-- Phase 7 reports reconcile with each other and with a known scenario.
--
-- PST (WIB), 1-4 October 2026:
--   A  1 Oct 10:00  4 x Mie Goreng   Rp 14.000  cash
--   B  1 Oct 12:00  2 x Gula (exempt) Rp 37.000  debit
--   C  2 Oct 23:30  1 x Jus Jeruk    Rp 21.000  cash 10.000 + kasbon 11.000 (Toko Berkah Jaya)
--   D  2 Oct 11:00  2 x Mie Goreng   Rp  7.000  cash, then voided
--   3 Oct: nothing
--   4 Oct: refund of 1 Mie from A, Rp 3.500 cash
-- TGR, moved to WITA for this test:
--   E  2 Oct 00:30 WITA (1 Oct 23:30 WIB)  1 x Mie Goreng  Rp 3.500 cash
begin;
create extension if not exists pgtap with schema extensions;
select plan(30);

create or replace function pg_temp.sale(p_seed text, p_store uuid, p_shift text, p_cashier uuid, p_number text,
                                        p_sku text, p_qty text, p_at timestamptz, p_options jsonb)
returns jsonb language sql as $$
  select public.sync_push(gen_random_uuid(), 'order', 'upsert',
    tests.order_payload(tests.uuid('180:order:' || p_seed), p_store, tests.uuid(p_shift), p_cashier, p_number,
      jsonb_build_array(jsonb_build_object('sku', p_sku, 'qty', p_qty)), 'completed', 1,
      p_options || jsonb_build_object('ordered_at', p_at)))
$$;

-- PST --------------------------------------------------------------------------------------------
select tests.act_as(tests.id('user.device_pst'));
select tests.open_shift('180:shift:pst', tests.id('store.pst'), tests.id('emp.eko'), 100000);
select is((select count(*)::int from (
  select pg_temp.sale('A', tests.id('store.pst'), '180:shift:pst', tests.id('emp.eko'), 'PST-T1-261001-0001',
           'MIE-GRG-ORI', '4', '2026-10-01 03:00Z', '{"payments":[{"method":"cash"}]}') ->> 'status' as s
  union all
  select pg_temp.sale('B', tests.id('store.pst'), '180:shift:pst', tests.id('emp.eko'), 'PST-T1-261001-0002',
           'SMB-GLA-1KG', '2', '2026-10-01 05:00Z', '{"payments":[{"method":"debit","reference":"APR1"}]}') ->> 'status'
  union all
  select pg_temp.sale('C', tests.id('store.pst'), '180:shift:pst', tests.id('emp.eko'), 'PST-T1-261002-0001',
           'MNM-JUS-1L', '1', '2026-10-02 16:30Z',
           jsonb_build_object('customer_id', tests.customer(4), 'payments',
             '[{"method":"cash","amount":10000},{"method":"kasbon"}]'::jsonb)) ->> 'status'
  union all
  select pg_temp.sale('D', tests.id('store.pst'), '180:shift:pst', tests.id('emp.eko'), 'PST-T1-261002-0002',
           'MIE-GRG-ORI', '2', '2026-10-02 04:00Z', '{"payments":[{"method":"cash"}]}') ->> 'status'
) x where s = 'applied'), 4, 'four PST sales are booked');
select is(public.sync_push(gen_random_uuid(), 'order', 'void',
  jsonb_build_object('order_id', tests.uuid('180:order:D'), 'voided_by', tests.id('emp.eko'),
                     'reason', 'Salah input', 'shift_id', tests.uuid('180:shift:pst'),
                     'voided_at', '2026-10-02 05:00Z')) ->> 'status', 'applied', 'D is voided');
select is(public.sync_push(gen_random_uuid(), 'refund', 'create',
  jsonb_build_object('id', tests.uuid('180:refund'), 'order_id', tests.uuid('180:order:A'),
    'refund_number', 'R-180-1', 'reason', 'Kemasan sobek', 'amount', 3500, 'method_type', 'cash',
    'restock', true, 'employee_id', tests.id('emp.eko'), 'approved_by', tests.id('emp.budi'),
    'shift_id', tests.uuid('180:shift:pst'), 'refunded_at', '2026-10-04 03:00Z',
    'items', jsonb_build_array(jsonb_build_object('id', tests.uuid('180:refund-item'),
      'order_item_id', md5(tests.uuid('180:order:A')::text || ':item:1')::uuid, 'quantity', '1', 'amount', 3500))))
  ->> 'status', 'applied', 'one Mie from A is refunded on 4 October');

-- TGR on WITA -------------------------------------------------------------------------------------
select tests.act_as_postgres();
update public.stores set timezone = 'Asia/Makassar' where id = tests.id('store.tgr');
select tests.act_as(tests.id('user.device_tgr'));
select tests.open_shift('180:shift:tgr', tests.id('store.tgr'), tests.id('emp.dewi'), 50000);
select is(pg_temp.sale('E', tests.id('store.tgr'), '180:shift:tgr', tests.id('emp.dewi'), 'TGR-T1-261002-0001',
           'MIE-GRG-ORI', '1', '2026-10-01 16:30Z', '{"payments":[{"method":"cash"}]}') -> 'result' ->> 'business_date',
  '2026-10-02', '00:30 WITA belongs to 2 October in Tangerang');

-- Owner: every store ---------------------------------------------------------------------------------
select tests.act_as(tests.id('user.owner'));
create temporary table t_r as
select public.report_sales(null, '2026-10-01', '2026-10-04') as sales,
       public.report_payments(null, '2026-10-01', '2026-10-04') as payments,
       public.report_products(null, '2026-10-01', '2026-10-04', 100) as products,
       public.report_staff(null, '2026-10-01', '2026-10-04') as staff,
       public.report_tax(null, '2026-10-01', '2026-10-04') as tax;

select is((select jsonb_build_array(sales -> 'totals' -> 'orders', sales -> 'totals' -> 'grand',
                                    sales -> 'totals' -> 'refunds', sales -> 'totals' -> 'net_sales',
                                    sales -> 'totals' -> 'void_count', sales -> 'totals' -> 'voids') from t_r),
  '[4, 75500, 3500, 72000, 1, 7000]'::jsonb, 'totals: 4 sales of Rp 75.500, Rp 3.500 refunded, one void');
select is((select jsonb_agg(jsonb_build_array(d ->> 'date', (d ->> 'orders')::int, (d ->> 'grand')::bigint,
                                              (d ->> 'refunds')::bigint))
           from t_r, jsonb_array_elements(sales -> 'by_day') d),
  '[["2026-10-01", 2, 51000, 0], ["2026-10-02", 2, 24500, 0], ["2026-10-03", 0, 0, 0], ["2026-10-04", 0, 0, 3500]]'::jsonb,
  'by day, with the empty 3 October and the refund on its own day');
select is((select sum((d ->> 'grand')::bigint) from t_r, jsonb_array_elements(sales -> 'by_day') d),
          (select (sales -> 'totals' ->> 'grand')::bigint from t_r)::numeric, 'Σ by day = total');
select is((select sum((s ->> 'grand')::bigint) from t_r, jsonb_array_elements(sales -> 'by_store') s),
          (select (sales -> 'totals' ->> 'grand')::bigint from t_r)::numeric, 'Σ by store = total');
select is((select jsonb_object_agg(s ->> 'store_code', jsonb_build_array((s ->> 'grand')::bigint, (s ->> 'refunds')::bigint))
           from t_r, jsonb_array_elements(sales -> 'by_store') s),
  '{"BKS": [0, 0], "PST": [72000, 3500], "TGR": [3500, 0]}'::jsonb, 'by store');
select is((select sum((h ->> 'orders')::int) from t_r, jsonb_array_elements(sales -> 'by_hour') h), 4::bigint,
  'Σ by hour = orders');
select is((select jsonb_build_array((sales -> 'by_hour' -> 23 ->> 'orders')::int, (sales -> 'by_hour' -> 0 ->> 'orders')::int)
           from t_r), '[1, 1]'::jsonb, 'hours are store-local: C at 23:00 WIB, E at 00:00 WITA');

select is((select jsonb_agg(jsonb_build_array(m ->> 'name', (m ->> 'count')::int, (m ->> 'amount')::bigint))
           from t_r, jsonb_array_elements(payments -> 'methods') m),
  '[["Tunai", 3, 27500], ["Kartu Debit", 1, 37000], ["Kasbon", 1, 11000]]'::jsonb, 'payments by method');
select is((select sum((m ->> 'amount')::bigint) from t_r, jsonb_array_elements(payments -> 'methods') m),
          (select (sales -> 'totals' ->> 'grand')::bigint from t_r)::numeric, 'Σ payments = total');
select is((select payments -> 'refunds' from t_r), '[{"count": 1, "amount": 3500, "method_type": "cash"}]'::jsonb,
  'refunds by method');
select is((select (payments -> 'kasbon' ->> 'issued')::bigint from t_r), 11000::bigint, 'kasbon issued');

select is((select jsonb_agg(jsonb_build_array(v ->> 'sku', (v ->> 'quantity')::numeric, (v ->> 'refunded_quantity')::numeric,
                                              (v ->> 'net')::bigint, (v ->> 'cost')::bigint))
           from t_r, jsonb_array_elements(products -> 'variants') v),
  '[["SMB-GLA-1KG", 2, 0, 37000, 32400], ["MNM-JUS-1L", 1, 0, 21000, 15500], ["MIE-GRG-ORI", 5, 1, 17500, 13500]]'::jsonb,
  'products: largest net first, with refunded quantity and cost');
select is((select (products -> 'totals' ->> 'net')::bigint from t_r),
          (select (sales -> 'totals' ->> 'net')::bigint from t_r), 'Σ product net = net total');
select is((select sum((c ->> 'net')::bigint) from t_r, jsonb_array_elements(products -> 'categories') c),
          (select (sales -> 'totals' ->> 'net')::bigint from t_r)::numeric, 'Σ category net = net total');
select is((select jsonb_build_array((products -> 'totals' ->> 'margin')::bigint, (products -> 'totals' ->> 'refunded')::bigint)
           from t_r), '[14100, 3500]'::jsonb, 'margin and refunded amount');

select is((select jsonb_agg(jsonb_build_array(s ->> 'name', (s ->> 'orders')::int, (s ->> 'grand')::bigint,
                                              (s ->> 'void_count')::int, (s ->> 'refunds')::bigint))
           from t_r, jsonb_array_elements(staff) s),
  '[["Eko Saputra", 3, 72000, 1, 3500], ["Dewi Anggraini", 1, 3500, 0, 0]]'::jsonb, 'staff');
select is((select sum((s ->> 'grand')::bigint) from t_r, jsonb_array_elements(staff) s),
          (select (sales -> 'totals' ->> 'grand')::bigint from t_r)::numeric, 'Σ staff = total');

select is((select (tax -> 'totals' ->> 'tax')::bigint from t_r),
          (select (sales -> 'totals' ->> 'tax')::bigint from t_r), 'tax report total = tax on sales');
select is((select (tax -> 'totals' ->> 'dpp')::bigint + (tax -> 'totals' ->> 'tax')::bigint from t_r),
          (select (tax -> 'totals' ->> 'base')::bigint from t_r), 'DPP + PPN = taxable base (tax included)');
select is((select jsonb_build_array((tax -> 'totals' ->> 'base')::bigint, (tax -> 'totals' ->> 'exempt')::bigint) from t_r),
  '[38500, 37000]'::jsonb, 'taxable Rp 38.500 (Mie and Jus), exempt Rp 37.000 (Gula)');

select is((select jsonb_build_array(d -> 'today' -> 'grand', d -> 'yesterday' -> 'grand',
                                    jsonb_array_length(d -> 'last7'), d -> 'top_products' -> 0 ->> 'sku')
           from (select public.dashboard_summary(null, '2026-10-02') as d) x),
  '[24500, 51000, 7, "MNM-JUS-1L"]'::jsonb, 'dashboard: today against yesterday, 7 days, the top product');

-- Scope and permissions --------------------------------------------------------------------------------
select tests.act_as(tests.id('user.manager_pst'));
select is((public.report_sales(null, '2026-10-01', '2026-10-04') -> 'totals' ->> 'grand')::bigint, 72000::bigint,
  'a store manager''s "all stores" is their store');
select throws_ok($$ select public.report_sales('a0000000-0000-4000-8000-000000000003'::uuid, '2026-10-01', '2026-10-04') $$,
  'P0001', null, 'another store is refused');
select ok((select (r -> 'totals' ->> 'value')::bigint > 0
             and (r -> 'totals' ->> 'value')::bigint = (select sum((i ->> 'value')::bigint)
                                                        from jsonb_array_elements(r -> 'items') i
                                                        where (i ->> 'value')::bigint > 0)
           from (select public.report_stock_value(null) as r) x),
  'stock value is the sum of its items');
select tests.act_as(tests.id('user.cashier_pst'));
select throws_ok($$ select public.report_sales(null, '2026-10-01', '2026-10-04') $$,
  'P0001', null, 'a cashier has no reports');
select tests.act_as(tests.id('user.owner'));
select throws_ok($$ select public.report_sales(null, '2026-10-04', '2026-10-01') $$,
  'P0001', null, 'a period that ends before it starts is refused');

select * from finish();
rollback;
