-- Offline checkout reaching the server: totals contract, stock deduction on
-- completion, idempotent retries, rejected payloads, cart versions.
begin;
create extension if not exists pgtap with schema extensions;
select plan(25);

create temporary table t_stock as
select variant_id, quantity from public.stock_levels where store_id = tests.id('store.pst');

create temporary table t_payload (name text primary key, payload jsonb not null);
grant select on t_payload to authenticated;

-- Sale A, checked by hand:
--   2 x Air Mineral 600 ml @ Rp 4.000 (PPN included) + 1 x Beras Premium 5 kg @ Rp 78.000 (PPN exempt)
--   gross 86.000 · PPN = round(8.000 x 1100 / 11100) = 793 · grand 86.000
--   cash 100.000 -> change 14.000 · customer earns floor(86.000 / 10.000) = 8 points
insert into t_payload values
  ('a', tests.order_payload(tests.uuid('020:order:a'), tests.id('store.pst'), tests.uuid('020:shift'), tests.id('emp.eko'),
     'PST-T1-261105-0001', '[{"sku":"MNM-AIR-600","qty":"2"},{"sku":"SMB-BRS-5KG","qty":"1"}]'::jsonb, 'completed', 1,
     jsonb_build_object('customer_id', tests.customer(1),
                        'payments', jsonb_build_array(jsonb_build_object('method', 'cash', 'tendered', 100000))))),
  ('bad_tax', jsonb_set(jsonb_set(
     tests.order_payload(tests.uuid('020:order:bad-tax'), tests.id('store.pst'), tests.uuid('020:shift'), tests.id('emp.eko'),
       'PST-T1-261105-0002', '[{"sku":"MNM-AIR-600","qty":"2"}]'::jsonb),
     '{tax_total}', '800'), '{items,0,tax_amount}', '800')),
  ('bad_payment', tests.order_payload(tests.uuid('020:order:bad-pay'), tests.id('store.pst'), tests.uuid('020:shift'), tests.id('emp.eko'),
     'PST-T1-261105-0003', '[{"sku":"MNM-AIR-600","qty":"2"}]'::jsonb, 'completed', 1,
     '{"payments":[{"method":"cash","amount":7000,"tendered":10000}]}'::jsonb)),
  ('cart_v1', tests.order_payload(tests.uuid('020:order:b'), tests.id('store.pst'), tests.uuid('020:shift'), tests.id('emp.eko'),
     'PST-T1-261105-0004', '[{"sku":"MNM-TEH-350","qty":"1"}]'::jsonb, 'open', 1)),
  ('cart_v2', tests.order_payload(tests.uuid('020:order:b'), tests.id('store.pst'), tests.uuid('020:shift'), tests.id('emp.eko'),
     'PST-T1-261105-0004', '[{"sku":"MNM-TEH-350","qty":"3"}]'::jsonb, 'completed', 2)),
  ('cart_v3', tests.order_payload(tests.uuid('020:order:b'), tests.id('store.pst'), tests.uuid('020:shift'), tests.id('emp.eko'),
     'PST-T1-261105-0004', '[{"sku":"MNM-TEH-350","qty":"5"}]'::jsonb, 'completed', 3)),
  ('no_shift', tests.order_payload(tests.uuid('020:order:c'), tests.id('store.pst'), null, tests.id('emp.eko'),
     'PST-T1-261105-0005', '[{"sku":"MNM-TEH-350","qty":"1"}]'::jsonb));

-- Terminal sells -----------------------------------------------------------------------------
select tests.act_as(tests.id('user.device_pst'));
select ok(tests.open_shift('020:shift', tests.id('store.pst'), tests.id('emp.eko'), 500000) is not null,
  'terminal opens a shift');
select is(
  public.sync_push(tests.uuid('020:push:a'), 'order', 'upsert', (select payload from t_payload where name = 'a')) ->> 'status',
  'applied',
  'completed sale is applied');

select tests.act_as_postgres();
select is(
  (select array[gross_total, tax_total, grand_total, paid_total, change_total] from public.orders where id = tests.uuid('020:order:a')),
  array[86000, 793, 86000, 86000, 14000]::bigint[],
  'totals follow the inclusive PPN formula (hand-checked)');
select is(
  (select business_date from public.orders where id = tests.uuid('020:order:a')),
  (now() at time zone 'Asia/Jakarta')::date,
  'business date is the store-local day');
select is(
  (select quantity from public.stock_levels where store_id = tests.id('store.pst') and variant_id = tests.variant('MNM-AIR-600')),
  (select quantity - 2 from t_stock where variant_id = tests.variant('MNM-AIR-600')),
  'stock of Air Mineral went down by 2');
select is(
  (select quantity from public.stock_levels where store_id = tests.id('store.pst') and variant_id = tests.variant('SMB-BRS-5KG')),
  (select quantity - 1 from t_stock where variant_id = tests.variant('SMB-BRS-5KG')),
  'stock of Beras went down by 1');
select is(
  (select count(*)::int from public.stock_movements where reference_id = tests.uuid('020:order:a') and movement_type = 'sale'),
  2,
  'one sale movement per variant');
select is((select points_balance from public.customers where id = tests.customer(1)), 128,
  'customer earned 8 points (120 -> 128)');

-- Retries ------------------------------------------------------------------------------------
select tests.act_as(tests.id('user.device_pst'));
select is(
  public.sync_push(tests.uuid('020:push:a'), 'order', 'upsert', (select payload from t_payload where name = 'a')) ->> 'status',
  'duplicate',
  'retrying the same queue item returns the stored result');
select is(
  public.sync_push(tests.uuid('020:push:a-requeued'), 'order', 'upsert', (select payload from t_payload where name = 'a'))
    -> 'result' ->> 'noop',
  'true',
  'a re-queued copy of a completed order is a no-op');

select tests.act_as_postgres();
select is(
  (select quantity from public.stock_levels where store_id = tests.id('store.pst') and variant_id = tests.variant('MNM-AIR-600')),
  (select quantity - 2 from t_stock where variant_id = tests.variant('MNM-AIR-600')),
  'retries never deduct stock twice');
select is((select count(*)::int from public.orders where order_number = 'PST-T1-261105-0001'), 1,
  'retries never duplicate the order');
select is((select points_balance from public.customers where id = tests.customer(1)), 128,
  'retries never award points twice');

-- Rejected payloads --------------------------------------------------------------------------
select tests.act_as(tests.id('user.device_pst'));
select is(
  public.sync_push(tests.uuid('020:push:bad-tax'), 'order', 'upsert', (select payload from t_payload where name = 'bad_tax')) ->> 'code',
  'tax_mismatch',
  'a bill whose PPN breaks the formula is rejected');
select tests.act_as_postgres();
select is((select count(*)::int from public.orders where id = tests.uuid('020:order:bad-tax')), 0,
  'a rejected order leaves nothing behind');
select is(
  (select error_code from public.sync_rejections where client_uuid = tests.uuid('020:push:bad-tax')),
  'tax_mismatch',
  'the rejection is logged for troubleshooting');
select tests.act_as(tests.id('user.device_pst'));
select is(
  public.sync_push(tests.uuid('020:push:bad-pay'), 'order', 'upsert', (select payload from t_payload where name = 'bad_payment')) ->> 'code',
  'payment_mismatch',
  'payments that do not cover the bill are rejected');

-- Cart versions: open -> completed --------------------------------------------------------------
select is(
  public.sync_push(tests.uuid('020:push:b1'), 'order', 'upsert', (select payload from t_payload where name = 'cart_v1'))
    -> 'result' ->> 'status',
  'open',
  'an open cart syncs as open');
select tests.act_as_postgres();
select is(
  (select quantity from public.stock_levels where store_id = tests.id('store.pst') and variant_id = tests.variant('MNM-TEH-350')),
  (select quantity from t_stock where variant_id = tests.variant('MNM-TEH-350')),
  'open carts do not touch stock');
select tests.act_as(tests.id('user.device_pst'));
select is(
  public.sync_push(tests.uuid('020:push:b2'), 'order', 'upsert', (select payload from t_payload where name = 'cart_v2'))
    -> 'result' ->> 'status',
  'completed',
  'version 2 completes the order');
select tests.act_as_postgres();
select is(
  (select quantity from public.stock_levels where store_id = tests.id('store.pst') and variant_id = tests.variant('MNM-TEH-350')),
  (select quantity - 3 from t_stock where variant_id = tests.variant('MNM-TEH-350')),
  'completion deducts the final quantity (3)');
select tests.act_as(tests.id('user.device_pst'));
select is(
  public.sync_push(tests.uuid('020:push:b1-late'), 'order', 'upsert', (select payload from t_payload where name = 'cart_v1'))
    -> 'result' ->> 'noop',
  'true',
  'a stale cart version arriving late is ignored');
select is(
  public.sync_push(tests.uuid('020:push:b3'), 'order', 'upsert', (select payload from t_payload where name = 'cart_v3')) ->> 'code',
  'order_closed',
  'a completed order cannot be edited by a newer snapshot');

-- Protocol errors -------------------------------------------------------------------------------
select is(
  public.sync_push(gen_random_uuid(), 'order', 'teleport', '{}'::jsonb) ->> 'code',
  'unknown_entity',
  'unknown entity/action pairs are rejected');
select is(
  public.sync_push(tests.uuid('020:push:c'), 'order', 'upsert', (select payload from t_payload where name = 'no_shift')) ->> 'code',
  'shift_required',
  'completing a sale requires a shift');

select * from finish();
rollback;
