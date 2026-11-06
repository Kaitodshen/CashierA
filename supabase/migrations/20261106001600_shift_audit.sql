-- =============================================================================
-- CashierA · 1600 · Phase 5 (shifts, approvals, audit): back-office reads.
-- The cashier actions (shift.close, cash_movement.create, order.void,
-- refund.create, audit.log) already exist since 1100.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- shift_summary: same report, plus who and where for printing and screens.
-- ---------------------------------------------------------------------------
create or replace function public.shift_summary(p_shift_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  s public.shifts%rowtype;
begin
  select * into s from public.shifts where id = p_shift_id;
  if not found then
    perform app.fail('shift_not_found');
  end if;
  if not (s.store_id = any (app.store_ids_with(array['shift.manage', 'reports.view']))) then
    perform app.fail('permission_denied', 'shift.manage or reports.view is required for this store');
  end if;

  return jsonb_build_object(
    'report', case when s.status = 'open' then 'X' else 'Z' end,
    'shift', jsonb_build_object(
      'id', s.id, 'store_id', s.store_id, 'device_id', s.device_id, 'status', s.status,
      'business_date', s.business_date, 'opened_by', s.opened_by, 'opened_at', s.opened_at,
      'closed_by', s.closed_by, 'closed_at', s.closed_at,
      'device_code', (select d.code from public.devices d where d.id = s.device_id),
      'store_name', (select st.name from public.stores st where st.id = s.store_id),
      'opened_by_name', (select e.full_name from public.employees e where e.id = s.opened_by),
      'closed_by_name', (select e.full_name from public.employees e where e.id = s.closed_by),
      'opening_cash', s.opening_cash, 'close_note', s.close_note),
    'sales', (
      select jsonb_build_object(
        'orders', count(*),
        'gross_total', coalesce(sum(o.gross_total), 0),
        'discount_total', coalesce(sum(o.item_discount_total + o.bill_discount_total + o.points_discount), 0),
        'net_total', coalesce(sum(o.net_total), 0),
        'service_charge_total', coalesce(sum(o.service_charge_total), 0),
        'tax_total', coalesce(sum(o.tax_total), 0),
        'rounding_total', coalesce(sum(o.rounding_amount), 0),
        'grand_total', coalesce(sum(o.grand_total), 0),
        'average_basket', coalesce(round(avg(o.grand_total)), 0))
      from public.orders o
      where o.shift_id = s.id and o.status = 'completed'),
    'voids', (
      select jsonb_build_object('orders', count(*), 'grand_total', coalesce(sum(o.grand_total), 0))
      from public.orders o
      where o.voided_shift_id = s.id and o.status = 'voided'),
    'cancelled_orders', (
      select count(*) from public.orders o where o.shift_id = s.id and o.status = 'cancelled'),
    'payments', (
      select coalesce(jsonb_agg(jsonb_build_object(
               'payment_method_id', x.payment_method_id, 'name', x.name, 'method_type', x.method_type,
               'count', x.n, 'amount', x.amount) order by x.sort_order), '[]'::jsonb)
      from (
        select p.payment_method_id, pm.name, p.method_type, pm.sort_order, count(*) as n, sum(p.amount) as amount
        from public.payments p
        join public.orders o on o.id = p.order_id
        join public.payment_methods pm on pm.id = p.payment_method_id
        where p.shift_id = s.id and p.status = 'paid' and o.status = 'completed'
        group by p.payment_method_id, pm.name, p.method_type, pm.sort_order
      ) x),
    'refunds', (
      select jsonb_build_object(
        'count', count(*),
        'amount', coalesce(sum(r.amount), 0),
        'cash_amount', coalesce(sum(r.amount) filter (where r.method_type = 'cash'), 0))
      from public.refunds r where r.shift_id = s.id),
    'kasbon', jsonb_build_object(
      'issued', (select coalesce(sum(p.amount), 0) from public.payments p
                 join public.orders o on o.id = p.order_id
                 where p.shift_id = s.id and p.method_type = 'kasbon' and o.status = 'completed'),
      'repaid', (select coalesce(sum(rp.amount), 0) from public.receivable_payments rp where rp.shift_id = s.id),
      'repaid_cash', (select coalesce(sum(rp.amount), 0) from public.receivable_payments rp
                      where rp.shift_id = s.id and rp.method_type = 'cash')),
    'cash', jsonb_build_object(
      'opening_cash', s.opening_cash,
      'cash_sales', (select coalesce(sum(p.amount), 0) from public.payments p
                     where p.shift_id = s.id and p.method_type = 'cash' and p.status = 'paid'),
      'voided_cash', (select coalesce(sum(p.amount), 0) from public.payments p
                      join public.orders o on o.id = p.order_id
                      where o.voided_shift_id = s.id and p.method_type = 'cash' and p.status = 'paid'),
      'cash_refunds', (select coalesce(sum(r.amount), 0) from public.refunds r
                       where r.shift_id = s.id and r.method_type = 'cash'),
      'kasbon_cash', (select coalesce(sum(rp.amount), 0) from public.receivable_payments rp
                      where rp.shift_id = s.id and rp.method_type = 'cash'),
      'cash_in', (select coalesce(sum(cm.amount), 0) from public.cash_movements cm
                  where cm.shift_id = s.id and cm.movement_type = 'in'),
      'cash_out', (select coalesce(sum(cm.amount), 0) from public.cash_movements cm
                   where cm.shift_id = s.id and cm.movement_type = 'out'),
      'expected_cash', app.shift_expected_cash(s.id),
      'counted_cash', s.counted_cash,
      'cash_difference', s.cash_difference),
    'top_items', (
      select coalesce(jsonb_agg(jsonb_build_object('variant_id', x.variant_id, 'name', x.name,
                                                   'quantity', x.qty, 'net_amount', x.net)
                                order by x.qty desc, x.name), '[]'::jsonb)
      from (
        select oi.variant_id,
               min(oi.product_name || coalesce(' ' || nullif(oi.variant_name, 'Default'), '')) as name,
               sum(oi.quantity - oi.refunded_quantity) as qty,
               sum(oi.net_amount) as net
        from public.order_items oi
        join public.orders o on o.id = oi.order_id
        where o.shift_id = s.id and o.status = 'completed'
        group by oi.variant_id
        order by sum(oi.quantity - oi.refunded_quantity) desc, min(oi.product_name)
        limit 10
      ) x)
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- shift_overview: the shifts of a period, newest first, at most 500.
-- p_store_id null = every store the caller may see.
-- ---------------------------------------------------------------------------
create or replace function public.shift_overview(
  p_store_id uuid default null,
  p_from date default null,
  p_to date default null
)
returns table (
  shift_id uuid,
  store_id uuid,
  store_name text,
  device_code text,
  status text,
  business_date date,
  opened_at timestamptz,
  closed_at timestamptz,
  opened_by_name text,
  closed_by_name text,
  opening_cash bigint,
  expected_cash bigint,
  counted_cash bigint,
  cash_difference bigint,
  order_count bigint,
  sales_total bigint
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_stores uuid[] := app.store_ids_with(array['shift.manage', 'reports.view'], false);
begin
  if p_store_id is not null and not (p_store_id = any (v_stores)) then
    perform app.fail('permission_denied', 'shift.manage or reports.view is required for this store');
  end if;
  if p_from is not null and p_to is not null and p_to < p_from then
    perform app.fail('invalid_input', 'the period ends before it starts');
  end if;

  return query
  select s.id, s.store_id, st.name, d.code, s.status, s.business_date, s.opened_at, s.closed_at,
         eo.full_name, ec.full_name, s.opening_cash,
         coalesce(s.expected_cash, app.shift_expected_cash(s.id)),
         s.counted_cash, s.cash_difference,
         (select count(*) from public.orders o where o.shift_id = s.id and o.status = 'completed'),
         (select coalesce(sum(o.grand_total), 0)::bigint from public.orders o
           where o.shift_id = s.id and o.status = 'completed')
  from public.shifts s
  join public.stores st on st.id = s.store_id
  join public.devices d on d.id = s.device_id
  join public.employees eo on eo.id = s.opened_by
  left join public.employees ec on ec.id = s.closed_by
  where s.store_id = any (v_stores)
    and (p_store_id is null or s.store_id = p_store_id)
    and (p_from is null or s.business_date >= p_from)
    and (p_to is null or s.business_date <= p_to)
  order by s.opened_at desc, s.id
  limit 500;
end;
$$;

-- ---------------------------------------------------------------------------
-- audit_entries: the audit log with names, newest first. Page backwards with
-- p_before and p_before_id (occurred_at and id of the last row shown). p_only_approvals keeps
-- entries a second employee approved. Company-wide entries (no store) are
-- for owners, as in the audit_log policy.
-- ---------------------------------------------------------------------------
create or replace function public.audit_entries(
  p_store_id uuid default null,
  p_from timestamptz default null,
  p_to timestamptz default null,
  p_only_approvals boolean default false,
  p_action_prefix text default null,
  p_limit integer default 100,
  p_before timestamptz default null,
  p_before_id uuid default null
)
returns table (
  id uuid,
  occurred_at timestamptz,
  store_id uuid,
  store_name text,
  device_code text,
  actor_name text,
  approver_name text,
  action text,
  entity_type text,
  entity_id uuid,
  details jsonb
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_stores uuid[] := app.store_ids_with(array['audit.view'], false);
  v_owner boolean := app.is_owner();
begin
  if cardinality(v_stores) = 0 then
    perform app.fail('permission_denied', 'audit.view is required');
  end if;
  if p_store_id is not null and not (p_store_id = any (v_stores)) then
    perform app.fail('permission_denied', 'audit.view is required for this store');
  end if;

  return query
  select a.id, a.occurred_at, a.store_id, st.name, d.code, ea.full_name, ep.full_name,
         a.action, a.entity_type, a.entity_id, a.details
  from public.audit_log a
  left join public.stores st on st.id = a.store_id
  left join public.devices d on d.id = a.device_id
  left join public.employees ea on ea.id = a.actor_employee_id
  left join public.employees ep on ep.id = a.approver_employee_id
  where (case
           when p_store_id is not null then a.store_id = p_store_id
           else a.store_id = any (v_stores) or (a.store_id is null and v_owner)
         end)
    and (p_from is null or a.occurred_at >= p_from)
    and (p_to is null or a.occurred_at < p_to)
    and (p_before is null or a.occurred_at < p_before
         or (a.occurred_at = p_before and p_before_id is not null and a.id > p_before_id))
    and (not coalesce(p_only_approvals, false) or a.approver_employee_id is not null)
    and (p_action_prefix is null or left(a.action, length(p_action_prefix)) = p_action_prefix)
  order by a.occurred_at desc, a.id
  limit least(greatest(coalesce(p_limit, 100), 1), 200);
end;
$$;

revoke execute on function public.shift_overview(uuid, date, date),
  public.audit_entries(uuid, timestamptz, timestamptz, boolean, text, integer, timestamptz, uuid)
  from public, anon;
grant execute on function public.shift_overview(uuid, date, date),
  public.audit_entries(uuid, timestamptz, timestamptz, boolean, text, integer, timestamptz, uuid)
  to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Discount approvals reach the audit log like every other approval: one
-- entry per approved manual discount when the order completes (held
-- snapshots do not count).
-- ---------------------------------------------------------------------------
create or replace function app.audit_discount_approvals()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.audit_log (occurred_at, store_id, device_id, actor_employee_id, approver_employee_id,
                                action, entity_type, entity_id, details)
  select coalesce(new.completed_at, now()), new.store_id, new.device_id, new.cashier_id, d.approved_by,
         'order.discount_approved', 'order', new.id,
         jsonb_build_object('order_number', new.order_number, 'description', d.description,
                            'amount', d.amount, 'discount_bps', d.discount_bps,
                            'order_item_id', d.order_item_id)
  from public.order_discounts d
  where d.order_id = new.id and d.source = 'manual' and d.approved_by is not null;
  return null;
end;
$$;

create trigger orders_audit_discount_approvals
after update of status on public.orders
for each row
when (new.status = 'completed' and old.status is distinct from 'completed')
execute function app.audit_discount_approvals();
