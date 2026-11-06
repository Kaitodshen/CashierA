-- =============================================================================
-- CashierA · 2000 · Phase 8 (purchasing, transfers, F&B). Atomic purchase
-- order RPCs, a receiving RPC, readable lists for the back office, and the
-- kitchen queue for the kitchen display. Stock, cost and transfer rules are
-- the existing triggers (1000) and transfer RPCs (1100).
-- =============================================================================

create sequence if not exists public.goods_receipt_seq;

-- ---------------------------------------------------------------------------
-- save_purchase_order(p): header + items in one transaction.
--   p = {id?, store_id, supplier_id, expected_date, note,
--        items: [{variant_id, quantity_ordered, unit_cost}]}
-- Allowed while the order is draft or ordered and nothing has been received.
-- ---------------------------------------------------------------------------
create or replace function public.save_purchase_order(p jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid := coalesce((p ->> 'id')::uuid, gen_random_uuid());
  v_store uuid := (p ->> 'store_id')::uuid;
  v_employee uuid := app.current_employee_id();
  po public.purchase_orders%rowtype;
  v_item jsonb;
begin
  if v_employee is null or not (v_store = any (app.store_ids_with(array['purchase.manage'], false))) then
    perform app.fail('permission_denied', 'purchase.manage is required for this store');
  end if;
  if not exists (select 1 from public.suppliers s where s.id = (p ->> 'supplier_id')::uuid and s.is_active) then
    perform app.fail('invalid_input', 'choose an active supplier');
  end if;
  if jsonb_typeof(p -> 'items') is distinct from 'array' or jsonb_array_length(p -> 'items') = 0 then
    perform app.fail('invalid_input', 'a purchase order needs at least one item');
  end if;
  for v_item in select value from jsonb_array_elements(p -> 'items') loop
    if coalesce((v_item ->> 'quantity_ordered')::numeric, 0) <= 0
       or coalesce((v_item ->> 'unit_cost')::bigint, -1) < 0 then
      perform app.fail('invalid_input', 'every line needs a quantity above 0 and a cost of 0 or more');
    end if;
  end loop;

  select * into po from public.purchase_orders where id = v_id for update;
  if found then
    if po.store_id <> v_store then
      perform app.fail('store_mismatch', 'the purchase order belongs to another store');
    end if;
    if po.status not in ('draft', 'ordered')
       or exists (select 1 from public.purchase_order_items i where i.purchase_order_id = po.id and i.quantity_received > 0) then
      perform app.fail('po_locked', 'the purchase order is ' || po.status || ' and can no longer be changed');
    end if;
    update public.purchase_orders
       set supplier_id = (p ->> 'supplier_id')::uuid,
           expected_date = (p ->> 'expected_date')::date,
           note = nullif(trim(p ->> 'note'), '')
     where id = v_id;
    delete from public.purchase_order_items where purchase_order_id = v_id;
  else
    insert into public.purchase_orders (id, store_id, supplier_id, expected_date, note, created_by)
    values (v_id, v_store, (p ->> 'supplier_id')::uuid, (p ->> 'expected_date')::date,
            nullif(trim(p ->> 'note'), ''), v_employee);
  end if;

  insert into public.purchase_order_items (purchase_order_id, variant_id, quantity_ordered, unit_cost)
  select v_id, (x.value ->> 'variant_id')::uuid, (x.value ->> 'quantity_ordered')::numeric,
         (x.value ->> 'unit_cost')::bigint
  from jsonb_array_elements(p -> 'items') x;

  select * into po from public.purchase_orders where id = v_id;
  return jsonb_build_object('purchase_order_id', po.id, 'po_number', po.po_number, 'status', po.status,
                            'total_amount', po.total_amount);
end;
$$;

-- ---------------------------------------------------------------------------
-- set_purchase_order_status(id, status): draft -> ordered; draft or ordered
-- -> cancelled, only before anything was received. Audited.
-- ---------------------------------------------------------------------------
create or replace function public.set_purchase_order_status(p_id uuid, p_status text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  po public.purchase_orders%rowtype;
  v_employee uuid := app.current_employee_id();
begin
  select * into po from public.purchase_orders where id = p_id for update;
  if not found then
    perform app.fail('po_not_found');
  end if;
  if v_employee is null or not (po.store_id = any (app.store_ids_with(array['purchase.manage'], false))) then
    perform app.fail('permission_denied', 'purchase.manage is required for this store');
  end if;
  if not ((po.status = 'draft' and p_status in ('ordered', 'cancelled'))
          or (po.status = 'ordered' and p_status = 'cancelled')) then
    perform app.fail('po_invalid_transition', format('%s -> %s is not allowed', po.status, p_status));
  end if;
  if p_status = 'cancelled' and exists (
       select 1 from public.purchase_order_items i where i.purchase_order_id = po.id and i.quantity_received > 0) then
    perform app.fail('po_invalid_transition', 'goods were already received on this order');
  end if;
  update public.purchase_orders set status = p_status where id = po.id;
  insert into public.audit_log (store_id, actor_employee_id, action, entity_type, entity_id, details)
  values (po.store_id, v_employee, 'purchase.' || p_status, 'purchase_order', po.id,
          jsonb_build_object('po_number', po.po_number, 'total_amount', po.total_amount));
  return jsonb_build_object('purchase_order_id', po.id, 'status', p_status);
end;
$$;

-- ---------------------------------------------------------------------------
-- receive_purchase_order(p): one goods receipt against an ordered PO.
--   p = {purchase_order_id, note, items: [{purchase_order_item_id, quantity, unit_cost?}]}
-- Lines with quantity 0 are skipped. A line may not exceed what is open.
-- ---------------------------------------------------------------------------
create or replace function public.receive_purchase_order(p jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  po public.purchase_orders%rowtype;
  v_employee uuid := app.current_employee_id();
  v_receipt uuid := gen_random_uuid();
  v_number text;
  v_item jsonb;
  poi public.purchase_order_items%rowtype;
  v_qty numeric;
  v_lines integer := 0;
begin
  select * into po from public.purchase_orders where id = (p ->> 'purchase_order_id')::uuid for update;
  if not found then
    perform app.fail('po_not_found');
  end if;
  if v_employee is null or not (po.store_id = any (app.store_ids_with(array['inventory.receive'], false))) then
    perform app.fail('permission_denied', 'inventory.receive is required for this store');
  end if;
  if po.status not in ('ordered', 'partially_received') then
    perform app.fail('po_not_open', 'the purchase order is ' || po.status);
  end if;

  v_number := 'GR-' || (select s.code from public.stores s where s.id = po.store_id) || '-'
              || to_char(now() at time zone 'Asia/Jakarta', 'YYMMDD') || '-'
              || lpad(nextval('public.goods_receipt_seq')::text, 3, '0');
  insert into public.goods_receipts (id, store_id, purchase_order_id, supplier_id, receipt_number, received_by, note)
  values (v_receipt, po.store_id, po.id, po.supplier_id, v_number, v_employee, nullif(trim(p ->> 'note'), ''));

  for v_item in select value from jsonb_array_elements(coalesce(p -> 'items', '[]'::jsonb)) loop
    v_qty := coalesce((v_item ->> 'quantity')::numeric, 0);
    continue when v_qty = 0;
    select * into poi from public.purchase_order_items
    where id = (v_item ->> 'purchase_order_item_id')::uuid and purchase_order_id = po.id;
    if not found then
      perform app.fail('invalid_input', 'the line is not on this purchase order');
    end if;
    if v_qty < 0 or poi.quantity_received + v_qty > poi.quantity_ordered then
      perform app.fail('receipt_exceeds_order',
        format('at most %s left to receive on this line', poi.quantity_ordered - poi.quantity_received));
    end if;
    insert into public.goods_receipt_items (goods_receipt_id, store_id, variant_id, purchase_order_item_id, quantity, unit_cost)
    values (v_receipt, po.store_id, poi.variant_id, poi.id, v_qty,
            coalesce((v_item ->> 'unit_cost')::bigint, poi.unit_cost));
    v_lines := v_lines + 1;
  end loop;
  if v_lines = 0 then
    perform app.fail('invalid_input', 'receive at least one item');
  end if;

  insert into public.audit_log (store_id, actor_employee_id, action, entity_type, entity_id, details)
  values (po.store_id, v_employee, 'purchase.received', 'purchase_order', po.id,
          jsonb_build_object('po_number', po.po_number, 'receipt_number', v_number, 'lines', v_lines));
  select * into po from public.purchase_orders where id = po.id;
  return jsonb_build_object('goods_receipt_id', v_receipt, 'receipt_number', v_number, 'status', po.status);
end;
$$;

-- ---------------------------------------------------------------------------
-- purchase_order_list(store, status) and purchase_order_detail(id).
-- ---------------------------------------------------------------------------
create or replace function public.purchase_order_list(p_store_id uuid default null, p_status text default null)
returns table (
  purchase_order_id uuid, po_number text, store_id uuid, store_code text, supplier_name text,
  status text, order_date date, expected_date date, total_amount bigint, line_count bigint,
  received_ratio numeric
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_stores uuid[] := app.store_ids_with(array['purchase.manage', 'inventory.view', 'reports.view'], false);
begin
  if p_store_id is not null and not (p_store_id = any (v_stores)) then
    perform app.fail('permission_denied', 'no access to this store''s purchasing');
  end if;
  return query
  select po.id, po.po_number, po.store_id, st.code, s.name, po.status, po.order_date, po.expected_date,
         po.total_amount, (select count(*) from public.purchase_order_items i where i.purchase_order_id = po.id),
         coalesce((select round(sum(least(i.quantity_received, i.quantity_ordered)) / nullif(sum(i.quantity_ordered), 0), 3)
                   from public.purchase_order_items i where i.purchase_order_id = po.id), 0)
  from public.purchase_orders po
  join public.stores st on st.id = po.store_id
  join public.suppliers s on s.id = po.supplier_id
  where po.store_id = any (v_stores)
    and (p_store_id is null or po.store_id = p_store_id)
    and (p_status is null or po.status = p_status)
  order by po.created_at desc
  limit 500;
end;
$$;

create or replace function public.purchase_order_detail(p_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  po public.purchase_orders%rowtype;
begin
  select * into po from public.purchase_orders where id = p_id;
  if not found or not (po.store_id = any (app.store_ids_with(array['purchase.manage', 'inventory.view', 'reports.view'], false))) then
    perform app.fail('po_not_found');
  end if;
  return jsonb_build_object(
    'purchase_order_id', po.id, 'po_number', po.po_number, 'status', po.status,
    'store_id', po.store_id, 'store_name', (select s.name from public.stores s where s.id = po.store_id),
    'supplier_id', po.supplier_id,
    'supplier', (select jsonb_build_object('name', s.name, 'contact_name', s.contact_name, 'phone', s.phone,
                                           'address', s.address)
                 from public.suppliers s where s.id = po.supplier_id),
    'order_date', po.order_date, 'expected_date', po.expected_date, 'note', po.note,
    'total_amount', po.total_amount,
    'created_by_name', (select e.full_name from public.employees e where e.id = po.created_by),
    'items', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id', i.id, 'variant_id', i.variant_id,
               'name', p.name || coalesce(' ' || nullif(v.name, 'Default'), ''), 'sku', v.sku,
               'unit', u.code, 'quantity_ordered', i.quantity_ordered, 'quantity_received', i.quantity_received,
               'unit_cost', i.unit_cost, 'line_total', round(i.quantity_ordered * i.unit_cost))
             order by p.name, v.name)
      from public.purchase_order_items i
      join public.product_variants v on v.id = i.variant_id
      join public.products p on p.id = v.product_id
      join public.units u on u.id = p.unit_id
      where i.purchase_order_id = po.id), '[]'::jsonb),
    'receipts', coalesce((
      select jsonb_agg(jsonb_build_object(
               'receipt_number', g.receipt_number, 'received_at', g.received_at,
               'received_by_name', e.full_name, 'note', g.note,
               'lines', (select count(*) from public.goods_receipt_items gi where gi.goods_receipt_id = g.id))
             order by g.received_at)
      from public.goods_receipts g
      left join public.employees e on e.id = g.received_by
      where g.purchase_order_id = po.id), '[]'::jsonb)
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- transfer_list(store, direction, status) and transfer_detail(id).
-- direction: 'in' (to the store), 'out' (from the store) or null (both).
-- ---------------------------------------------------------------------------
create or replace function public.transfer_list(p_store_id uuid default null, p_direction text default null,
                                                p_status text default null)
returns table (
  transfer_id uuid, transfer_number text, from_store_id uuid, from_store text, to_store_id uuid, to_store text,
  status text, requested_at timestamptz, requested_by_name text, line_count bigint
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_stores uuid[] := app.store_ids_with(
    array['inventory.view', 'transfer.request', 'transfer.approve', 'reports.view'], false);
begin
  if p_store_id is not null and not (p_store_id = any (v_stores)) then
    perform app.fail('permission_denied', 'no access to this store''s transfers');
  end if;
  return query
  select t.id, t.transfer_number, t.from_store_id, f.code || ' · ' || f.name, t.to_store_id,
         d.code || ' · ' || d.name, t.status, t.requested_at, e.full_name,
         (select count(*) from public.stock_transfer_items i where i.transfer_id = t.id)
  from public.stock_transfers t
  join public.stores f on f.id = t.from_store_id
  join public.stores d on d.id = t.to_store_id
  left join public.employees e on e.id = t.requested_by
  where (t.from_store_id = any (v_stores) or t.to_store_id = any (v_stores))
    and (p_store_id is null
         or (coalesce(p_direction, '') <> 'out' and t.to_store_id = p_store_id)
         or (coalesce(p_direction, '') <> 'in' and t.from_store_id = p_store_id))
    and (p_status is null or t.status = p_status)
  order by t.requested_at desc
  limit 500;
end;
$$;

create or replace function public.transfer_detail(p_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  t public.stock_transfers%rowtype;
  v_stores uuid[] := app.store_ids_with(
    array['inventory.view', 'transfer.request', 'transfer.approve', 'reports.view'], false);
begin
  select * into t from public.stock_transfers where id = p_id;
  if not found or not (t.from_store_id = any (v_stores) or t.to_store_id = any (v_stores)) then
    perform app.fail('transfer_not_found');
  end if;
  return jsonb_build_object(
    'transfer_id', t.id, 'transfer_number', t.transfer_number, 'status', t.status, 'note', t.note,
    'from_store_id', t.from_store_id,
    'from_store', (select s.code || ' · ' || s.name from public.stores s where s.id = t.from_store_id),
    'to_store_id', t.to_store_id,
    'to_store', (select s.code || ' · ' || s.name from public.stores s where s.id = t.to_store_id),
    'reject_reason', t.reject_reason,
    'events', jsonb_strip_nulls(jsonb_build_object(
      'requested', jsonb_build_object('at', t.requested_at, 'by', (select full_name from public.employees where id = t.requested_by)),
      'approved', case when t.approved_at is not null then jsonb_build_object('at', t.approved_at, 'by', (select full_name from public.employees where id = t.approved_by)) end,
      'shipped', case when t.shipped_at is not null then jsonb_build_object('at', t.shipped_at, 'by', (select full_name from public.employees where id = t.shipped_by)) end,
      'received', case when t.received_at is not null then jsonb_build_object('at', t.received_at, 'by', (select full_name from public.employees where id = t.received_by)) end,
      'rejected', case when t.rejected_at is not null then jsonb_build_object('at', t.rejected_at, 'by', (select full_name from public.employees where id = t.rejected_by)) end,
      'cancelled', case when t.cancelled_at is not null then jsonb_build_object('at', t.cancelled_at, 'by', (select full_name from public.employees where id = t.cancelled_by)) end)),
    'items', coalesce((
      select jsonb_agg(jsonb_build_object(
               'variant_id', i.variant_id, 'name', p.name || coalesce(' ' || nullif(v.name, 'Default'), ''),
               'sku', v.sku, 'quantity_requested', i.quantity_requested, 'quantity_shipped', i.quantity_shipped,
               'quantity_received', i.quantity_received,
               'stock_at_sender', (select sl.quantity from public.stock_levels sl
                                   where sl.store_id = t.from_store_id and sl.variant_id = i.variant_id))
             order by p.name, v.name)
      from public.stock_transfer_items i
      join public.product_variants v on v.id = i.variant_id
      join public.products p on p.id = v.product_id
      where i.transfer_id = t.id), '[]'::jsonb)
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- kitchen_queue(station): the active tickets of the caller's store (a paired
-- terminal, or staff with kitchen.view), oldest first, each with only that
-- station's items. station null = both.
-- ---------------------------------------------------------------------------
create or replace function public.kitchen_queue(p_station text default null, p_store_id uuid default null)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_store uuid := coalesce(app.current_device_store_id(), p_store_id);
begin
  if v_store is null or not (v_store = any (app.store_ids_with(array['kitchen.view']))) then
    perform app.fail('permission_denied', 'kitchen.view is required for this store');
  end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'order_id', o.id, 'order_number', o.order_number, 'station', k.station, 'status', k.status,
             'order_type', o.order_type, 'table_name', dt.name, 'guest_count', o.guest_count, 'note', o.note,
             'created_at', k.created_at, 'updated_at', k.updated_at,
             'items', (
               select coalesce(jsonb_agg(jsonb_build_object(
                        'name', oi.product_name || coalesce(' ' || nullif(oi.variant_name, 'Default'), ''),
                        'quantity', oi.quantity, 'note', oi.note,
                        'modifiers', (select coalesce(jsonb_agg(m.modifier_name order by m.modifier_name), '[]'::jsonb)
                                      from public.order_item_modifiers m where m.order_item_id = oi.id))
                      order by oi.sort_order), '[]'::jsonb)
               from public.order_items oi
               where oi.order_id = o.id and oi.kitchen_station = k.station))
           order by k.created_at, o.order_number)
    from public.order_status k
    join public.orders o on o.id = k.order_id
    left join public.dining_tables dt on dt.id = o.table_id
    where k.store_id = v_store and k.status in ('new', 'preparing', 'ready')
      and o.status not in ('cancelled', 'voided')
      and (p_station is null or k.station = p_station)), '[]'::jsonb);
end;
$$;

revoke execute on function public.save_purchase_order(jsonb), public.set_purchase_order_status(uuid, text),
  public.receive_purchase_order(jsonb), public.purchase_order_list(uuid, text), public.purchase_order_detail(uuid),
  public.transfer_list(uuid, text, text), public.transfer_detail(uuid), public.kitchen_queue(text, uuid)
  from public, anon;
grant execute on function public.save_purchase_order(jsonb), public.set_purchase_order_status(uuid, text),
  public.receive_purchase_order(jsonb), public.purchase_order_list(uuid, text), public.purchase_order_detail(uuid),
  public.transfer_list(uuid, text, text), public.transfer_detail(uuid), public.kitchen_queue(text, uuid)
  to authenticated, service_role;
