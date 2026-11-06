-- =============================================================================
-- CashierA · 1000 · Business logic (functions and triggers)
--   * business dates in the store timezone
--   * stock: one entry point (apply_stock_delta), deterministic row locking
--   * order lifecycle: completion -> stock, loyalty, kasbon, vouchers, tables
--                      void -> reversal; cancel -> release table / KDS
--   * refunds, kasbon repayments, vouchers, adjustments, receiving, transfers,
--     opname, shift cash
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Generic guards
-- ---------------------------------------------------------------------------
create or replace function app.forbid_change()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  perform app.fail('immutable', coalesce(tg_argv[0], tg_table_name || ' rows cannot be changed'));
  return null;
end;
$$;

do $$
declare
  r record;
begin
  for r in
    select * from (values
      ('stock_movements',        'stock history is append-only'),
      ('stock_adjustment_items', 'post a correcting adjustment instead'),
      ('goods_receipt_items',    'post a correcting adjustment instead'),
      ('refunds',                'refunds are final'),
      ('refund_items',           'refunds are final'),
      ('cash_movements',         'record an opposite movement instead'),
      ('receivable_payments',    'record a correcting payment instead'),
      ('loyalty_ledger',         'post an adjust entry instead')
    ) as t(table_name, message)
  loop
    execute format(
      'create trigger %I before update or delete on public.%I for each row execute function app.forbid_change(%L)',
      r.table_name || '_immutable', r.table_name, r.message);
  end loop;
end;
$$;

-- ---------------------------------------------------------------------------
-- Business date (store-local calendar day)
-- ---------------------------------------------------------------------------
create or replace function app.store_local_date(p_store_id uuid, p_at timestamptz)
returns date
language sql
stable
security definer
set search_path = ''
as $$
  select (p_at at time zone s.timezone)::date from public.stores s where s.id = p_store_id
$$;

-- Trigger argument: the timestamp column to derive business_date from.
create or replace function app.set_business_date()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_at timestamptz := (to_jsonb(new) ->> tg_argv[0])::timestamptz;
begin
  new.business_date := app.store_local_date(new.store_id, v_at);
  return new;
end;
$$;

create trigger orders_business_date
before insert or update of ordered_at, store_id on public.orders
for each row execute function app.set_business_date('ordered_at');

create trigger shifts_business_date
before insert or update of opened_at on public.shifts
for each row execute function app.set_business_date('opened_at');

create trigger refunds_business_date
before insert on public.refunds
for each row execute function app.set_business_date('refunded_at');

-- ---------------------------------------------------------------------------
-- Stock core
-- ---------------------------------------------------------------------------

-- Ensure stock rows exist, then lock them in variant-id order (deadlock-safe).
create or replace function app.lock_stock_rows(p_store_id uuid, p_variant_ids uuid[])
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if coalesce(cardinality(p_variant_ids), 0) = 0 then
    return;
  end if;
  insert into public.stock_levels (store_id, variant_id, quantity)
  select p_store_id, v.id, 0
  from (select distinct unnest(p_variant_ids) as id) v
  order by v.id
  on conflict (store_id, variant_id) do nothing;

  perform 1
  from public.stock_levels sl
  where sl.store_id = p_store_id and sl.variant_id = any (p_variant_ids)
  order by sl.variant_id
  for update;
end;
$$;

-- The only way stock changes. Returns the new balance (may be negative).
create or replace function app.apply_stock_delta(
  p_store_id uuid,
  p_variant_id uuid,
  p_delta numeric,
  p_movement_type text,
  p_reference_type text,
  p_reference_id uuid,
  p_employee_id uuid,
  p_note text default null,
  p_unit_cost bigint default null
)
returns numeric
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_delta numeric(14,3) := round(p_delta, 3);
  v_balance numeric(14,3);
  v_cost bigint := p_unit_cost;
begin
  if v_delta is null or v_delta = 0 then
    return null;
  end if;

  insert into public.stock_levels (store_id, variant_id, quantity)
  values (p_store_id, p_variant_id, 0)
  on conflict (store_id, variant_id) do nothing;

  update public.stock_levels
     set quantity = quantity + v_delta
   where store_id = p_store_id and variant_id = p_variant_id
  returning quantity into v_balance;

  if v_cost is null then
    select pv.cost into v_cost from public.product_variants pv where pv.id = p_variant_id;
  end if;

  insert into public.stock_movements (
    store_id, variant_id, movement_type, quantity_delta, balance_after, unit_cost,
    reference_type, reference_id, employee_id, note)
  values (
    p_store_id, p_variant_id, p_movement_type, v_delta, v_balance, coalesce(v_cost, 0),
    p_reference_type, p_reference_id, p_employee_id, p_note);

  return v_balance;
end;
$$;

-- Low stock: while a variant is at or below its reorder point there is exactly one
-- open LOW_STOCK alert; it resolves itself once stock is above the point again.
-- Stock rows are created at 0 and then updated by apply_stock_delta, so watching
-- updates covers every change (and avoids an alert for the empty starter row).
create or replace function app.check_low_stock()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_reorder numeric;
begin
  select s.reorder_point into v_reorder
  from public.store_variant_settings s
  where s.store_id = new.store_id and s.variant_id = new.variant_id;

  if v_reorder is null then
    return new;
  end if;

  if new.quantity <= v_reorder then
    insert into public.alerts (store_id, alert_type, severity, variant_id, reference_type, message, details)
    values (new.store_id, 'LOW_STOCK', 'info', new.variant_id, 'stock_level',
            format('Stock %s is at or below the reorder point %s', new.quantity, v_reorder),
            jsonb_build_object('quantity', new.quantity, 'reorder_point', v_reorder))
    on conflict (store_id, variant_id) where alert_type = 'LOW_STOCK' and status <> 'resolved'
    do nothing;
  elsif old.quantity <= v_reorder then
    update public.alerts
       set status = 'resolved', resolved_at = now(), resolution_note = 'auto: restocked above reorder point'
     where store_id = new.store_id and variant_id = new.variant_id
       and alert_type = 'LOW_STOCK' and status <> 'resolved';
  end if;
  return new;
end;
$$;

create trigger stock_levels_low_stock
after update of quantity on public.stock_levels
for each row execute function app.check_low_stock();

-- What an order consumes: plain stocked items, recipe ingredients, modifier ingredients.
create or replace function app.order_stock_lines(p_order_id uuid)
returns table (variant_id uuid, quantity numeric)
language sql
stable
security definer
set search_path = ''
as $$
  with item as (
    select oi.id, oi.variant_id, oi.quantity, p.track_stock
    from public.order_items oi
    join public.products p on p.id = oi.product_id
    where oi.order_id = p_order_id
  ),
  lines as (
    select i.variant_id, i.quantity
    from item i
    where i.track_stock
      and not exists (select 1 from public.recipe_items r where r.variant_id = i.variant_id)
    union all
    select r.ingredient_variant_id, i.quantity * r.quantity
    from item i
    join public.recipe_items r on r.variant_id = i.variant_id
    union all
    select mr.ingredient_variant_id, i.quantity * mr.quantity
    from item i
    join public.order_item_modifiers m on m.order_item_id = i.id
    join public.modifier_recipe_items mr on mr.modifier_id = m.modifier_id
  )
  select l.variant_id, round(sum(l.quantity), 3)
  from lines l
  join public.product_variants v on v.id = l.variant_id
  join public.products p on p.id = v.product_id
  where p.track_stock
  group by l.variant_id
  having round(sum(l.quantity), 3) <> 0
$$;

-- Deduct an order's stock. Returns how many variants went negative.
create or replace function app.deduct_order_stock(p_order_id uuid)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_order record;
  v_line record;
  v_ids uuid[];
  v_balance numeric;
  v_negative integer := 0;
begin
  select o.id, o.store_id, o.cashier_id, o.order_number into v_order
  from public.orders o where o.id = p_order_id;

  select coalesce(array_agg(l.variant_id order by l.variant_id), '{}') into v_ids
  from app.order_stock_lines(p_order_id) l;

  perform app.lock_stock_rows(v_order.store_id, v_ids);

  for v_line in
    select l.variant_id, l.quantity from app.order_stock_lines(p_order_id) l order by l.variant_id
  loop
    v_balance := app.apply_stock_delta(
      v_order.store_id, v_line.variant_id, -v_line.quantity, 'sale', 'order', p_order_id, v_order.cashier_id);
    if v_balance < 0 then
      v_negative := v_negative + 1;
      insert into public.alerts (store_id, alert_type, severity, variant_id, reference_type, reference_id, message, details)
      values (v_order.store_id, 'STOCK_DISCREPANCY', 'warning', v_line.variant_id, 'order', p_order_id,
              format('Stock fell to %s after order %s', v_balance, v_order.order_number),
              jsonb_build_object('balance_after', v_balance, 'quantity_sold', v_line.quantity,
                                 'order_number', v_order.order_number));
    end if;
  end loop;
  return v_negative;
end;
$$;

-- Put back exactly what the order's movements took (idempotent).
create or replace function app.reverse_order_stock(p_order_id uuid, p_employee_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_store uuid;
  v_ids uuid[];
  v_line record;
begin
  select o.store_id into v_store from public.orders o where o.id = p_order_id;

  select coalesce(array_agg(x.variant_id order by x.variant_id), '{}') into v_ids
  from (
    select m.variant_id
    from public.stock_movements m
    where m.reference_type = 'order' and m.reference_id = p_order_id
    group by m.variant_id
    having sum(m.quantity_delta) <> 0
  ) x;

  perform app.lock_stock_rows(v_store, v_ids);

  for v_line in
    select m.variant_id, sum(m.quantity_delta) as net
    from public.stock_movements m
    where m.reference_type = 'order' and m.reference_id = p_order_id
    group by m.variant_id
    having sum(m.quantity_delta) <> 0
    order by m.variant_id
  loop
    perform app.apply_stock_delta(v_store, v_line.variant_id, -v_line.net, 'sale_void', 'order', p_order_id, p_employee_id);
  end loop;
end;
$$;

-- ---------------------------------------------------------------------------
-- Order guards
-- ---------------------------------------------------------------------------
create or replace function app.guard_order_insert()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.status not in ('open', 'held') then
    perform app.fail('order_insert_status',
      'orders are inserted open or held, then completed or cancelled by an update');
  end if;
  return new;
end;
$$;

create trigger orders_guard_insert
before insert on public.orders
for each row execute function app.guard_order_insert();

create or replace function app.guard_order_update()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.status is distinct from old.status and not (
       (old.status in ('open', 'held') and new.status in ('open', 'held', 'completed', 'cancelled'))
    or (old.status = 'completed' and new.status = 'voided')
  ) then
    perform app.fail('order_invalid_transition', format('%s -> %s', old.status, new.status));
  end if;

  if old.status in ('completed', 'voided', 'cancelled') and (
       new.store_id, new.order_number, new.cashier_id, new.customer_id, new.shift_id, new.ordered_at,
       new.gross_total, new.item_discount_total, new.bill_discount_total, new.points_redeemed,
       new.points_discount, new.net_total, new.service_charge_total, new.tax_total, new.rounding_amount,
       new.grand_total, new.paid_total, new.change_total, new.points_earned
     ) is distinct from (
       old.store_id, old.order_number, old.cashier_id, old.customer_id, old.shift_id, old.ordered_at,
       old.gross_total, old.item_discount_total, old.bill_discount_total, old.points_redeemed,
       old.points_discount, old.net_total, old.service_charge_total, old.tax_total, old.rounding_amount,
       old.grand_total, old.paid_total, old.change_total, old.points_earned
     ) then
    perform app.fail('order_immutable', 'a closed order cannot be edited; void or refund it instead');
  end if;
  return new;
end;
$$;

create trigger orders_guard_update
before update on public.orders
for each row execute function app.guard_order_update();

-- Lines, modifiers, discounts and payments freeze once the order is closed.
create or replace function app.guard_closed_order_children()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_row jsonb := to_jsonb(coalesce(new, old));
  v_order_id uuid;
  v_status text;
begin
  if tg_table_name = 'order_item_modifiers' then
    select oi.order_id into v_order_id from public.order_items oi where oi.id = (v_row ->> 'order_item_id')::uuid;
  else
    v_order_id := (v_row ->> 'order_id')::uuid;
  end if;

  select o.status into v_status from public.orders o where o.id = v_order_id;

  if v_status in ('completed', 'voided', 'cancelled') then
    if tg_table_name = 'order_items' and tg_op = 'UPDATE'
       and (to_jsonb(new) - 'refunded_quantity' - 'updated_at') = (to_jsonb(old) - 'refunded_quantity' - 'updated_at') then
      return new;
    end if;
    perform app.fail('order_immutable', 'lines of a closed order cannot change');
  end if;
  return coalesce(new, old);
end;
$$;

create trigger order_items_guard
before insert or update or delete on public.order_items
for each row execute function app.guard_closed_order_children();

create trigger order_item_modifiers_guard
before insert or update or delete on public.order_item_modifiers
for each row execute function app.guard_closed_order_children();

create trigger order_discounts_guard
before insert or update or delete on public.order_discounts
for each row execute function app.guard_closed_order_children();

create trigger payments_guard
before insert or update or delete on public.payments
for each row execute function app.guard_closed_order_children();

-- ---------------------------------------------------------------------------
-- Order validation (the money contract shared with cashiera_core)
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
  if v_items.tax <> o.tax_total then
    perform app.fail('order_totals_mismatch', format('lines tax %s <> tax_total %s', v_items.tax, o.tax_total));
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
end;
$$;

-- ---------------------------------------------------------------------------
-- Order lifecycle effects
-- ---------------------------------------------------------------------------
create or replace function app.complete_order(p_order_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  o public.orders%rowtype;
  v_negative integer;
  v_kasbon bigint;
  v_due_days integer;
  v_limit bigint;
  v_outstanding bigint;
  v_reasons text[] := '{}';
begin
  select * into o from public.orders where id = p_order_id;
  perform app.validate_order_totals(p_order_id);

  v_negative := app.deduct_order_stock(p_order_id);
  if v_negative > 0 then
    v_reasons := v_reasons || 'stock_negative'::text;
  end if;

  if o.customer_id is not null then
    if o.points_redeemed > 0 then
      insert into public.loyalty_ledger (customer_id, store_id, order_id, entry_type, points, employee_id)
      values (o.customer_id, o.store_id, o.id, 'redeem', -o.points_redeemed, o.cashier_id)
      on conflict (order_id, entry_type) where order_id is not null and refund_id is null do nothing;
    end if;
    if o.points_earned > 0 then
      insert into public.loyalty_ledger (customer_id, store_id, order_id, entry_type, points, employee_id)
      values (o.customer_id, o.store_id, o.id, 'earn', o.points_earned, o.cashier_id)
      on conflict (order_id, entry_type) where order_id is not null and refund_id is null do nothing;
    end if;
  end if;

  select coalesce(sum(p.amount), 0) into v_kasbon
  from public.payments p
  where p.order_id = o.id and p.method_type = 'kasbon';

  if v_kasbon > 0 then
    select bp.kasbon_default_due_days into v_due_days from public.business_profile bp where bp.id = 1;
    select c.kasbon_limit into v_limit from public.customers c where c.id = o.customer_id;
    select coalesce(sum(r.amount - r.paid_amount), 0) into v_outstanding
    from public.receivables r
    where r.customer_id = o.customer_id and r.status in ('open', 'partial');

    insert into public.receivables (store_id, customer_id, order_id, amount, due_date)
    values (o.store_id, o.customer_id, o.id, v_kasbon,
            coalesce(o.kasbon_due_date, o.business_date + coalesce(v_due_days, 30)))
    on conflict (order_id) do nothing;

    if v_limit is not null and v_outstanding + v_kasbon > v_limit then
      v_reasons := v_reasons || 'kasbon_limit_exceeded'::text;
      insert into public.alerts (store_id, alert_type, severity, reference_type, reference_id, message, details)
      values (o.store_id, 'KASBON_LIMIT', 'warning', 'order', o.id,
              format('Kasbon limit Rp %s exceeded (outstanding Rp %s)', v_limit, v_outstanding + v_kasbon),
              jsonb_build_object('customer_id', o.customer_id, 'limit', v_limit, 'outstanding', v_outstanding + v_kasbon));
    end if;
  end if;

  insert into public.voucher_redemptions (voucher_id, order_id, store_id, customer_id, amount)
  select d.voucher_id, o.id, o.store_id, o.customer_id, sum(d.amount)
  from public.order_discounts d
  where d.order_id = o.id and d.voucher_id is not null
  group by d.voucher_id
  on conflict (voucher_id, order_id) do nothing;

  if o.table_id is not null then
    update public.dining_tables
       set status = 'cleaning', current_order_id = null
     where id = o.table_id and (current_order_id = o.id or current_order_id is null);
  end if;

  if cardinality(v_reasons) > 0 then
    update public.orders
       set needs_review = true,
           review_reason = array_to_string(array_remove(array[nullif(review_reason, '')] || v_reasons, null), '; ')
     where id = o.id;
  end if;
end;
$$;

create or replace function app.void_order_effects(p_order_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  o public.orders%rowtype;
  r public.receivables%rowtype;
begin
  select * into o from public.orders where id = p_order_id;

  if o.refunded_total > 0 then
    perform app.fail('void_after_refund', 'this order already has refunds');
  end if;

  select * into r from public.receivables where order_id = p_order_id for update;
  if found then
    if r.paid_amount > 0 then
      perform app.fail('void_with_kasbon_payments', 'kasbon repayments exist; refund instead');
    end if;
    update public.receivables set status = 'void' where id = r.id;
  end if;

  perform app.reverse_order_stock(p_order_id, o.voided_by);

  if o.customer_id is not null then
    insert into public.loyalty_ledger (customer_id, store_id, order_id, entry_type, points, employee_id, note)
    select o.customer_id, o.store_id, o.id, 'reverse_earn', -l.points, o.voided_by, 'void'
    from public.loyalty_ledger l
    where l.order_id = o.id and l.refund_id is null and l.entry_type = 'earn'
    on conflict (order_id, entry_type) where order_id is not null and refund_id is null do nothing;

    insert into public.loyalty_ledger (customer_id, store_id, order_id, entry_type, points, employee_id, note)
    select o.customer_id, o.store_id, o.id, 'reverse_redeem', -l.points, o.voided_by, 'void'
    from public.loyalty_ledger l
    where l.order_id = o.id and l.refund_id is null and l.entry_type = 'redeem'
    on conflict (order_id, entry_type) where order_id is not null and refund_id is null do nothing;
  end if;

  update public.voucher_redemptions set is_reversed = true where order_id = o.id and not is_reversed;
  update public.order_status set status = 'cancelled' where order_id = o.id and status not in ('served', 'cancelled');
end;
$$;

create or replace function app.release_order_resources(p_order_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.dining_tables
     set status = 'available', current_order_id = null
   where current_order_id = p_order_id;
  update public.order_status
     set status = 'cancelled'
   where order_id = p_order_id and status not in ('served', 'cancelled');
end;
$$;

create or replace function app.on_order_status_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.status = 'completed' then
    perform app.complete_order(new.id);
  elsif new.status = 'voided' then
    perform app.void_order_effects(new.id);
  elsif new.status = 'cancelled' then
    perform app.release_order_resources(new.id);
  end if;
  return new;
end;
$$;

create trigger orders_status_change
after update of status on public.orders
for each row
when (old.status is distinct from new.status)
execute function app.on_order_status_change();

-- ---------------------------------------------------------------------------
-- Loyalty, kasbon, vouchers
-- ---------------------------------------------------------------------------
create or replace function app.apply_loyalty_entry()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_balance integer;
begin
  update public.customers
     set points_balance = points_balance + new.points
   where id = new.customer_id
  returning points_balance into v_balance;

  if v_balance < 0 then
    insert into public.alerts (store_id, alert_type, severity, reference_type, reference_id, message, details)
    values (new.store_id, 'LOYALTY_NEGATIVE', 'warning', 'customer', new.customer_id,
            format('Customer points balance is negative (%s)', v_balance),
            jsonb_build_object('balance', v_balance, 'ledger_id', new.id));
  end if;
  return new;
end;
$$;

create trigger loyalty_ledger_apply
after insert on public.loyalty_ledger
for each row execute function app.apply_loyalty_entry();

create or replace function app.apply_receivable_payment()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  r public.receivables%rowtype;
  v_paid bigint;
begin
  select * into r from public.receivables where id = new.receivable_id for update;
  if r.status = 'void' then
    perform app.fail('receivable_void', 'this kasbon was voided');
  end if;
  if new.store_id <> r.store_id then
    perform app.fail('store_mismatch', 'kasbon is repaid at the store that issued it');
  end if;

  v_paid := r.paid_amount + new.amount;
  update public.receivables
     set paid_amount = v_paid,
         status = case when v_paid >= r.amount then 'paid' else 'partial' end
   where id = r.id;

  if v_paid > r.amount then
    insert into public.alerts (store_id, alert_type, severity, reference_type, reference_id, message, details)
    values (r.store_id, 'KASBON_OVERPAID', 'warning', 'receivable', r.id,
            format('Kasbon overpaid by Rp %s', v_paid - r.amount),
            jsonb_build_object('amount', r.amount, 'paid_amount', v_paid, 'payment_id', new.id));
  end if;
  return new;
end;
$$;

create trigger receivable_payments_apply
after insert on public.receivable_payments
for each row execute function app.apply_receivable_payment();

create or replace function app.on_voucher_redemption()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v public.vouchers%rowtype;
begin
  if tg_op = 'INSERT' then
    update public.vouchers set used_count = used_count + 1 where id = new.voucher_id returning * into v;
    if v.max_uses is not null and v.used_count > v.max_uses then
      insert into public.alerts (store_id, alert_type, severity, reference_type, reference_id, message, details)
      values (new.store_id, 'VOUCHER_OVERUSED', 'warning', 'voucher', v.id,
              format('Voucher %s used %s times (limit %s)', v.code, v.used_count, v.max_uses),
              jsonb_build_object('order_id', new.order_id));
    end if;
  elsif tg_op = 'UPDATE' and new.is_reversed and not old.is_reversed then
    update public.vouchers set used_count = greatest(used_count - 1, 0) where id = new.voucher_id;
  end if;
  return new;
end;
$$;

create trigger voucher_redemptions_count
after insert or update of is_reversed on public.voucher_redemptions
for each row execute function app.on_voucher_redemption();

-- ---------------------------------------------------------------------------
-- Refunds (validated by the refund.create handler; effects here)
-- ---------------------------------------------------------------------------
create or replace function app.on_refund()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  o public.orders%rowtype;
begin
  select * into o from public.orders where id = new.order_id for update;
  if o.status <> 'completed' then
    perform app.fail('refund_order_not_completed', 'only completed orders can be refunded');
  end if;
  if new.store_id <> o.store_id then
    perform app.fail('store_mismatch', 'refund store differs from the order store');
  end if;
  if o.refunded_total + new.amount > o.grand_total then
    perform app.fail('refund_exceeds_total', format('at most Rp %s can still be refunded', o.grand_total - o.refunded_total));
  end if;

  update public.orders set refunded_total = refunded_total + new.amount where id = o.id;

  if o.customer_id is not null and new.points_reversed > 0 then
    insert into public.loyalty_ledger (customer_id, store_id, order_id, refund_id, entry_type, points, employee_id, note)
    values (o.customer_id, new.store_id, o.id, new.id, 'reverse_earn', -new.points_reversed, new.employee_id,
            'refund ' || new.refund_number);
  end if;
  return new;
end;
$$;

create trigger refunds_apply
after insert on public.refunds
for each row execute function app.on_refund();

create or replace function app.on_refund_item()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_refund public.refunds%rowtype;
  v_item record;
begin
  select * into v_refund from public.refunds where id = new.refund_id;

  select oi.id, oi.order_id, oi.variant_id, oi.quantity, oi.refunded_quantity, p.track_stock,
         exists (select 1 from public.recipe_items r where r.variant_id = oi.variant_id) as has_recipe
    into v_item
    from public.order_items oi
    join public.products p on p.id = oi.product_id
   where oi.id = new.order_item_id
   for update of oi;

  if v_item.order_id is distinct from v_refund.order_id then
    perform app.fail('refund_item_mismatch', 'the item belongs to another order');
  end if;
  if v_item.refunded_quantity + new.quantity > v_item.quantity then
    perform app.fail('refund_quantity_exceeded', format('only %s left to refund', v_item.quantity - v_item.refunded_quantity));
  end if;

  update public.order_items set refunded_quantity = refunded_quantity + new.quantity where id = new.order_item_id;

  -- Prepared F&B items (recipes) can't go back on the shelf.
  if v_refund.restock and v_item.track_stock and not v_item.has_recipe then
    perform app.lock_stock_rows(v_refund.store_id, array[v_item.variant_id]);
    perform app.apply_stock_delta(v_refund.store_id, v_item.variant_id, new.quantity, 'refund', 'refund',
                                  v_refund.id, v_refund.employee_id);
  end if;
  return new;
end;
$$;

create trigger refund_items_apply
after insert on public.refund_items
for each row execute function app.on_refund_item();

-- ---------------------------------------------------------------------------
-- Stock adjustments
-- ---------------------------------------------------------------------------
create or replace function app.on_stock_adjustment_item()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  a public.stock_adjustments%rowtype;
  v_type text;
begin
  select * into a from public.stock_adjustments where id = new.adjustment_id;
  if new.store_id <> a.store_id then
    perform app.fail('store_mismatch', 'item store differs from the adjustment');
  end if;
  if a.reason in ('initial', 'stock_in') and new.quantity_delta < 0 then
    perform app.fail('adjustment_sign', a.reason || ' needs positive quantities');
  end if;
  if a.reason in ('stock_out', 'damaged', 'expired', 'lost') and new.quantity_delta > 0 then
    perform app.fail('adjustment_sign', a.reason || ' needs negative quantities');
  end if;

  v_type := case a.reason
    when 'initial' then 'initial'
    when 'damaged' then 'waste'
    when 'expired' then 'waste'
    when 'lost' then 'waste'
    else 'adjustment'
  end;

  perform app.lock_stock_rows(a.store_id, array[new.variant_id]);
  perform app.apply_stock_delta(a.store_id, new.variant_id, new.quantity_delta, v_type, 'stock_adjustment',
                                a.id, a.employee_id, a.note, new.unit_cost);
  return new;
end;
$$;

create trigger stock_adjustment_items_apply
after insert on public.stock_adjustment_items
for each row execute function app.on_stock_adjustment_item();

-- ---------------------------------------------------------------------------
-- Purchasing and goods receiving
-- ---------------------------------------------------------------------------
create or replace function app.recalc_purchase_order_total()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_po uuid := coalesce(new.purchase_order_id, old.purchase_order_id);
begin
  update public.purchase_orders po
     set total_amount = coalesce((
       select sum(round(i.quantity_ordered * i.unit_cost)) from public.purchase_order_items i
       where i.purchase_order_id = po.id), 0)
   where po.id = v_po;
  return null;
end;
$$;

create trigger purchase_order_items_total
after insert or update or delete on public.purchase_order_items
for each row execute function app.recalc_purchase_order_total();

create or replace function app.on_goods_receipt_item()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  g public.goods_receipts%rowtype;
  poi public.purchase_order_items%rowtype;
  v_po_status text;
  v_on_hand numeric;
  v_cost bigint;
begin
  select * into g from public.goods_receipts where id = new.goods_receipt_id;
  if new.store_id <> g.store_id then
    perform app.fail('store_mismatch', 'item store differs from the goods receipt');
  end if;

  if g.purchase_order_id is not null then
    select po.status into v_po_status from public.purchase_orders po where po.id = g.purchase_order_id;
    if v_po_status not in ('ordered', 'partially_received') then
      perform app.fail('po_not_open', 'the purchase order is ' || v_po_status);
    end if;
  end if;

  if new.purchase_order_item_id is not null then
    select * into poi from public.purchase_order_items where id = new.purchase_order_item_id for update;
    if poi.purchase_order_id is distinct from g.purchase_order_id or poi.variant_id <> new.variant_id then
      perform app.fail('receipt_po_mismatch', 'the line does not belong to this purchase order');
    end if;
    update public.purchase_order_items set quantity_received = quantity_received + new.quantity where id = poi.id;
  end if;

  -- Weighted average cost across all stores. The variant row lock serializes receipts.
  select pv.cost into v_cost from public.product_variants pv where pv.id = new.variant_id for update;
  select coalesce(sum(greatest(sl.quantity, 0)), 0) into v_on_hand
  from public.stock_levels sl where sl.variant_id = new.variant_id;
  update public.product_variants
     set cost = case
       when v_on_hand + new.quantity > 0
         then round((v_on_hand * v_cost + new.quantity * new.unit_cost) / (v_on_hand + new.quantity))
       else new.unit_cost
     end
   where id = new.variant_id;

  perform app.lock_stock_rows(g.store_id, array[new.variant_id]);
  perform app.apply_stock_delta(g.store_id, new.variant_id, new.quantity, 'purchase_receive', 'goods_receipt',
                                g.id, g.received_by, null, new.unit_cost);

  if g.purchase_order_id is not null then
    update public.purchase_orders po
       set status = case
         when exists (
           select 1 from public.purchase_order_items i
           where i.purchase_order_id = po.id and i.quantity_received < i.quantity_ordered)
         then 'partially_received'
         else 'received'
       end
     where po.id = g.purchase_order_id;
  end if;
  return new;
end;
$$;

create trigger goods_receipt_items_apply
after insert on public.goods_receipt_items
for each row execute function app.on_goods_receipt_item();

-- ---------------------------------------------------------------------------
-- Stock transfers
-- ---------------------------------------------------------------------------
create or replace function app.guard_transfer_update()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if (new.from_store_id, new.to_store_id, new.transfer_number, new.requested_by)
     is distinct from (old.from_store_id, old.to_store_id, old.transfer_number, old.requested_by) then
    perform app.fail('transfer_immutable', 'stores, number and requester cannot change');
  end if;
  if new.status is distinct from old.status and not (
       (old.status = 'requested' and new.status in ('approved', 'rejected', 'cancelled'))
    or (old.status = 'approved' and new.status in ('in_transit', 'cancelled'))
    or (old.status = 'in_transit' and new.status = 'received')
  ) then
    perform app.fail('transfer_invalid_transition', format('%s -> %s', old.status, new.status));
  end if;
  return new;
end;
$$;

create trigger stock_transfers_guard
before update on public.stock_transfers
for each row execute function app.guard_transfer_update();

create or replace function app.on_transfer_status_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_ids uuid[];
  v_line record;
  v_diff jsonb;
begin
  if new.status = 'in_transit' then
    select coalesce(array_agg(i.variant_id order by i.variant_id), '{}') into v_ids
    from public.stock_transfer_items i
    where i.transfer_id = new.id and coalesce(i.quantity_shipped, 0) > 0;
    perform app.lock_stock_rows(new.from_store_id, v_ids);
    for v_line in
      select i.variant_id, i.quantity_shipped from public.stock_transfer_items i
      where i.transfer_id = new.id and coalesce(i.quantity_shipped, 0) > 0
      order by i.variant_id
    loop
      perform app.apply_stock_delta(new.from_store_id, v_line.variant_id, -v_line.quantity_shipped,
                                    'transfer_out', 'stock_transfer', new.id, new.shipped_by);
    end loop;

  elsif new.status = 'received' then
    select coalesce(array_agg(i.variant_id order by i.variant_id), '{}') into v_ids
    from public.stock_transfer_items i
    where i.transfer_id = new.id and coalesce(i.quantity_received, 0) > 0;
    perform app.lock_stock_rows(new.to_store_id, v_ids);
    for v_line in
      select i.variant_id, i.quantity_received from public.stock_transfer_items i
      where i.transfer_id = new.id and coalesce(i.quantity_received, 0) > 0
      order by i.variant_id
    loop
      perform app.apply_stock_delta(new.to_store_id, v_line.variant_id, v_line.quantity_received,
                                    'transfer_in', 'stock_transfer', new.id, new.received_by);
    end loop;

    select jsonb_agg(jsonb_build_object('variant_id', i.variant_id,
                                        'shipped', coalesce(i.quantity_shipped, 0),
                                        'received', coalesce(i.quantity_received, 0)))
      into v_diff
      from public.stock_transfer_items i
     where i.transfer_id = new.id
       and coalesce(i.quantity_received, 0) <> coalesce(i.quantity_shipped, 0);
    if v_diff is not null then
      insert into public.alerts (store_id, alert_type, severity, reference_type, reference_id, message, details)
      values (new.to_store_id, 'TRANSFER_DISCREPANCY', 'warning', 'stock_transfer', new.id,
              format('Transfer %s: received quantities differ from shipped', new.transfer_number),
              jsonb_build_object('from_store_id', new.from_store_id, 'lines', v_diff));
    end if;
  end if;
  return new;
end;
$$;

create trigger stock_transfers_status_change
after update of status on public.stock_transfers
for each row
when (old.status is distinct from new.status)
execute function app.on_transfer_status_change();

-- ---------------------------------------------------------------------------
-- Stock opname
-- ---------------------------------------------------------------------------
create or replace function app.guard_opname_items()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_status text;
begin
  select so.status into v_status
  from public.stock_opnames so
  where so.id = coalesce(new.opname_id, old.opname_id);
  if v_status is distinct from 'draft' then
    perform app.fail('opname_not_draft', 'counts can only change while the opname is a draft');
  end if;
  return coalesce(new, old);
end;
$$;

create trigger stock_opname_items_guard
before insert or update or delete on public.stock_opname_items
for each row execute function app.guard_opname_items();

create or replace function app.complete_opname(p_opname_id uuid, p_employee_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  op public.stock_opnames%rowtype;
  v_ids uuid[];
  v_line record;
  v_system numeric(14,3);
  v_adjusted integer := 0;
begin
  select * into op from public.stock_opnames where id = p_opname_id for update;
  if not found then
    perform app.fail('opname_not_found');
  end if;
  if op.status <> 'draft' then
    perform app.fail('opname_not_draft', op.status);
  end if;

  select coalesce(array_agg(i.variant_id order by i.variant_id), '{}') into v_ids
  from public.stock_opname_items i where i.opname_id = op.id;
  if cardinality(v_ids) = 0 then
    perform app.fail('opname_empty', 'count at least one item');
  end if;

  perform app.lock_stock_rows(op.store_id, v_ids);

  for v_line in
    select i.id, i.variant_id, i.counted_qty
    from public.stock_opname_items i
    where i.opname_id = op.id
    order by i.variant_id
  loop
    select sl.quantity into v_system
    from public.stock_levels sl
    where sl.store_id = op.store_id and sl.variant_id = v_line.variant_id;

    update public.stock_opname_items
       set system_qty = v_system, difference = v_line.counted_qty - v_system
     where id = v_line.id;

    if v_line.counted_qty <> v_system then
      perform app.apply_stock_delta(op.store_id, v_line.variant_id, v_line.counted_qty - v_system, 'opname',
                                    'stock_opname', op.id, p_employee_id, 'opname ' || op.opname_number);
      v_adjusted := v_adjusted + 1;
    end if;
  end loop;

  update public.stock_opnames
     set status = 'completed', completed_by = p_employee_id, completed_at = now()
   where id = op.id;

  return jsonb_build_object('opname_id', op.id, 'lines', cardinality(v_ids), 'adjusted', v_adjusted);
end;
$$;

-- ---------------------------------------------------------------------------
-- Shift cash
-- expected = kas awal + cash sales - cash of orders voided in this shift
--            - cash refunds + cash kasbon repayments + petty cash in - out
-- ---------------------------------------------------------------------------
create or replace function app.shift_expected_cash(p_shift_id uuid)
returns bigint
language sql
stable
security definer
set search_path = ''
as $$
  select s.opening_cash
    + coalesce((select sum(p.amount) from public.payments p
                where p.shift_id = s.id and p.method_type = 'cash' and p.status = 'paid'), 0)
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

-- After a late sync into an already-closed shift, recompute expected cash and selisih.
create or replace function app.recompute_closed_shift(p_shift_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_expected bigint := app.shift_expected_cash(p_shift_id);
begin
  update public.shifts
     set expected_cash = v_expected, cash_difference = counted_cash - v_expected
   where id = p_shift_id and status = 'closed';
end;
$$;
