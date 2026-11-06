-- =============================================================================
-- CashierA · 1700 · Phase 6 (customers, loyalty, kasbon): points are checked
-- against the company settings, managers can adjust points, and the back
-- office gets a kasbon overview and a customer statement.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Adjusting points is worth money, so it gets its own permission (owner and
-- manager), separate from customer.manage which cashiers hold.
-- ---------------------------------------------------------------------------
insert into public.permissions (code, module, description_en, description_id) values
  ('loyalty.adjust', 'customer', 'Add or remove loyalty points by hand', 'Menambah atau mengurangi poin secara manual')
on conflict (code) do nothing;

insert into public.role_permissions (role_id, permission_code)
select r.id, 'loyalty.adjust' from public.roles r where r.code in ('owner', 'manager')
on conflict do nothing;

-- ---------------------------------------------------------------------------
-- Order totals: same checks as 1500, plus the loyalty rules.
-- ---------------------------------------------------------------------------
create or replace function app.validate_order_totals(p_order_id uuid)
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  o public.orders%rowtype;
  v_items record;
  v_disc record;
  v_pay record;
  v_base bigint;
  v_service bigint;
  v_tax bigint;
  v_bp public.business_profile%rowtype;
begin
  select * into o from public.orders where id = p_order_id;

  select count(*) as n,
         coalesce(sum(gross_amount), 0) as gross,
         coalesce(sum(item_discount_amount), 0) as item_disc,
         coalesce(sum(bill_discount_amount), 0) as bill_disc,
         coalesce(sum(net_amount), 0) as net,
         coalesce(sum(tax_amount), 0) as tax,
         coalesce(sum(net_amount) filter (where is_taxable), 0) as taxable_net
    into v_items
    from public.order_items
   where order_id = p_order_id;

  if v_items.n = 0 then
    perform app.fail('order_empty', o.order_number);
  end if;
  if v_items.gross <> o.gross_total then
    perform app.fail('order_totals_mismatch', format('lines gross %s <> gross_total %s', v_items.gross, o.gross_total));
  end if;
  if v_items.item_disc <> o.item_discount_total then
    perform app.fail('order_totals_mismatch', format('lines item discounts %s <> item_discount_total %s', v_items.item_disc, o.item_discount_total));
  end if;
  if v_items.bill_disc <> o.bill_discount_total + o.points_discount then
    perform app.fail('order_totals_mismatch', format('lines bill discounts %s <> bill_discount_total + points_discount %s',
      v_items.bill_disc, o.bill_discount_total + o.points_discount));
  end if;
  if v_items.net <> o.net_total then
    perform app.fail('order_totals_mismatch', format('lines net %s <> net_total %s', v_items.net, o.net_total));
  end if;
  -- The line tax shares add up to the bill's tax. When no taxable line has
  -- anything left (an exempt basket with a taxable service charge, or taxable
  -- lines discounted to zero), there is nothing to carry it: the header keeps
  -- the tax and the lines carry none.
  if v_items.taxable_net > 0 and v_items.tax <> o.tax_total then
    perform app.fail('order_totals_mismatch', format('lines tax %s <> tax_total %s', v_items.tax, o.tax_total));
  end if;
  if v_items.taxable_net = 0 and v_items.tax <> 0 then
    perform app.fail('order_totals_mismatch', format('lines tax %s with no taxable net', v_items.tax));
  end if;

  select coalesce(sum(amount) filter (where order_item_id is not null), 0) as item_disc,
         coalesce(sum(amount) filter (where order_item_id is null and source <> 'points'), 0) as bill_disc,
         coalesce(sum(amount) filter (where source = 'points'), 0) as points
    into v_disc
    from public.order_discounts
   where order_id = p_order_id;

  if (v_disc.item_disc, v_disc.bill_disc, v_disc.points)
     is distinct from (o.item_discount_total, o.bill_discount_total, o.points_discount) then
    perform app.fail('order_discounts_mismatch', format(
      'discount rows item/bill/points %s/%s/%s <> header %s/%s/%s',
      v_disc.item_disc, v_disc.bill_disc, v_disc.points,
      o.item_discount_total, o.bill_discount_total, o.points_discount));
  end if;

  -- Service charge and tax are computed once per bill (see docs §4.5).
  v_service := round(o.net_total::numeric * o.service_charge_bps / 10000);
  if o.service_charge_total <> v_service then
    perform app.fail('service_charge_mismatch', format('service %s <> expected %s', o.service_charge_total, v_service));
  end if;

  v_base := v_items.taxable_net + case when o.service_charge_taxable then o.service_charge_total else 0 end;
  v_tax := case
    when o.tax_rate_bps = 0 then 0
    when o.tax_inclusive then round(v_base::numeric * o.tax_rate_bps / (10000 + o.tax_rate_bps))
    else round(v_base::numeric * o.tax_rate_bps / 10000)
  end;
  if o.tax_total <> v_tax then
    perform app.fail('tax_mismatch', format('tax %s <> expected %s on base %s', o.tax_total, v_tax, v_base));
  end if;

  select count(*) filter (where status <> 'paid') as unpaid,
         coalesce(sum(amount) filter (where status = 'paid'), 0) as applied,
         coalesce(sum(amount) filter (where status = 'paid' and method_type <> 'kasbon'), 0) as paid,
         coalesce(sum(change_amount) filter (where status = 'paid'), 0) as change,
         count(*) filter (where method_type = 'kasbon') as kasbon_rows
    into v_pay
    from public.payments
   where order_id = p_order_id;

  if v_pay.unpaid > 0 then
    perform app.fail('payment_pending', 'every payment must be paid before the order completes');
  end if;
  if v_pay.applied <> o.grand_total then
    perform app.fail('payment_mismatch', format('payments %s <> grand_total %s', v_pay.applied, o.grand_total));
  end if;
  if v_pay.paid <> o.paid_total then
    perform app.fail('payment_mismatch', format('non-kasbon payments %s <> paid_total %s', v_pay.paid, o.paid_total));
  end if;
  if v_pay.change <> o.change_total then
    perform app.fail('payment_mismatch', format('change %s <> change_total %s', v_pay.change, o.change_total));
  end if;
  if v_pay.kasbon_rows > 0 and o.customer_id is null then
    perform app.fail('kasbon_requires_customer', 'kasbon needs a customer');
  end if;
  if (o.points_redeemed > 0 or o.points_earned > 0) and o.customer_id is null then
    perform app.fail('loyalty_requires_customer', 'points need a customer');
  end if;

  -- Points follow the company's loyalty settings (A6).
  if o.customer_id is not null then
    select * into v_bp from public.business_profile where id = 1;
    if not v_bp.loyalty_enabled then
      if o.points_redeemed > 0 or o.points_earned > 0 then
        perform app.fail('loyalty_disabled', 'loyalty is switched off');
      end if;
    else
      if o.points_earned <> floor(o.net_total::numeric / v_bp.loyalty_earn_amount)::integer then
        perform app.fail('points_earned_mismatch',
          format('points_earned %s <> floor(net %s / %s)', o.points_earned, o.net_total, v_bp.loyalty_earn_amount));
      end if;
      if o.points_discount <> o.points_redeemed::bigint * v_bp.loyalty_point_value then
        perform app.fail('points_value_mismatch',
          format('points_discount %s <> %s points x Rp %s', o.points_discount, o.points_redeemed, v_bp.loyalty_point_value));
      end if;
      if o.points_redeemed > 0 and o.points_redeemed < v_bp.loyalty_min_redeem_points then
        perform app.fail('points_below_minimum',
          format('at least %s points must be redeemed', v_bp.loyalty_min_redeem_points));
      end if;
    end if;
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- adjust_points(customer_id, points, note): a manual correction (+ or -) in
-- the ledger by someone with loyalty.adjust. The balance may not go below 0.
-- Audited.
-- ---------------------------------------------------------------------------
create or replace function public.adjust_points(p_customer_id uuid, p_points integer, p_note text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  c public.customers%rowtype;
  v_employee uuid := app.current_employee_id();
  v_balance integer;
begin
  if v_employee is null or not app.has_permission('loyalty.adjust') then
    perform app.fail('permission_denied', 'loyalty.adjust is required');
  end if;
  if p_points is null or p_points = 0 then
    perform app.fail('invalid_input', 'points must not be 0');
  end if;
  if coalesce(length(trim(p_note)), 0) < 3 then
    perform app.fail('invalid_input', 'a note of at least 3 characters is required');
  end if;
  select * into c from public.customers where id = p_customer_id for update;
  if not found then
    perform app.fail('customer_not_found');
  end if;
  if c.points_balance + p_points < 0 then
    perform app.fail('points_insufficient', format('the balance is %s points', c.points_balance));
  end if;

  insert into public.loyalty_ledger (customer_id, entry_type, points, note, employee_id)
  values (c.id, 'adjust', p_points, trim(p_note), v_employee);
  select points_balance into v_balance from public.customers where id = c.id;

  insert into public.audit_log (actor_employee_id, action, entity_type, entity_id, details)
  values (v_employee, 'loyalty.adjusted', 'customer', c.id,
          jsonb_build_object('points', p_points, 'note', trim(p_note), 'balance', v_balance));
  return jsonb_build_object('customer_id', c.id, 'points_balance', v_balance);
end;
$$;

-- ---------------------------------------------------------------------------
-- kasbon_overview(store_id, as_of): outstanding kasbon per customer and
-- store, most overdue first. p_store_id null = every store the caller may see.
-- ---------------------------------------------------------------------------
create or replace function public.kasbon_overview(p_store_id uuid default null, p_as_of date default null)
returns table (
  store_id uuid,
  store_name text,
  customer_id uuid,
  customer_name text,
  customer_phone text,
  kasbon_limit bigint,
  open_count bigint,
  outstanding bigint,
  overdue bigint,
  oldest_due date
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_stores uuid[] := app.store_ids_with(array['kasbon.manage', 'reports.view'], false);
  v_today date := coalesce(p_as_of, (now() at time zone 'Asia/Jakarta')::date);
begin
  if p_store_id is not null and not (p_store_id = any (v_stores)) then
    perform app.fail('permission_denied', 'kasbon.manage or reports.view is required for this store');
  end if;
  return query
  select r.store_id, s.name, c.id, c.name, c.phone, c.kasbon_limit,
         count(*), sum(r.amount - r.paid_amount)::bigint,
         coalesce(sum(r.amount - r.paid_amount) filter (where r.due_date < v_today), 0)::bigint,
         min(r.due_date)
  from public.receivables r
  join public.customers c on c.id = r.customer_id
  join public.stores s on s.id = r.store_id
  where r.status in ('open', 'partial')
    and r.store_id = any (v_stores)
    and (p_store_id is null or r.store_id = p_store_id)
  group by r.store_id, s.name, c.id, c.name, c.phone, c.kasbon_limit
  order by 9 desc, 10, 4;
end;
$$;

-- ---------------------------------------------------------------------------
-- customer_statement(customer_id): the customer, their kasbon (with
-- payments) in the stores the caller may see, and the last 100 ledger
-- entries.
-- ---------------------------------------------------------------------------
create or replace function public.customer_statement(p_customer_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  c public.customers%rowtype;
  v_stores uuid[] := app.store_ids_with(array['kasbon.manage', 'reports.view'], false);
begin
  if not app.is_member() or app.current_employee_id() is null then
    perform app.fail('permission_denied', 'staff only');
  end if;
  select * into c from public.customers where id = p_customer_id;
  if not found then
    perform app.fail('customer_not_found');
  end if;
  return jsonb_build_object(
    'customer', jsonb_build_object('id', c.id, 'code', c.code, 'name', c.name, 'phone', c.phone,
                                   'points_balance', c.points_balance, 'kasbon_limit', c.kasbon_limit,
                                   'is_active', c.is_active),
    'kasbon', coalesce((
      select jsonb_agg(jsonb_build_object(
               'receivable_id', r.id, 'store_id', r.store_id, 'store_name', s.name, 'order_id', r.order_id,
               'order_number', o.order_number, 'amount', r.amount, 'paid_amount', r.paid_amount,
               'due_date', r.due_date, 'status', r.status, 'created_at', r.created_at,
               'payments', coalesce((
                 select jsonb_agg(jsonb_build_object('id', rp.id, 'amount', rp.amount, 'method_type', rp.method_type,
                                                     'paid_at', rp.paid_at, 'employee_name', e.full_name)
                                  order by rp.paid_at)
                 from public.receivable_payments rp
                 left join public.employees e on e.id = rp.employee_id
                 where rp.receivable_id = r.id), '[]'::jsonb))
             order by r.due_date, r.created_at)
      from public.receivables r
      join public.stores s on s.id = r.store_id
      join public.orders o on o.id = r.order_id
      where r.customer_id = c.id and r.store_id = any (v_stores)), '[]'::jsonb),
    'ledger', coalesce((
      select jsonb_agg(x.e order by x.created_at desc)
      from (
        select l.created_at,
               jsonb_build_object('id', l.id, 'entry_type', l.entry_type, 'points', l.points, 'note', l.note,
                                  'created_at', l.created_at, 'order_number', o.order_number,
                                  'store_name', s.name, 'employee_name', e.full_name) as e
        from public.loyalty_ledger l
        left join public.orders o on o.id = l.order_id
        left join public.stores s on s.id = l.store_id
        left join public.employees e on e.id = l.employee_id
        where l.customer_id = c.id
        order by l.created_at desc
        limit 100
      ) x), '[]'::jsonb)
  );
end;
$$;

revoke execute on function public.adjust_points(uuid, integer, text),
  public.kasbon_overview(uuid, date), public.customer_statement(uuid) from public, anon;
grant execute on function public.adjust_points(uuid, integer, text),
  public.kasbon_overview(uuid, date), public.customer_statement(uuid) to authenticated, service_role;
