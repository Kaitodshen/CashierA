-- Phase 4 cashier: a sale priced by the Dart engine (cashiera_core
-- test/pricing/server_fixture_test.dart builds the same numbers) is accepted,
-- held and then completed as one order; split card + cash; the exempt-basket
-- tax rule; save_promotion.
begin;
create extension if not exists pgtap with schema extensions;
select plan(12);

-- The fixture (PST, PPN 11% included):
--   3 x Mie Goreng Original @ 3.500 = 10.500, B2G1 promo -3.500 -> 7.000
--   1 x Beras Premium 5 kg  @ 78.000, PPN-exempt
--   manual bill discount Rp 5.000 spread 412 / 4.588 -> nets 6.588 / 73.412
--   PPN = round(6.588 x 1100 / 11100) = 653 on the mie line
--   grand 80.000 = debit 50.000 + cash 30.000 (tendered 50.000, change 20.000)
create or replace function pg_temp.sale(p_status text, p_version integer, p_paid boolean)
returns jsonb language sql as $$
  select jsonb_build_object(
    'id', tests.uuid('130:order'), 'store_id', tests.id('store.pst'), 'shift_id', tests.uuid('130:shift'),
    'cashier_id', tests.id('emp.eko'), 'order_number', 'PST-T1-261106-0001', 'order_type', 'takeaway',
    'status', p_status, 'version', p_version, 'ordered_at', now(),
    'completed_at', case when p_status = 'completed' then now() end,
    'gross_total', 88500, 'item_discount_total', 3500, 'bill_discount_total', 5000,
    'points_redeemed', 0, 'points_discount', 0, 'net_total', 80000, 'service_charge_total', 0,
    'tax_total', 653, 'tax_inclusive', true, 'tax_rate_bps', 1100, 'service_charge_bps', 0,
    'service_charge_taxable', true, 'rounding_amount', 0, 'grand_total', 80000,
    'paid_total', case when p_paid then 80000 else 0 end,
    'change_total', case when p_paid then 20000 else 0 end, 'points_earned', 0,
    'items', jsonb_build_array(
      jsonb_build_object('id', tests.uuid('130:line:mie'), 'product_id', tests.product('mie-goreng'),
        'variant_id', tests.variant('MIE-GRG-ORI'), 'product_name', 'Mie Goreng Instan', 'variant_name', 'Original',
        'sku', 'MIE-GRG-ORI', 'quantity', '3.000', 'unit_price', 3500, 'modifiers_unit_total', 0,
        'gross_amount', 10500, 'item_discount_amount', 3500, 'bill_discount_amount', 412, 'net_amount', 6588,
        'tax_amount', 653, 'is_taxable', true, 'unit_cost', 2700, 'cost_amount', 8100, 'sort_order', 0),
      jsonb_build_object('id', tests.uuid('130:line:beras'), 'product_id', tests.product('beras-premium'),
        'variant_id', tests.variant('SMB-BRS-5KG'), 'product_name', 'Beras Premium 5 kg', 'variant_name', 'Default',
        'sku', 'SMB-BRS-5KG', 'quantity', '1.000', 'unit_price', 78000, 'modifiers_unit_total', 0,
        'gross_amount', 78000, 'item_discount_amount', 0, 'bill_discount_amount', 4588, 'net_amount', 73412,
        'tax_amount', 0, 'is_taxable', false, 'unit_cost', 70000, 'cost_amount', 70000, 'sort_order', 1)),
    'discounts', jsonb_build_array(
      jsonb_build_object('id', tests.uuid('130:disc:promo'), 'order_item_id', tests.uuid('130:line:mie'),
        'source', 'promotion', 'promotion_id', md5('cashiera:promo:b2g1-mie')::uuid,
        'description', 'Beli 2 Gratis 1 Mie Goreng', 'amount', 3500, 'discount_bps', 10000),
      jsonb_build_object('id', tests.uuid('130:disc:manual'), 'order_item_id', null, 'source', 'manual',
        'description', 'Diskon tagihan', 'amount', 5000, 'discount_bps', null)),
    'payments', case when p_paid then jsonb_build_array(
      jsonb_build_object('id', tests.uuid('130:pay:debit'),
        'payment_method_id', (select id from public.payment_methods where code = 'debit_card'),
        'method_type', 'card', 'amount', 50000, 'tendered_amount', null, 'change_amount', 0,
        'reference', 'APR-1188', 'status', 'paid', 'paid_at', now()),
      jsonb_build_object('id', tests.uuid('130:pay:cash'),
        'payment_method_id', (select id from public.payment_methods where code = 'cash'),
        'method_type', 'cash', 'amount', 30000, 'tendered_amount', 50000, 'change_amount', 20000,
        'reference', null, 'status', 'paid', 'paid_at', now()))
      else '[]'::jsonb end)
$$;

create temporary table t_payload (name text primary key, payload jsonb not null);
grant select on t_payload to authenticated;
insert into t_payload values
  ('held', pg_temp.sale('held', 1, false)),
  ('done', pg_temp.sale('completed', 2, true));

select tests.act_as(tests.id('user.device_pst'));
select tests.open_shift('130:shift', tests.id('store.pst'), tests.id('emp.eko'), 200000);

select is(public.sync_push(tests.uuid('130:push:held'), 'order', 'upsert', (select payload from t_payload where name = 'held'))
            -> 'result' ->> 'status',
  'held', 'the bill is held first (version 1, no payments)');
select is(public.sync_push(tests.uuid('130:push:done'), 'order', 'upsert', (select payload from t_payload where name = 'done'))
            ->> 'status',
  'applied', 'the same bill is completed with the engine''s numbers (version 2)');

select tests.act_as_postgres();
select is(
  (select count(*)::int from public.orders where order_number = 'PST-T1-261106-0001'), 1,
  'holding and finishing is one order, not two');
select is(
  (select array[grand_total, tax_total, paid_total, change_total] from public.orders where id = tests.uuid('130:order')),
  array[80000, 653, 80000, 20000]::bigint[], 'totals are stored as sent');
select is(
  (select status from public.orders where id = tests.uuid('130:order')), 'completed', 'the order is completed');
select is(
  (select array_agg(amount order by amount) from public.payments where order_id = tests.uuid('130:order')),
  array[30000, 50000]::bigint[], 'split payment: cash 30.000 (change 20.000) and debit 50.000');
select is(
  (select sum(net_amount)::bigint from public.order_items where order_id = tests.uuid('130:order')), 80000::bigint,
  'line nets add up to the bill');

-- A taxable service charge on an exempt basket: the header carries the tax --------------
update public.store_settings
   set tax_inclusive = false, service_charge_enabled = true, service_charge_bps = 1000
 where store_id = tests.id('store.bks');
create or replace function pg_temp.exempt(p_line_tax bigint)
returns jsonb language sql as $$
  select jsonb_build_object(
    'id', tests.uuid('130:exempt:' || p_line_tax), 'store_id', tests.id('store.bks'),
    'shift_id', tests.uuid('130:shift:bks'), 'cashier_id', tests.id('emp.gilang'),
    'order_number', 'BKS-T1-261106-' || lpad(p_line_tax::text, 4, '0'), 'status', 'completed', 'version', 1,
    'ordered_at', now(), 'completed_at', now(),
    'gross_total', 78000, 'item_discount_total', 0, 'bill_discount_total', 0, 'net_total', 78000,
    'service_charge_total', 7800, 'tax_total', 858, 'tax_inclusive', false, 'tax_rate_bps', 1100,
    'service_charge_bps', 1000, 'service_charge_taxable', true, 'rounding_amount', 0,
    'grand_total', 86658, 'paid_total', 86658, 'change_total', 0,
    'items', jsonb_build_array(jsonb_build_object('id', tests.uuid('130:exempt:line:' || p_line_tax),
      'product_id', tests.product('beras-premium'), 'variant_id', tests.variant('SMB-BRS-5KG'),
      'product_name', 'Beras Premium 5 kg', 'sku', 'SMB-BRS-5KG', 'quantity', '1.000', 'unit_price', 78000,
      'gross_amount', 78000, 'net_amount', 78000, 'tax_amount', p_line_tax, 'is_taxable', false)),
    'discounts', '[]'::jsonb,
    'payments', jsonb_build_array(jsonb_build_object('id', tests.uuid('130:exempt:pay:' || p_line_tax),
      'payment_method_id', (select id from public.payment_methods where code = 'qris'),
      'method_type', 'qris', 'amount', 86658, 'status', 'paid')))
$$;
insert into t_payload values ('exempt', pg_temp.exempt(0));

select tests.act_as(tests.id('user.device_bks'));
select tests.open_shift('130:shift:bks', tests.id('store.bks'), tests.id('emp.gilang'), 0);
select is(public.sync_push(tests.uuid('130:push:exempt'), 'order', 'upsert', (select payload from t_payload where name = 'exempt'))
            ->> 'status',
  'applied', 'exempt basket + taxable service: tax 858 on the header, none on the line');

-- save_promotion ------------------------------------------------------------------------------
create or replace function pg_temp.promo(p_stores jsonb)
returns jsonb language sql as $$
  select jsonb_build_object(
    'id', tests.uuid('130:promo'), 'name', 'Diskon Sabun', 'promo_type', 'happy_hour',
    'rules', jsonb_build_object('scope', jsonb_build_object('all', true),
                                'discount', jsonb_build_object('type', 'percent', 'bps', 500)),
    'priority', 40, 'is_stackable', true, 'days_of_week', jsonb_build_array(6, 7),
    'start_time', '10:00', 'end_time', '12:00', 'store_ids', p_stores)
$$;

select tests.act_as(tests.id('user.owner'));
select is(public.save_promotion(pg_temp.promo(jsonb_build_array(tests.id('store.pst'), tests.id('store.bks'))))
            ->> 'store_count',
  '2', 'save_promotion creates a promotion for two stores');
select public.save_promotion(pg_temp.promo(jsonb_build_array(tests.id('store.tgr'))));
select tests.act_as_postgres();
select is(
  (select array_agg(store_id) from public.promotion_stores where promotion_id = tests.uuid('130:promo')),
  array[tests.id('store.tgr')], 'saving again replaces the store list');

select tests.act_as(tests.id('user.owner'));
select throws_like(
  $$select public.save_promotion(pg_temp.promo('[]'::jsonb) || '{"rules":{"scope":{"all":true}}}'::jsonb)$$,
  'promotion_rules_invalid%', 'rules that do not fit the type are refused');

select tests.act_as(tests.id('user.cashier_pst'));
select throws_like(
  $$select public.save_promotion(pg_temp.promo('[]'::jsonb))$$,
  'permission_denied%', 'a cashier cannot edit promotions');

select * from finish();
rollback;
