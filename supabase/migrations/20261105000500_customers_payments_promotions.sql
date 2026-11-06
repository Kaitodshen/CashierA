-- =============================================================================
-- CashierA · 0500 · Customers, payment methods, promotions, vouchers
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Customers (company-wide; loyalty points are shared across stores)
-- ---------------------------------------------------------------------------
create sequence public.customer_code_seq;

create table public.customers (
  id uuid primary key default gen_random_uuid(),
  code text not null unique default ('C' || lpad(nextval('public.customer_code_seq')::text, 6, '0')),
  name text not null check (length(trim(name)) > 0),
  phone text check (phone ~ '^\+?[0-9]{8,15}$'),
  email text check (email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
  birth_date date,
  address text,
  notes text,
  points_balance integer not null default 0,
  kasbon_limit bigint check (kasbon_limit >= 0),
  created_store_id uuid references public.stores (id),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
-- Phone is searchable but not unique: two stores may create the same customer
-- while offline. Duplicates raise a CUSTOMER_DUPLICATE alert for merging.
create index customers_phone_idx on public.customers (phone) where phone is not null;
create index customers_name_idx on public.customers (lower(name));
comment on column public.customers.points_balance is 'Maintained by loyalty_ledger triggers. Not writable by clients.';
comment on column public.customers.kasbon_limit is 'Maximum outstanding kasbon in rupiah; null = no limit.';

-- ---------------------------------------------------------------------------
-- Payment methods (company list) and which ones each store accepts
-- ---------------------------------------------------------------------------
create table public.payment_methods (
  id uuid primary key default gen_random_uuid(),
  code text not null unique check (code ~ '^[a-z][a-z0-9_]*$'),
  name text not null check (length(trim(name)) > 0),
  method_type text not null check (method_type in ('cash', 'qris', 'card', 'transfer', 'ewallet', 'kasbon')),
  requires_reference boolean not null default false,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
comment on column public.payment_methods.requires_reference is 'Cashier must type an approval code or transfer reference.';

insert into public.payment_methods (code, name, method_type, requires_reference, sort_order) values
  ('cash',        'Tunai',        'cash',     false, 10),
  ('qris',        'QRIS',         'qris',     false, 20),
  ('debit_card',  'Kartu Debit',  'card',     true,  30),
  ('credit_card', 'Kartu Kredit', 'card',     true,  40),
  ('transfer',    'Transfer Bank','transfer', true,  50),
  ('ewallet',     'E-Wallet',     'ewallet',  true,  60),
  ('kasbon',      'Kasbon',       'kasbon',   false, 70);

create table public.store_payment_methods (
  store_id uuid not null references public.stores (id) on delete cascade,
  payment_method_id uuid not null references public.payment_methods (id) on delete cascade,
  is_enabled boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (store_id, payment_method_id)
);

-- New stores get default settings and every active payment method.
create or replace function app.on_store_created()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.store_settings (store_id, receipt_header)
  values (new.id, new.name)
  on conflict (store_id) do nothing;

  insert into public.store_payment_methods (store_id, payment_method_id, sort_order)
  select new.id, pm.id, pm.sort_order from public.payment_methods pm where pm.is_active
  on conflict do nothing;
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- Promotions. Rules are JSON, validated here and evaluated by the pure-Dart
-- promo engine (cashiera_core). Shapes (amounts in rupiah, bps = 1/100 %):
--   scope    : {"all": true} | {"category_ids":[..], "product_ids":[..], "variant_ids":[..]}
--   discount : {"type":"percent","bps":1000} | {"type":"fixed","amount":5000}
--   happy_hour  : {"scope", "discount"}                  + start_time/end_time required
--   buy_x_get_y : {"buy":{"scope","quantity"}, "get":{"scope","quantity","discount"}, "max_applications"?}
--   bundle      : {"components":[{"scope","quantity"}, ...>=2], "bundle_price", "max_applications"?}
--   tiered_qty  : {"scope", "tiers":[{"min_quantity","discount"}, ... ascending]}
--   min_purchase: {"min_subtotal", "discount", "max_discount"?}
-- ---------------------------------------------------------------------------
create or replace function app.promo_scope_valid(p jsonb)
returns boolean
language plpgsql
immutable
set search_path = ''
as $$
declare
  v_key text;
  v_total integer := 0;
begin
  if p is null or jsonb_typeof(p) <> 'object' then
    return false;
  end if;
  if p ? 'all' then
    return jsonb_typeof(p -> 'all') = 'boolean' and (p ->> 'all')::boolean;
  end if;
  foreach v_key in array array['category_ids', 'product_ids', 'variant_ids'] loop
    if p ? v_key then
      if jsonb_typeof(p -> v_key) <> 'array' then
        return false;
      end if;
      if exists (
        select 1 from jsonb_array_elements_text(p -> v_key) as e(v)
        where e.v !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
      ) then
        return false;
      end if;
      v_total := v_total + jsonb_array_length(p -> v_key);
    end if;
  end loop;
  return v_total > 0;
end;
$$;

create or replace function app.promo_discount_valid(p jsonb)
returns boolean
language plpgsql
immutable
set search_path = ''
as $$
begin
  if p is null or jsonb_typeof(p) <> 'object' then
    return false;
  end if;
  if p ->> 'type' = 'percent' then
    return app.is_positive_int(p -> 'bps') and (p ->> 'bps')::numeric <= 10000;
  elsif p ->> 'type' = 'fixed' then
    return app.is_positive_int(p -> 'amount');
  end if;
  return false;
end;
$$;

create or replace function app.promotion_rules_valid(p_type text, p_rules jsonb)
returns boolean
language plpgsql
immutable
set search_path = ''
as $$
declare
  v_item jsonb;
  v_prev numeric := 0;
  v_optional_max boolean;
begin
  if p_rules is null or jsonb_typeof(p_rules) <> 'object' then
    return false;
  end if;
  v_optional_max := (p_rules -> 'max_applications') is null
    or jsonb_typeof(p_rules -> 'max_applications') = 'null'
    or app.is_positive_int(p_rules -> 'max_applications');

  if p_type = 'happy_hour' then
    return app.promo_scope_valid(p_rules -> 'scope')
       and app.promo_discount_valid(p_rules -> 'discount');

  elsif p_type = 'buy_x_get_y' then
    return app.promo_scope_valid(p_rules #> '{buy,scope}')
       and app.is_positive_int(p_rules #> '{buy,quantity}')
       and app.promo_scope_valid(p_rules #> '{get,scope}')
       and app.is_positive_int(p_rules #> '{get,quantity}')
       and app.promo_discount_valid(p_rules #> '{get,discount}')
       and v_optional_max;

  elsif p_type = 'bundle' then
    if jsonb_typeof(p_rules -> 'components') is distinct from 'array'
       or jsonb_array_length(p_rules -> 'components') < 2 then
      return false;
    end if;
    for v_item in select value from jsonb_array_elements(p_rules -> 'components') loop
      if not (app.promo_scope_valid(v_item -> 'scope') and app.is_positive_int(v_item -> 'quantity')) then
        return false;
      end if;
    end loop;
    return app.is_positive_int(p_rules -> 'bundle_price') and v_optional_max;

  elsif p_type = 'tiered_qty' then
    if not app.promo_scope_valid(p_rules -> 'scope')
       or jsonb_typeof(p_rules -> 'tiers') is distinct from 'array'
       or jsonb_array_length(p_rules -> 'tiers') < 1 then
      return false;
    end if;
    for v_item in select value from jsonb_array_elements(p_rules -> 'tiers') loop
      if not (app.is_positive_int(v_item -> 'min_quantity') and app.promo_discount_valid(v_item -> 'discount')) then
        return false;
      end if;
      if (v_item ->> 'min_quantity')::numeric <= v_prev then
        return false;
      end if;
      v_prev := (v_item ->> 'min_quantity')::numeric;
    end loop;
    return true;

  elsif p_type = 'min_purchase' then
    return app.is_positive_int(p_rules -> 'min_subtotal')
       and app.promo_discount_valid(p_rules -> 'discount')
       and ((p_rules -> 'max_discount') is null
            or jsonb_typeof(p_rules -> 'max_discount') = 'null'
            or app.is_positive_int(p_rules -> 'max_discount'));
  end if;

  return false;
end;
$$;

create table public.promotions (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(trim(name)) > 0),
  description text,
  promo_type text not null check (promo_type in ('happy_hour', 'buy_x_get_y', 'bundle', 'tiered_qty', 'min_purchase')),
  rules jsonb not null,
  priority integer not null default 100,
  is_stackable boolean not null default false,
  starts_at timestamptz,
  ends_at timestamptz,
  days_of_week smallint[] check (days_of_week <@ array[1, 2, 3, 4, 5, 6, 7]::smallint[]),
  start_time time,
  end_time time,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint promotions_rules_valid check (app.promotion_rules_valid(promo_type, rules)),
  constraint promotions_period_valid check (ends_at is null or starts_at is null or ends_at > starts_at),
  constraint promotions_window_valid check ((start_time is null) = (end_time is null)),
  constraint promotions_happy_hour_window check (promo_type <> 'happy_hour' or start_time is not null)
);
comment on column public.promotions.priority is 'Lower runs first. Non-stackable promos stop lower-priority ones on the same items.';
comment on column public.promotions.days_of_week is 'ISO weekdays 1=Mon..7=Sun in the store timezone; null = every day.';
comment on column public.promotions.start_time is 'Daily window in store local time; end before start wraps past midnight.';

-- Empty = valid in every store.
create table public.promotion_stores (
  promotion_id uuid not null references public.promotions (id) on delete cascade,
  store_id uuid not null references public.stores (id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (promotion_id, store_id)
);

create table public.vouchers (
  id uuid primary key default gen_random_uuid(),
  code text not null check (code ~ '^[A-Z0-9_-]{3,32}$'),
  description text,
  discount_type text not null check (discount_type in ('percent', 'fixed')),
  discount_value bigint not null check (discount_value > 0),
  max_discount bigint check (max_discount > 0),
  min_subtotal bigint not null default 0 check (min_subtotal >= 0),
  max_uses integer check (max_uses > 0),
  used_count integer not null default 0 check (used_count >= 0),
  per_customer_limit integer check (per_customer_limit > 0),
  starts_at timestamptz,
  ends_at timestamptz,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (discount_type <> 'percent' or discount_value <= 10000),
  check (ends_at is null or starts_at is null or ends_at > starts_at)
);
create unique index vouchers_code_key on public.vouchers (upper(code));
comment on column public.vouchers.discount_value is 'bps when percent (1000 = 10%), rupiah when fixed.';
comment on column public.vouchers.used_count is 'Maintained by voucher_redemptions triggers. Not writable by clients.';
