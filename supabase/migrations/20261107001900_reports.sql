-- =============================================================================
-- CashierA · 1900 · Phase 7 (dashboard and reports). Read-only report RPCs
-- for the back office. Every report takes p_store_id (null = every store the
-- caller may see with reports.view) and an inclusive business_date range.
-- Sales are completed orders; voids and refunds are reported separately;
-- net sales = grand total - refunds.
-- =============================================================================

-- Stores a report covers, or permission_denied.
create or replace function app.report_stores(p_store_id uuid)
returns uuid[]
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_stores uuid[] := app.store_ids_with(array['reports.view'], false);
begin
  if p_store_id is not null then
    if not (p_store_id = any (v_stores)) then
      perform app.fail('permission_denied', 'reports.view is required for this store');
    end if;
    return array[p_store_id];
  end if;
  if cardinality(v_stores) = 0 then
    perform app.fail('permission_denied', 'reports.view is required');
  end if;
  return v_stores;
end;
$$;

create or replace function app.report_period(p_from date, p_to date)
returns void
language plpgsql
immutable
set search_path = ''
as $$
begin
  if p_from is null or p_to is null then
    perform app.fail('invalid_input', 'a period is required');
  end if;
  if p_to < p_from then
    perform app.fail('invalid_input', 'the period ends before it starts');
  end if;
  if p_to - p_from > 366 then
    perform app.fail('invalid_input', 'a report covers at most 367 days');
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- report_sales: totals, by day (every date), by store-local hour, by store.
-- ---------------------------------------------------------------------------
create or replace function public.report_sales(p_store_id uuid, p_from date, p_to date)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_stores uuid[] := app.report_stores(p_store_id);
begin
  perform app.report_period(p_from, p_to);
  return (
    with sales as (
      select o.* from public.orders o
      where o.store_id = any (v_stores) and o.status = 'completed'
        and o.business_date between p_from and p_to
    ),
    refunds as (
      select r.* from public.refunds r
      where r.store_id = any (v_stores) and r.business_date between p_from and p_to
    ),
    voids as (
      select o.* from public.orders o
      where o.store_id = any (v_stores) and o.status = 'voided'
        and o.business_date between p_from and p_to
    )
    select jsonb_build_object(
      'totals', (
        select jsonb_build_object(
          'orders', count(*),
          'items', coalesce((select sum(oi.quantity) from public.order_items oi
                             where oi.order_id in (select id from sales)), 0),
          'gross', coalesce(sum(s.gross_total), 0),
          'discounts', coalesce(sum(s.item_discount_total + s.bill_discount_total + s.points_discount), 0),
          'net', coalesce(sum(s.net_total), 0),
          'service', coalesce(sum(s.service_charge_total), 0),
          'tax', coalesce(sum(s.tax_total), 0),
          'rounding', coalesce(sum(s.rounding_amount), 0),
          'grand', coalesce(sum(s.grand_total), 0),
          'average', coalesce(round(avg(s.grand_total)), 0),
          'refund_count', (select count(*) from refunds),
          'refunds', (select coalesce(sum(amount), 0) from refunds),
          'net_sales', coalesce(sum(s.grand_total), 0) - (select coalesce(sum(amount), 0) from refunds),
          'void_count', (select count(*) from voids),
          'voids', (select coalesce(sum(grand_total), 0) from voids))
        from sales s),
      'by_day', (
        select jsonb_agg(jsonb_build_object(
                 'date', d::date,
                 'orders', (select count(*) from sales s where s.business_date = d::date),
                 'grand', (select coalesce(sum(s.grand_total), 0) from sales s where s.business_date = d::date),
                 'refunds', (select coalesce(sum(r.amount), 0) from refunds r where r.business_date = d::date))
               order by d)
        from generate_series(p_from::timestamp, p_to::timestamp, interval '1 day') d),
      'by_hour', (
        select jsonb_agg(jsonb_build_object(
                 'hour', h,
                 'orders', coalesce(x.orders, 0),
                 'grand', coalesce(x.grand, 0))
               order by h)
        from generate_series(0, 23) h
        left join (
          select extract(hour from coalesce(s.completed_at, s.ordered_at) at time zone st.timezone)::int as hour,
                 count(*) as orders, sum(s.grand_total) as grand
          from sales s join public.stores st on st.id = s.store_id
          group by 1
        ) x on x.hour = h),
      'by_store', coalesce((
        select jsonb_agg(jsonb_build_object(
                 'store_id', st.id, 'store_name', st.name, 'store_code', st.code,
                 'orders', (select count(*) from sales s where s.store_id = st.id),
                 'grand', (select coalesce(sum(s.grand_total), 0) from sales s where s.store_id = st.id),
                 'refunds', (select coalesce(sum(r.amount), 0) from refunds r where r.store_id = st.id))
               order by st.code)
        from public.stores st where st.id = any (v_stores)), '[]'::jsonb)
    )
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- report_payments: completed sales by payment method, refunds by method,
-- kasbon issued in the period and repaid in the period (store-local date).
-- ---------------------------------------------------------------------------
create or replace function public.report_payments(p_store_id uuid, p_from date, p_to date)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_stores uuid[] := app.report_stores(p_store_id);
begin
  perform app.report_period(p_from, p_to);
  return jsonb_build_object(
    'methods', coalesce((
      select jsonb_agg(jsonb_build_object(
               'payment_method_id', x.id, 'name', x.name, 'method_type', x.method_type,
               'count', x.n, 'amount', x.amount) order by x.sort_order, x.name)
      from (
        select pm.id, pm.name, pm.method_type, pm.sort_order, count(*) as n, sum(p.amount) as amount
        from public.payments p
        join public.orders o on o.id = p.order_id
        join public.payment_methods pm on pm.id = p.payment_method_id
        where o.store_id = any (v_stores) and o.status = 'completed' and p.status = 'paid'
          and o.business_date between p_from and p_to
        group by pm.id, pm.name, pm.method_type, pm.sort_order
      ) x), '[]'::jsonb),
    'refunds', coalesce((
      select jsonb_agg(jsonb_build_object('method_type', x.method_type, 'count', x.n, 'amount', x.amount)
                       order by x.method_type)
      from (
        select r.method_type, count(*) as n, sum(r.amount) as amount
        from public.refunds r
        where r.store_id = any (v_stores) and r.business_date between p_from and p_to
        group by r.method_type
      ) x), '[]'::jsonb),
    'kasbon', jsonb_build_object(
      'issued', (select coalesce(sum(p.amount), 0) from public.payments p
                 join public.orders o on o.id = p.order_id
                 where o.store_id = any (v_stores) and o.status = 'completed' and p.method_type = 'kasbon'
                   and o.business_date between p_from and p_to),
      'repaid', (select coalesce(sum(rp.amount), 0) from public.receivable_payments rp
                 where rp.store_id = any (v_stores)
                   and app.store_local_date(rp.store_id, rp.paid_at) between p_from and p_to))
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- report_products: by variant (largest net first, at most p_limit) and by
-- category. net is before refunds; refunded_* are the refunds of those
-- sales, whenever they happened.
-- ---------------------------------------------------------------------------
create or replace function public.report_products(p_store_id uuid, p_from date, p_to date, p_limit integer default 100)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_stores uuid[] := app.report_stores(p_store_id);
begin
  perform app.report_period(p_from, p_to);
  return (
    with lines as (
      select oi.*, p.category_id,
             coalesce((select sum(ri.amount) from public.refund_items ri where ri.order_item_id = oi.id), 0)
               as refunded_amount
      from public.order_items oi
      join public.orders o on o.id = oi.order_id
      join public.products p on p.id = oi.product_id
      where o.store_id = any (v_stores) and o.status = 'completed'
        and o.business_date between p_from and p_to
    )
    select jsonb_build_object(
      'variants', coalesce((
        select jsonb_agg(v order by (v ->> 'net')::bigint desc, v ->> 'name')
        from (
          select jsonb_build_object(
                   'variant_id', l.variant_id,
                   'name', min(l.product_name || coalesce(' ' || nullif(l.variant_name, 'Default'), '')),
                   'sku', min(l.sku),
                   'category', (select c.name from public.categories c where c.id = min(l.category_id::text)::uuid),
                   'quantity', sum(l.quantity),
                   'refunded_quantity', sum(l.refunded_quantity),
                   'net', sum(l.net_amount),
                   'refunded', sum(l.refunded_amount),
                   'cost', sum(l.cost_amount),
                   'margin', sum(l.net_amount) - sum(l.cost_amount)) as v
          from lines l
          group by l.variant_id
          order by sum(l.net_amount) desc, min(l.product_name)
          limit greatest(coalesce(p_limit, 100), 1)
        ) x), '[]'::jsonb),
      'variant_count', (select count(distinct variant_id) from lines),
      'categories', coalesce((
        select jsonb_agg(jsonb_build_object(
                 'category_id', x.category_id, 'name', coalesce(c.name, '-'),
                 'quantity', x.quantity, 'net', x.net, 'cost', x.cost, 'margin', x.net - x.cost)
               order by x.net desc, c.name)
        from (
          select l.category_id, sum(l.quantity) as quantity, sum(l.net_amount) as net, sum(l.cost_amount) as cost
          from lines l group by l.category_id
        ) x left join public.categories c on c.id = x.category_id), '[]'::jsonb),
      'totals', (
        select jsonb_build_object(
          'quantity', coalesce(sum(l.quantity), 0), 'net', coalesce(sum(l.net_amount), 0),
          'refunded', coalesce(sum(l.refunded_amount), 0), 'cost', coalesce(sum(l.cost_amount), 0),
          'margin', coalesce(sum(l.net_amount) - sum(l.cost_amount), 0))
        from lines l)
    )
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- report_staff: per cashier (sales), plus voids (voided_by) and refunds
-- (employee_id) in the period.
-- ---------------------------------------------------------------------------
create or replace function public.report_staff(p_store_id uuid, p_from date, p_to date)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_stores uuid[] := app.report_stores(p_store_id);
begin
  perform app.report_period(p_from, p_to);
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'employee_id', e.id, 'name', e.full_name,
             'orders', coalesce(s.orders, 0), 'grand', coalesce(s.grand, 0),
             'average', case when coalesce(s.orders, 0) = 0 then 0 else round(s.grand::numeric / s.orders) end,
             'discounts', coalesce(s.discounts, 0),
             'void_count', coalesce(v.n, 0), 'voids', coalesce(v.amount, 0),
             'refund_count', coalesce(r.n, 0), 'refunds', coalesce(r.amount, 0))
           order by coalesce(s.grand, 0) desc, e.full_name)
    from public.employees e
    left join (
      select o.cashier_id as id, count(*) as orders, sum(o.grand_total) as grand,
             sum(o.item_discount_total + o.bill_discount_total) as discounts
      from public.orders o
      where o.store_id = any (v_stores) and o.status = 'completed' and o.business_date between p_from and p_to
      group by o.cashier_id
    ) s on s.id = e.id
    left join (
      select o.voided_by as id, count(*) as n, sum(o.grand_total) as amount
      from public.orders o
      where o.store_id = any (v_stores) and o.status = 'voided' and o.business_date between p_from and p_to
      group by o.voided_by
    ) v on v.id = e.id
    left join (
      select rf.employee_id as id, count(*) as n, sum(rf.amount) as amount
      from public.refunds rf
      where rf.store_id = any (v_stores) and rf.business_date between p_from and p_to
      group by rf.employee_id
    ) r on r.id = e.id
    where s.id is not null or v.id is not null or r.id is not null), '[]'::jsonb);
end;
$$;

-- ---------------------------------------------------------------------------
-- report_tax: by day, the taxable base (taxable lines + taxable service),
-- the tax (PPN), DPP (base without tax) and exempt sales.
-- ---------------------------------------------------------------------------
create or replace function public.report_tax(p_store_id uuid, p_from date, p_to date)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_stores uuid[] := app.report_stores(p_store_id);
begin
  perform app.report_period(p_from, p_to);
  return (
    with per_order as (
      select o.business_date, o.tax_total, o.tax_inclusive,
             coalesce((select sum(oi.net_amount) from public.order_items oi
                       where oi.order_id = o.id and oi.is_taxable), 0)
               + case when o.service_charge_taxable then o.service_charge_total else 0 end as base,
             coalesce((select sum(oi.net_amount) from public.order_items oi
                       where oi.order_id = o.id and not oi.is_taxable), 0) as exempt
      from public.orders o
      where o.store_id = any (v_stores) and o.status = 'completed' and o.business_date between p_from and p_to
    ),
    days as (
      select d::date as day,
             coalesce(sum(p.base), 0) as base,
             coalesce(sum(p.tax_total), 0) as tax,
             coalesce(sum(case when p.tax_inclusive then p.base - p.tax_total else p.base end), 0) as dpp,
             coalesce(sum(p.exempt), 0) as exempt
      from generate_series(p_from::timestamp, p_to::timestamp, interval '1 day') d
      left join per_order p on p.business_date = d::date
      group by d
    )
    select jsonb_build_object(
      'by_day', jsonb_agg(jsonb_build_object('date', day, 'base', base, 'dpp', dpp, 'tax', tax, 'exempt', exempt)
                          order by day),
      'totals', jsonb_build_object('base', sum(base), 'dpp', sum(dpp), 'tax', sum(tax), 'exempt', sum(exempt)))
    from days
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- report_stock_value(store): on-hand stock at current cost, per store and
-- variant (stock-tracked products only).
-- ---------------------------------------------------------------------------
create or replace function public.report_stock_value(p_store_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_stores uuid[] := app.report_stores(p_store_id);
begin
  return (
    with rows as (
      select sl.store_id, st.code as store_code, pv.id as variant_id,
             p.name || coalesce(' ' || nullif(pv.name, 'Default'), '') as name, pv.sku,
             sl.quantity, pv.cost, round(sl.quantity * pv.cost)::bigint as value,
             s.reorder_point
      from public.stock_levels sl
      join public.product_variants pv on pv.id = sl.variant_id
      join public.products p on p.id = pv.product_id
      join public.stores st on st.id = sl.store_id
      left join public.store_variant_settings s on s.store_id = sl.store_id and s.variant_id = sl.variant_id
      where sl.store_id = any (v_stores) and p.track_stock and pv.is_active
    )
    select jsonb_build_object(
      'items', coalesce(jsonb_agg(jsonb_build_object(
                 'store_code', store_code, 'variant_id', variant_id, 'name', name, 'sku', sku,
                 'quantity', quantity, 'cost', cost, 'value', value) order by value desc, name), '[]'::jsonb),
      'totals', jsonb_build_object(
        'quantity', coalesce(sum(quantity), 0),
        'value', coalesce(sum(value) filter (where value > 0), 0),
        'negative_count', count(*) filter (where quantity < 0),
        'low_count', count(*) filter (where reorder_point is not null and quantity <= reorder_point)))
    from rows
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- dashboard_summary(store, today): today against yesterday, the last 7 days,
-- today's top products and payment mix, and what needs attention now.
-- ---------------------------------------------------------------------------
create or replace function public.dashboard_summary(p_store_id uuid, p_today date)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_stores uuid[] := app.report_stores(p_store_id);
  v_today date := coalesce(p_today, (now() at time zone 'Asia/Jakarta')::date);
begin
  return jsonb_build_object(
    'today', public.report_sales(p_store_id, v_today, v_today) -> 'totals',
    'yesterday', public.report_sales(p_store_id, v_today - 1, v_today - 1) -> 'totals',
    'last7', public.report_sales(p_store_id, v_today - 6, v_today) -> 'by_day',
    'top_products', coalesce((
      select jsonb_agg(v) from (
        select v from jsonb_array_elements(public.report_products(p_store_id, v_today, v_today, 5) -> 'variants') v
      ) x), '[]'::jsonb),
    'payments', public.report_payments(p_store_id, v_today, v_today) -> 'methods',
    'open_shifts', (select count(*) from public.shifts s where s.store_id = any (v_stores) and s.status = 'open'),
    'low_stock', (select count(*) from public.alerts a
                  where a.store_id = any (v_stores) and a.alert_type = 'LOW_STOCK' and a.status <> 'resolved'),
    'open_alerts', (select count(*) from public.alerts a
                    where a.store_id = any (v_stores) and a.alert_type <> 'LOW_STOCK' and a.status <> 'resolved'),
    'overdue_kasbon', (select coalesce(sum(r.amount - r.paid_amount), 0) from public.receivables r
                       where r.store_id = any (v_stores) and r.status in ('open', 'partial') and r.due_date < v_today)
  );
end;
$$;

revoke execute on function public.report_sales(uuid, date, date), public.report_payments(uuid, date, date),
  public.report_products(uuid, date, date, integer), public.report_staff(uuid, date, date),
  public.report_tax(uuid, date, date), public.report_stock_value(uuid), public.dashboard_summary(uuid, date)
  from public, anon;
grant execute on function public.report_sales(uuid, date, date), public.report_payments(uuid, date, date),
  public.report_products(uuid, date, date, integer), public.report_staff(uuid, date, date),
  public.report_tax(uuid, date, date), public.report_stock_value(uuid), public.dashboard_summary(uuid, date)
  to authenticated, service_role;
