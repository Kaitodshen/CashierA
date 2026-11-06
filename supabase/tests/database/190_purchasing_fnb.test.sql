-- Phase 8 end to end: a purchase order received in two parts, a transfer
-- with a shortfall, and the kitchen queue of a dine-in order.
begin;
create extension if not exists pgtap with schema extensions;
select plan(26);

create temporary table t_v (name text primary key, value jsonb);
grant select, insert, update on t_v to authenticated;

-- Before: Mie Goreng at PST.
select tests.act_as_postgres();
insert into t_v values
  ('stock', to_jsonb((select quantity from public.stock_levels
                      where store_id = tests.id('store.pst') and variant_id = tests.variant('MIE-GRG-ORI')))),
  ('cost', to_jsonb((select cost from public.product_variants where id = tests.variant('MIE-GRG-ORI')))),
  ('stock_all', to_jsonb((select sum(quantity) from public.stock_levels where variant_id = tests.variant('MIE-GRG-ORI')))),
  ('supplier', to_jsonb((select id from public.suppliers where name = 'PT Sumber Pangan Demo')));

create or replace function pg_temp.po(p_mie text)
returns jsonb language sql as $$
  select jsonb_build_object('id', tests.uuid('190:po'), 'store_id', tests.id('store.pst'),
    'supplier_id', (select value ->> 0 from t_v where name = 'supplier')::uuid,
    'expected_date', '2026-11-10', 'note', 'Kirim pagi',
    'items', jsonb_build_array(
      jsonb_build_object('variant_id', tests.variant('MIE-GRG-ORI'), 'quantity_ordered', p_mie, 'unit_cost', 2500),
      jsonb_build_object('variant_id', tests.variant('SMB-GLA-1KG'), 'quantity_ordered', '10', 'unit_cost', 16000)))
$$;
update t_v set value = jsonb_build_array(value #>> '{}') where name = 'supplier';

-- Purchase order ---------------------------------------------------------------------------------
select tests.act_as(tests.id('user.cashier_pst'));
select throws_ok($$ select public.save_purchase_order(pg_temp.po('100')) $$, 'P0001', null,
  'a cashier cannot create purchase orders');
select tests.act_as(tests.id('user.manager_pst'));
select is((public.save_purchase_order(pg_temp.po('100')) ->> 'total_amount')::bigint, 410000::bigint,
  'a draft: 100 x 2.500 + 10 x 16.000');
select is((public.save_purchase_order(pg_temp.po('120')) ->> 'total_amount')::bigint, 460000::bigint,
  'saving again replaces the lines (120 Mie)');
select is(public.set_purchase_order_status(tests.uuid('190:po'), 'ordered') ->> 'status', 'ordered',
  'the order is sent');

create temporary table t_items as
select i.id, i.variant_id from public.purchase_order_items i where i.purchase_order_id = tests.uuid('190:po');
grant select on t_items to authenticated;
create or replace function pg_temp.receive(p_mie numeric, p_gula numeric)
returns jsonb language sql as $$
  select public.receive_purchase_order(jsonb_build_object('purchase_order_id', tests.uuid('190:po'), 'note', 'Dus penyok 1',
    'items', jsonb_build_array(
      jsonb_build_object('purchase_order_item_id', (select id from t_items where variant_id = tests.variant('MIE-GRG-ORI')),
                         'quantity', p_mie),
      jsonb_build_object('purchase_order_item_id', (select id from t_items where variant_id = tests.variant('SMB-GLA-1KG')),
                         'quantity', p_gula))))
$$;
select is(pg_temp.receive(50, 0) ->> 'status', 'partially_received', 'the first 50 Mie arrive');
select throws_ok($$ select pg_temp.receive(0, 0) $$, 'P0001', null, 'a receipt with nothing in it is refused');
select throws_ok($$ select pg_temp.receive(71, 0) $$, 'P0001', null, 'more than the 70 still open is refused');
select throws_ok($$ select public.save_purchase_order(pg_temp.po('130')) $$, 'P0001', null,
  'lines are locked once goods arrived');
select throws_ok($$ select public.set_purchase_order_status('$$ || tests.uuid('190:po') || $$'::uuid, 'cancelled') $$,
  'P0001', null, 'and it can no longer be cancelled');
select is(pg_temp.receive(70, 10) ->> 'status', 'received', 'the rest arrives: fully received');

select tests.act_as_postgres();
select is((select quantity from public.stock_levels where store_id = tests.id('store.pst') and variant_id = tests.variant('MIE-GRG-ORI')),
          (select (value #>> '{}')::numeric + 120 from t_v where name = 'stock'), 'PST has 120 more Mie');
-- Weighted average across all stores, delivery by delivery: n units at cost c, then +50 at 2.500, then +70 at 2.500.
select is((select cost from public.product_variants where id = tests.variant('MIE-GRG-ORI')),
  (select round(((x.n + 50) * round((x.n * x.c + 50 * 2500) / (x.n + 50)) + 70 * 2500) / (x.n + 120))::bigint
   from (select (select (value #>> '{}')::numeric from t_v where name = 'stock_all') as n,
                (select (value #>> '{}')::numeric from t_v where name = 'cost') as c) x),
  'the cost is averaged over both deliveries');

select tests.act_as(tests.id('user.manager_pst'));
select is((select jsonb_build_array(d ->> 'status', jsonb_array_length(d -> 'receipts'), d -> 'items' -> 1 ->> 'name',
                                    (d -> 'items' -> 1 ->> 'quantity_received')::numeric)
           from (select public.purchase_order_detail(tests.uuid('190:po')) as d) x),
  '["received", 2, "Mie Goreng Instan Original", 120]'::jsonb, 'the detail shows both receipts and the lines');
select is((select received_ratio from public.purchase_order_list(tests.id('store.pst'), 'received')
           where purchase_order_id = tests.uuid('190:po')), 1.000::numeric, 'the list shows it 100% received');
select tests.act_as_postgres();
select ok(exists (select 1 from public.audit_log where action = 'purchase.received' and entity_id = tests.uuid('190:po')),
  'receiving is audited');

-- Transfer with a shortfall ------------------------------------------------------------------------
select tests.act_as(tests.id('user.manager_pst'));
insert into t_v values ('transfer', to_jsonb((
  public.request_stock_transfer(tests.id('store.bks'), tests.id('store.pst'),
    jsonb_build_array(jsonb_build_object('variant_id', tests.variant('MIE-GRG-ORI'), 'quantity', 10)), 'Stok habis')
  ->> 'transfer_id')));
select is((select count(*)::int from public.transfer_list(tests.id('store.pst'), 'in', 'requested')
           where transfer_id = (select (value #>> '{}')::uuid from t_v where name = 'transfer')), 1,
  'Pusat sees its incoming request');
select is((select count(*)::int from public.transfer_list(tests.id('store.pst'), 'out')
           where transfer_id = (select (value #>> '{}')::uuid from t_v where name = 'transfer')), 0,
  '... and not as outgoing');
select tests.act_as(tests.id('user.manager_bks'));
select is(public.transition_stock_transfer((select (value #>> '{}')::uuid from t_v where name = 'transfer'), 'approved') ->> 'status',
  'approved', 'Bekasi approves');
select is(public.transition_stock_transfer((select (value #>> '{}')::uuid from t_v where name = 'transfer'), 'in_transit',
  jsonb_build_array(jsonb_build_object('variant_id', tests.variant('MIE-GRG-ORI'), 'quantity', 10))) ->> 'status',
  'in_transit', 'and ships 10');
select tests.act_as(tests.id('user.manager_pst'));
select is(public.transition_stock_transfer((select (value #>> '{}')::uuid from t_v where name = 'transfer'), 'received',
  jsonb_build_array(jsonb_build_object('variant_id', tests.variant('MIE-GRG-ORI'), 'quantity', 9))) ->> 'status',
  'received', 'Pusat receives 9');
select is((select jsonb_build_array(d ->> 'status', (d -> 'items' -> 0 ->> 'quantity_shipped')::numeric,
                                    (d -> 'items' -> 0 ->> 'quantity_received')::numeric,
                                    d -> 'events' -> 'approved' ->> 'by', d -> 'events' -> 'received' ->> 'by')
           from (select public.transfer_detail((select (value #>> '{}')::uuid from t_v where name = 'transfer')) as d) x),
  '["received", 10, 9, "Citra Lestari", "Budi Santoso"]'::jsonb, 'the detail shows who did what and the shortfall');

-- Kitchen queue --------------------------------------------------------------------------------------
select tests.act_as_postgres();
update public.stores set fnb_mode = true where id = tests.id('store.tgr');
insert into public.dining_tables (id, store_id, name, area, capacity)
values (tests.uuid('190:table'), tests.id('store.tgr'), 'Meja 7', 'Dalam', 4);
select tests.act_as(tests.id('user.device_tgr'));
select tests.open_shift('190:shift', tests.id('store.tgr'), tests.id('emp.indra'), 0);
select is(public.sync_push(gen_random_uuid(), 'order', 'upsert',
  jsonb_set(jsonb_set(
    tests.order_payload(tests.uuid('190:order'), tests.id('store.tgr'), tests.uuid('190:shift'), tests.id('emp.indra'),
      'TGR-T1-261107-0001', '[{"sku":"MIE-GRG-ORI","qty":"2"},{"sku":"MNM-TEH-350","qty":"1"}]'::jsonb, 'open', 1,
      '{"order_type":"dine_in","guest_count":2}'::jsonb) || jsonb_build_object('table_id', tests.uuid('190:table')),
    '{items,0,kitchen_station}', '"kitchen"'), '{items,1,kitchen_station}', '"bar"')) ->> 'status',
  'applied', 'a dine-in bill at Meja 7 with food and a drink');
select is((select jsonb_build_array(jsonb_array_length(q), q -> 0 ->> 'table_name',
                                    jsonb_array_length(q -> 0 -> 'items'), q -> 0 -> 'items' -> 0 ->> 'name')
           from (select public.kitchen_queue('bar') as q) x),
  '[1, "Meja 7", 1, "Teh Melati Botol 350 ml"]'::jsonb, 'the bar sees one ticket with only the drink');
select is(jsonb_array_length(public.kitchen_queue(null)), 2, 'kitchen and bar: two tickets');
select is(public.sync_push(gen_random_uuid(), 'kitchen', 'status',
  jsonb_build_object('order_id', tests.uuid('190:order'), 'station', 'kitchen', 'status', 'served',
                     'employee_id', tests.id('emp.dewi'))) ->> 'status', 'applied', 'the kitchen serves the food');
select is((select jsonb_agg(t ->> 'station') from jsonb_array_elements(public.kitchen_queue(null)) t), '["bar"]'::jsonb,
  'a served ticket leaves the queue');

select * from finish();
rollback;
