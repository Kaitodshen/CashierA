-- Transfers (requested -> approved -> in_transit -> received), purchase order
-- receiving with weighted-average cost, stock opname, adjustment sign rules,
-- recipe (BOM) deduction.
begin;
create extension if not exists pgtap with schema extensions;
select plan(22);

create temporary table t_stock as
select store_id, variant_id, quantity from public.stock_levels;

create temporary table t_ids (name text primary key, id uuid not null);
grant select, insert on t_ids to authenticated;

-- Transfer: PST asks Bekasi for 10 x Air Mineral 1500 ml ------------------------------------------
select tests.act_as(tests.id('user.device_pst'));
select is(
  public.request_stock_transfer(tests.id('store.bks'), tests.id('store.pst'),
    jsonb_build_array(jsonb_build_object('variant_id', tests.variant('MNM-AIR-1500'), 'quantity', '10')),
    'Stok menipis', tests.id('emp.kurniawan')) ->> 'status',
  'requested', 'the inventory clerk requests stock from Bekasi');
select tests.act_as_postgres();
insert into t_ids select 'transfer', id from public.stock_transfers where to_store_id = tests.id('store.pst') order by created_at desc limit 1;

select tests.act_as(tests.id('user.device_pst'));
select throws_like(
  $$select public.transition_stock_transfer((select id from t_ids where name = 'transfer'), 'approved', null, null, tests.id('emp.budi'))$$,
  'store_mismatch%', 'the requesting store cannot approve its own request');

select tests.act_as(tests.id('user.device_bks'));
select is(
  public.transition_stock_transfer((select id from t_ids where name = 'transfer'), 'approved', null, null, tests.id('emp.citra')) ->> 'status',
  'approved', 'the Bekasi manager approves');
select is(
  public.transition_stock_transfer((select id from t_ids where name = 'transfer'), 'in_transit', null, null, tests.id('emp.citra')) ->> 'status',
  'in_transit', 'Bekasi ships the goods');
select tests.act_as_postgres();
select is(
  (select quantity from public.stock_levels where store_id = tests.id('store.bks') and variant_id = tests.variant('MNM-AIR-1500')),
  (select quantity - 10 from t_stock where store_id = tests.id('store.bks') and variant_id = tests.variant('MNM-AIR-1500')),
  'stock leaves Bekasi when shipped');

select tests.act_as(tests.id('user.device_pst'));
select is(
  public.transition_stock_transfer((select id from t_ids where name = 'transfer'), 'received',
    jsonb_build_array(jsonb_build_object('variant_id', tests.variant('MNM-AIR-1500'), 'quantity', '9')),
    null, tests.id('emp.kurniawan')) ->> 'status',
  'received', 'PST receives 9 of the 10');
select tests.act_as_postgres();
select is(
  (select quantity from public.stock_levels where store_id = tests.id('store.pst') and variant_id = tests.variant('MNM-AIR-1500')),
  (select quantity + 9 from t_stock where store_id = tests.id('store.pst') and variant_id = tests.variant('MNM-AIR-1500')),
  'stock enters PST when received');
select is(
  (select count(*)::int from public.alerts
   where alert_type = 'TRANSFER_DISCREPANCY' and reference_id = (select id from t_ids where name = 'transfer')),
  1, 'the missing unit raises TRANSFER_DISCREPANCY');
select tests.act_as(tests.id('user.device_bks'));
select throws_like(
  $$select public.transition_stock_transfer((select id from t_ids where name = 'transfer'), 'approved', null, null, tests.id('emp.citra'))$$,
  'transfer_invalid_transition%', 'a received transfer cannot go back');

-- Purchase order and goods receipt (manager in the back office) ------------------------------------
select tests.act_as_postgres();
create temporary table t_cost as
select (select cost from public.product_variants where id = tests.variant('KBR-PWG-900')) as cost,
       (select sum(greatest(quantity, 0)) from public.stock_levels where variant_id = tests.variant('KBR-PWG-900')) as on_hand;

select tests.act_as(tests.id('user.manager_pst'));
select lives_ok($$
  insert into public.purchase_orders (id, store_id, supplier_id, status, created_by)
  values (tests.uuid('070:po'), tests.id('store.pst'),
          (select id from public.suppliers where name = 'PT Sumber Pangan Demo'), 'ordered', tests.id('emp.budi'));
  insert into public.purchase_order_items (id, purchase_order_id, variant_id, quantity_ordered, unit_cost)
  values (tests.uuid('070:po:1'), tests.uuid('070:po'), tests.variant('KBR-PWG-900'), 20, 15000);
$$, 'the manager creates a purchase order');
select lives_ok($$
  insert into public.goods_receipts (id, store_id, purchase_order_id, supplier_id, receipt_number, received_by)
  values (tests.uuid('070:gr'), tests.id('store.pst'), tests.uuid('070:po'),
          (select id from public.suppliers where name = 'PT Sumber Pangan Demo'), 'GR-PST-261105-01', tests.id('emp.budi'));
  insert into public.goods_receipt_items (goods_receipt_id, store_id, variant_id, purchase_order_item_id, quantity, unit_cost)
  values (tests.uuid('070:gr'), tests.id('store.pst'), tests.variant('KBR-PWG-900'), tests.uuid('070:po:1'), 20, 15000);
$$, 'and receives the goods against it');
select tests.act_as_postgres();
select is(
  (select quantity from public.stock_levels where store_id = tests.id('store.pst') and variant_id = tests.variant('KBR-PWG-900')),
  (select quantity + 20 from t_stock where store_id = tests.id('store.pst') and variant_id = tests.variant('KBR-PWG-900')),
  'received goods are added to stock');
select is(
  (select status from public.purchase_orders where id = tests.uuid('070:po')),
  'received', 'the purchase order is fully received');
select is(
  (select cost from public.product_variants where id = tests.variant('KBR-PWG-900')),
  (select round((on_hand * cost + 20 * 15000) / (on_hand + 20))::bigint from t_cost),
  'cost becomes the weighted average of old stock and the new delivery');

-- Stock opname on the terminal ------------------------------------------------------------------------
select tests.act_as(tests.id('user.device_pst'));
select is(
  public.sync_push(tests.uuid('070:push:opname'), 'stock_opname', 'submit',
    jsonb_build_object('id', tests.uuid('070:opname'), 'store_id', tests.id('store.pst'), 'opname_number', 'OP-PST-261105-01',
                       'employee_id', tests.id('emp.kurniawan'),
                       'items', jsonb_build_array(jsonb_build_object('variant_id', tests.variant('MNM-ISO-500'), 'counted_qty', '5'))))
    -> 'result' ->> 'adjusted',
  '1', 'the count differs from the system, so one line is adjusted');
select tests.act_as_postgres();
select is(
  (select quantity from public.stock_levels where store_id = tests.id('store.pst') and variant_id = tests.variant('MNM-ISO-500')),
  5.000::numeric, 'stock now equals the counted quantity');
select is(
  (select difference from public.stock_opname_items where opname_id = tests.uuid('070:opname')),
  (select 5 - quantity from t_stock where store_id = tests.id('store.pst') and variant_id = tests.variant('MNM-ISO-500')),
  'the opname records the difference (selisih stok)');

select tests.act_as(tests.id('user.device_pst'));
select is(
  public.sync_push(tests.uuid('070:push:bad-adj'), 'stock_adjustment', 'create',
    jsonb_build_object('id', tests.uuid('070:adj'), 'store_id', tests.id('store.pst'), 'adjustment_number', 'ADJ-261105-0070',
                       'reason', 'stock_out', 'employee_id', tests.id('emp.kurniawan'),
                       'items', jsonb_build_array(jsonb_build_object('id', tests.uuid('070:adj:1'),
                                                                     'variant_id', tests.variant('MNM-ISO-500'), 'quantity_delta', '5')))) ->> 'code',
  'adjustment_sign', 'stock out with a positive quantity is refused');

-- Recipe (BOM): selling Es Kopi Susu consumes 18 g of beans, not the drink itself ----------------------
select tests.act_as_postgres();
insert into public.products (id, unit_id, name, product_type) values
  (tests.uuid('070:p:beans'), (select id from public.units where code = 'g'), 'Biji Kopi (uji)', 'ingredient'),
  (tests.uuid('070:p:drink'), (select id from public.units where code = 'pcs'), 'Es Kopi Susu (uji)', 'standard');
insert into public.product_variants (id, product_id, sku, price, cost) values
  (tests.uuid('070:v:beans'), tests.uuid('070:p:beans'), 'TST-BEANS-G', 0, 300),
  (tests.uuid('070:v:drink'), tests.uuid('070:p:drink'), 'TST-ESKOPI', 18000, 6000);
insert into public.recipe_items (variant_id, ingredient_variant_id, quantity)
values (tests.uuid('070:v:drink'), tests.uuid('070:v:beans'), 18);
select app.apply_stock_delta(tests.id('store.pst'), tests.uuid('070:v:beans'), 1000, 'initial', null, null, tests.id('emp.budi'));

create temporary table t_payload (payload jsonb not null);
grant select on t_payload to authenticated;
insert into t_payload values (tests.order_payload(tests.uuid('070:order'), tests.id('store.pst'), tests.uuid('070:shift'),
  tests.id('emp.eko'), 'PST-T1-261105-0501', '[{"sku":"TST-ESKOPI","qty":"2"}]'::jsonb));

select tests.act_as(tests.id('user.device_pst'));
select tests.open_shift('070:shift', tests.id('store.pst'), tests.id('emp.eko'), 0);
select is(public.sync_push(tests.uuid('070:push:order'), 'order', 'upsert', (select payload from t_payload)) ->> 'status',
  'applied', 'two iced coffees are sold');
select tests.act_as_postgres();
select is(
  (select quantity from public.stock_levels where store_id = tests.id('store.pst') and variant_id = tests.uuid('070:v:beans')),
  964.000::numeric, 'the recipe consumed 2 x 18 g of beans');
select is(
  (select count(*)::int from public.stock_movements where variant_id = tests.uuid('070:v:drink')),
  0, 'the drink itself has no stock movement');
select throws_like(
  $$insert into public.recipe_items (variant_id, ingredient_variant_id, quantity)
    values (tests.uuid('070:v:beans'), tests.variant('MNM-AIR-600'), 1)$$,
  'recipe_nested%', 'recipes are one level deep');

select * from finish();
rollback;
