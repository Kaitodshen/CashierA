-- =============================================================================
-- CashierA · 1800 · Fixes from the Phase 5 review.
--   * An approval naming another employee is accepted only from a paired
--     terminal (which checked their PIN); everyone else approves as
--     themselves.
--   * Only completed orders carry payments, and expected cash counts the
--     cash of completed and voided sales only.
-- =============================================================================

create or replace function app.assert_approver(p_employee_id uuid, p_store_id uuid, p_permission text)
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if p_employee_id is null then
    perform app.fail('approval_required', 'needs approval: ' || p_permission);
  end if;
  -- Only a paired terminal checks another employee's PIN before naming
  -- them. Staff signed in elsewhere (back office, API) approve as
  -- themselves only.
  if not app.is_device() and p_employee_id is distinct from app.current_employee_id() then
    perform app.fail('approval_requires_terminal',
      'another employee''s approval needs their PIN on a paired terminal');
  end if;
  if not app.employee_can(p_employee_id, p_store_id, p_permission) then
    perform app.fail('approval_denied', format('approver lacks %s at this store', p_permission));
  end if;
end;
$$;

create or replace function app.sync_dispatch(p_entity text, p_action text, p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_key text := p_entity || '.' || p_action;
begin
  -- Money is taken only when a sale is finished; held, open and cancelled
  -- snapshots carry no payments (they would count as drawer cash).
  if v_key = 'order.upsert'
     and coalesce(p_payload ->> 'status', 'open') <> 'completed'
     and jsonb_typeof(p_payload -> 'payments') = 'array'
     and jsonb_array_length(p_payload -> 'payments') > 0 then
    perform app.fail('payments_require_completion', 'only a completed order carries payments');
  end if;
  if v_key = 'shift.open' then return app.sync_shift_open(p_payload);
  elsif v_key = 'shift.close' then return app.sync_shift_close(p_payload);
  elsif v_key = 'cash_movement.create' then return app.sync_cash_movement(p_payload);
  elsif v_key = 'order.upsert' then return app.sync_order_upsert(p_payload);
  elsif v_key = 'order.void' then return app.sync_order_void(p_payload);
  elsif v_key = 'order.mark_printed' then return app.sync_order_mark_printed(p_payload);
  elsif v_key = 'refund.create' then return app.sync_refund_create(p_payload);
  elsif v_key = 'customer.upsert' then return app.sync_customer_upsert(p_payload);
  elsif v_key = 'receivable_payment.create' then return app.sync_receivable_payment(p_payload);
  elsif v_key = 'stock_adjustment.create' then return app.sync_stock_adjustment(p_payload);
  elsif v_key = 'stock_opname.submit' then return app.sync_stock_opname_submit(p_payload);
  elsif v_key = 'audit.log' then return app.sync_audit_log(p_payload);
  elsif v_key = 'dining_table.status' then return app.sync_dining_table_status(p_payload);
  elsif v_key = 'kitchen.status' then return app.sync_kitchen_status(p_payload);
  end if;
  perform app.fail('unknown_entity', v_key);
  return null;
end;
$$;

create or replace function app.shift_expected_cash(p_shift_id uuid)
returns bigint
language sql
stable
security definer
set search_path = ''
as $$
  select s.opening_cash
    + coalesce((select sum(p.amount) from public.payments p
                join public.orders o on o.id = p.order_id
                where p.shift_id = s.id and p.method_type = 'cash' and p.status = 'paid'
                  and o.status in ('completed', 'voided')), 0)
    - coalesce((select sum(p.amount) from public.payments p
                join public.orders o on o.id = p.order_id
                where o.voided_shift_id = s.id and p.method_type = 'cash' and p.status = 'paid'), 0)
    - coalesce((select sum(r.amount) from public.refunds r
                where r.shift_id = s.id and r.method_type = 'cash'), 0)
    + coalesce((select sum(rp.amount) from public.receivable_payments rp
                where rp.shift_id = s.id and rp.method_type = 'cash'), 0)
    + coalesce((select sum(case cm.movement_type when 'in' then cm.amount else -cm.amount end)
                from public.cash_movements cm where cm.shift_id = s.id), 0)
  from public.shifts s
  where s.id = p_shift_id
$$;

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
                     join public.orders o on o.id = p.order_id
                     where p.shift_id = s.id and p.method_type = 'cash' and p.status = 'paid'
                       and o.status in ('completed', 'voided')),
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
