-- =============================================================================
-- CashierA · 2100 · Phase 9 (payment gateway). Dynamic QRIS through Midtrans.
--
-- A charge is opened by a terminal (gateway_charge_open), filled in and settled
-- by the Edge Functions with the service role (gateway_charge_attach / _settle),
-- and watched by the terminal (gateway_charge_status, Realtime). A payment that
-- goes through a gateway method, or names a provider, is accepted only when its
-- charge (same id) is paid for the same amount in the same store.
-- =============================================================================

alter table public.payment_methods
  add column if not exists gateway text check (gateway in ('midtrans'));
comment on column public.payment_methods.gateway is
  'Set for dynamic methods paid through a gateway (Edge Functions). Null = recorded by the cashier.';

insert into public.payment_methods (code, name, method_type, requires_reference, sort_order, gateway)
values ('qris_dynamic', 'QRIS Dinamis', 'qris', false, 21, 'midtrans')
on conflict (code) do nothing;

create table public.gateway_charges (
  id uuid primary key,
  store_id uuid not null references public.stores (id),
  device_id uuid references public.devices (id),
  payment_method_id uuid not null references public.payment_methods (id),
  order_id uuid not null,
  order_number text,
  amount bigint not null check (amount > 0),
  provider text not null check (provider in ('midtrans')),
  provider_ref text,
  qr_string text,
  expires_at timestamptz,
  status text not null default 'pending'
    check (status in ('pending', 'paid', 'failed', 'expired', 'cancelled')),
  paid_at timestamptz,
  raw jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint gateway_charges_paid_chk check (status <> 'paid' or paid_at is not null)
);
create index gateway_charges_store_created_idx on public.gateway_charges (store_id, created_at desc);
create unique index gateway_charges_provider_ref_key on public.gateway_charges (provider, provider_ref)
  where provider_ref is not null;
comment on table public.gateway_charges is
  'One dynamic QRIS charge per payment id. Written only by RPCs; paid is final.';

alter table public.gateway_charges enable row level security;
create policy gateway_charges_select on public.gateway_charges
  for select to authenticated
  using (store_id in (select unnest(app.store_ids_with(array['pos.sell', 'reports.view']))));
grant select on public.gateway_charges to authenticated;
grant all on public.gateway_charges to service_role;
alter publication supabase_realtime add table public.gateway_charges;

-- ---------------------------------------------------------------------------
-- gateway_charge_open(p): the terminal starts a charge before showing the QR.
--   p = {id, store_id, payment_method_id, order_id, order_number, amount}
-- Idempotent on id (a retry returns the same charge).
-- ---------------------------------------------------------------------------
create or replace function public.gateway_charge_open(p jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid := (p ->> 'id')::uuid;
  v_store uuid := (p ->> 'store_id')::uuid;
  v_amount bigint := (p ->> 'amount')::bigint;
  v_method public.payment_methods%rowtype;
  c public.gateway_charges%rowtype;
begin
  if not app.is_device() then
    perform app.fail('permission_denied', 'only a paired terminal can take gateway payments');
  end if;
  perform app.assert_write_scope(v_store);
  if v_id is null or (p ->> 'order_id') is null then
    perform app.fail('invalid_input', 'id and order_id are required');
  end if;
  if v_amount is null or v_amount <= 0 then
    perform app.fail('invalid_input', 'amount must be positive');
  end if;
  select * into v_method from public.payment_methods
  where id = (p ->> 'payment_method_id')::uuid and is_active and gateway is not null;
  if not found then
    perform app.fail('payment_method_invalid', 'not an active gateway method');
  end if;

  select * into c from public.gateway_charges where id = v_id;
  if found then
    if c.store_id <> v_store or c.amount <> v_amount or c.order_id <> (p ->> 'order_id')::uuid then
      perform app.fail('invalid_input', 'this charge id is already used for another payment');
    end if;
  else
    insert into public.gateway_charges (id, store_id, device_id, payment_method_id, order_id, order_number,
                                        amount, provider)
    values (v_id, v_store, app.current_device_id(), v_method.id, (p ->> 'order_id')::uuid,
            p ->> 'order_number', v_amount, v_method.gateway)
    returning * into c;
  end if;
  return jsonb_build_object('id', c.id, 'status', c.status, 'amount', c.amount, 'provider', c.provider,
                            'provider_ref', c.provider_ref, 'qr_string', c.qr_string, 'expires_at', c.expires_at);
end;
$$;

-- ---------------------------------------------------------------------------
-- gateway_charge_attach: the Edge Function stores the gateway's answer.
-- ---------------------------------------------------------------------------
create or replace function public.gateway_charge_attach(
  p_id uuid,
  p_provider_ref text,
  p_qr_string text,
  p_expires_at timestamptz,
  p_raw jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  c public.gateway_charges%rowtype;
begin
  update public.gateway_charges
     set provider_ref = coalesce(p_provider_ref, provider_ref),
         qr_string = coalesce(p_qr_string, qr_string),
         expires_at = coalesce(p_expires_at, expires_at),
         raw = raw || jsonb_build_object('charge', coalesce(p_raw, '{}'::jsonb)),
         updated_at = now()
   where id = p_id
  returning * into c;
  if not found then
    perform app.fail('charge_not_found');
  end if;
  return jsonb_build_object('id', c.id, 'status', c.status, 'provider_ref', c.provider_ref,
                            'qr_string', c.qr_string, 'expires_at', c.expires_at);
end;
$$;

-- ---------------------------------------------------------------------------
-- gateway_charge_settle: the gateway's verdict (webhook, cancel, status check).
-- paid is final; a late paid after expiry or cancel still counts (the money
-- arrived). A different amount is refused and logged.
-- ---------------------------------------------------------------------------
create or replace function public.gateway_charge_settle(
  p_id uuid,
  p_status text,
  p_gross_amount bigint default null,
  p_transaction_id text default null,
  p_raw jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  c public.gateway_charges%rowtype;
  v_changed boolean := false;
begin
  if p_status not in ('pending', 'paid', 'failed', 'expired', 'cancelled') then
    perform app.fail('invalid_input', 'unknown status ' || coalesce(p_status, 'null'));
  end if;
  select * into c from public.gateway_charges where id = p_id for update;
  if not found then
    perform app.fail('charge_not_found');
  end if;
  if p_gross_amount is not null and p_gross_amount <> c.amount then
    insert into public.audit_log (store_id, device_id, action, entity_type, entity_id, details)
    values (c.store_id, c.device_id, 'payment.gateway_mismatch', 'gateway_charge', c.id,
            jsonb_build_object('expected', c.amount, 'reported', p_gross_amount, 'status', p_status));
    perform app.fail('amount_mismatch', format('charge is %s, gateway reported %s', c.amount, p_gross_amount));
  end if;

  if c.status <> 'paid' and p_status <> 'pending' and p_status <> c.status then
    v_changed := true;
    update public.gateway_charges
       set status = p_status,
           paid_at = case when p_status = 'paid' then now() end,
           provider_ref = coalesce(p_transaction_id, provider_ref),
           raw = raw || jsonb_build_object(p_status, coalesce(p_raw, '{}'::jsonb)),
           updated_at = now()
     where id = c.id
    returning * into c;
    insert into public.audit_log (store_id, device_id, action, entity_type, entity_id, details)
    values (c.store_id, c.device_id, 'payment.gateway_' || p_status, 'gateway_charge', c.id,
            jsonb_build_object('amount', c.amount, 'order_number', c.order_number,
                               'provider_ref', c.provider_ref));
  end if;
  return jsonb_build_object('id', c.id, 'status', c.status, 'changed', v_changed, 'amount', c.amount,
                            'provider_ref', c.provider_ref, 'paid_at', c.paid_at);
end;
$$;

-- ---------------------------------------------------------------------------
-- gateway_charge_status: what the terminal (or back office) sees.
-- ---------------------------------------------------------------------------
create or replace function public.gateway_charge_status(p_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  c public.gateway_charges%rowtype;
begin
  select * into c from public.gateway_charges where id = p_id;
  if not found or not (auth.role() = 'service_role'
                       or c.store_id = any (app.store_ids_with(array['pos.sell', 'reports.view']))) then
    perform app.fail('charge_not_found');
  end if;
  return jsonb_build_object('id', c.id, 'status', c.status, 'amount', c.amount, 'provider', c.provider,
                            'provider_ref', c.provider_ref, 'qr_string', c.qr_string,
                            'expires_at', c.expires_at, 'paid_at', c.paid_at);
end;
$$;

-- ---------------------------------------------------------------------------
-- gateway_charge_list(store, from, to): charges by store-local date, newest
-- first. matched = a sale booked the payment; a paid charge without one is
-- money received with no sale (reconcile or refund it at the gateway).
-- ---------------------------------------------------------------------------
create or replace function public.gateway_charge_list(p_store_id uuid, p_from date, p_to date)
returns table (
  charge_id uuid,
  store_id uuid,
  store_code text,
  order_number text,
  amount bigint,
  status text,
  provider_ref text,
  created_at timestamptz,
  paid_at timestamptz,
  matched boolean
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_allowed uuid[] := app.store_ids_with(array['reports.view'], false);
begin
  if p_store_id is not null and not (p_store_id = any (v_allowed)) then
    perform app.fail('permission_denied', 'reports.view is required for this store');
  end if;
  return query
  select c.id, c.store_id, s.code, c.order_number, c.amount, c.status, c.provider_ref, c.created_at, c.paid_at,
         exists (select 1 from public.payments pay where pay.id = c.id)
  from public.gateway_charges c
  join public.stores s on s.id = c.store_id
  where c.store_id = any (v_allowed)
    and (p_store_id is null or c.store_id = p_store_id)
    and (c.created_at at time zone s.timezone)::date between p_from and p_to
  order by c.created_at desc
  limit 500;
end;
$$;

-- ---------------------------------------------------------------------------
-- Payments through a gateway need a paid charge with the same id, amount and
-- store. The charge's provider fields are copied onto the payment.
-- ---------------------------------------------------------------------------
create or replace function app.check_gateway_payment()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_gateway text;
  c public.gateway_charges%rowtype;
begin
  select pm.gateway into v_gateway from public.payment_methods pm where pm.id = new.payment_method_id;
  if v_gateway is null and new.provider is null then
    return new;
  end if;
  select * into c from public.gateway_charges g where g.id = new.id;
  if not found or c.status <> 'paid' or c.amount <> new.amount or c.store_id <> new.store_id then
    perform app.fail('gateway_unconfirmed',
                     format('payment %s has no paid gateway charge for %s', new.id, new.amount));
  end if;
  new.provider := c.provider;
  new.provider_ref := c.provider_ref;
  new.status := 'paid';
  new.paid_at := coalesce(c.paid_at, new.paid_at);
  return new;
end;
$$;

create trigger payments_gateway_check
before insert or update of amount, status, provider, provider_ref, payment_method_id on public.payments
for each row execute function app.check_gateway_payment();

revoke execute on function public.gateway_charge_open(jsonb), public.gateway_charge_status(uuid),
  public.gateway_charge_list(uuid, date, date),
  public.gateway_charge_attach(uuid, text, text, timestamptz, jsonb),
  public.gateway_charge_settle(uuid, text, bigint, text, jsonb)
  from public, anon, authenticated;
grant execute on function public.gateway_charge_open(jsonb), public.gateway_charge_status(uuid),
  public.gateway_charge_list(uuid, date, date)
  to authenticated, service_role;
grant execute on function public.gateway_charge_attach(uuid, text, text, timestamptz, jsonb),
  public.gateway_charge_settle(uuid, text, bigint, text, jsonb)
  to service_role;
