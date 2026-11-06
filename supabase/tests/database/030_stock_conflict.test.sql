-- Two terminals sell the last unit while offline. Rule: arrival order wins,
-- stock may go negative, the later order is flagged, the cashier is never blocked.
begin;
create extension if not exists pgtap with schema extensions;
select plan(13);

-- A second terminal at PST
insert into auth.users (id, aud, role, is_anonymous, created_at, updated_at)
values (tests.uuid('030:t2-user'), 'authenticated', 'authenticated', true, now(), now());
insert into public.devices (id, store_id, auth_user_id, code, name, platform)
values (tests.uuid('030:t2'), tests.id('store.pst'), tests.uuid('030:t2-user'), 'T2', 'Kasir 2 Pusat', 'android');

-- Exactly one Tisu Wajah left at PST
select app.apply_stock_delta(
  tests.id('store.pst'), tests.variant('KBR-TSU-250'),
  1 - (select quantity from public.stock_levels
       where store_id = tests.id('store.pst') and variant_id = tests.variant('KBR-TSU-250')),
  'adjustment', null, null, tests.id('emp.budi'), 'test setup');

create temporary table t_payload (name text primary key, payload jsonb not null);
grant select on t_payload to authenticated;
insert into t_payload values
  ('t1', tests.order_payload(tests.uuid('030:order:1'), tests.id('store.pst'), tests.uuid('030:shift:1'), tests.id('emp.eko'),
     'PST-T1-261105-0101', '[{"sku":"KBR-TSU-250","qty":"1"}]'::jsonb)),
  ('t2', tests.order_payload(tests.uuid('030:order:2'), tests.id('store.pst'), tests.uuid('030:shift:2'), tests.id('emp.fitri'),
     'PST-T2-261105-0001', '[{"sku":"KBR-TSU-250","qty":"1"}]'::jsonb)),
  ('t2_wrong_shift', tests.order_payload(tests.uuid('030:order:3'), tests.id('store.pst'), tests.uuid('030:shift:1'), tests.id('emp.fitri'),
     'PST-T2-261105-0002', '[{"sku":"KBR-TSU-250","qty":"1"}]'::jsonb));

select tests.act_as(tests.id('user.device_pst'));
select tests.open_shift('030:shift:1', tests.id('store.pst'), tests.id('emp.eko'), 200000);
select is(
  public.sync_push(tests.uuid('030:push:1'), 'order', 'upsert', (select payload from t_payload where name = 't1')) ->> 'status',
  'applied',
  'terminal 1 sells the last unit');

select tests.act_as(tests.uuid('030:t2-user'));
select tests.open_shift('030:shift:2', tests.id('store.pst'), tests.id('emp.fitri'), 200000);
select is(
  public.sync_push(tests.uuid('030:push:2'), 'order', 'upsert', (select payload from t_payload where name = 't2')) ->> 'status',
  'applied',
  'terminal 2 sold the same unit offline and is not blocked');
select is(
  public.sync_push(tests.uuid('030:push:3'), 'order', 'upsert', (select payload from t_payload where name = 't2_wrong_shift')) ->> 'code',
  'shift_other_device',
  'a terminal cannot book sales into another terminal''s shift');

select tests.act_as_postgres();
select is(
  (select quantity from public.stock_levels where store_id = tests.id('store.pst') and variant_id = tests.variant('KBR-TSU-250')),
  -1.000::numeric,
  'stock went negative (-1)');
select is((select needs_review from public.orders where id = tests.uuid('030:order:1')), false,
  'the first-received order is clean');
select is((select needs_review from public.orders where id = tests.uuid('030:order:2')), true,
  'the later order is flagged for manager review');
select ok((select review_reason from public.orders where id = tests.uuid('030:order:2')) like '%stock_negative%',
  'the review reason says stock went negative');
select is(
  (select count(*)::int from public.alerts
   where alert_type = 'STOCK_DISCREPANCY' and reference_id = tests.uuid('030:order:2')
     and variant_id = tests.variant('KBR-TSU-250')),
  1,
  'a STOCK_DISCREPANCY alert points at the later order');
select is(
  (select count(*)::int from public.alerts where alert_type = 'STOCK_DISCREPANCY' and reference_id = tests.uuid('030:order:1')),
  0,
  'no discrepancy alert for the first order');
select is(
  (select count(*)::int from public.alerts
   where alert_type = 'LOW_STOCK' and status <> 'resolved'
     and store_id = tests.id('store.pst') and variant_id = tests.variant('KBR-TSU-250')),
  1,
  'exactly one open LOW_STOCK alert');

-- The inventory clerk restocks on terminal 1
select tests.act_as(tests.id('user.device_pst'));
select is(
  public.sync_push(tests.uuid('030:push:restock'), 'stock_adjustment', 'create',
    jsonb_build_object(
      'id', tests.uuid('030:adj'), 'store_id', tests.id('store.pst'), 'adjustment_number', 'ADJ-261105-0001',
      'reason', 'stock_in', 'employee_id', tests.id('emp.kurniawan'),
      'items', jsonb_build_array(jsonb_build_object(
        'id', tests.uuid('030:adj:1'), 'variant_id', tests.variant('KBR-TSU-250'), 'quantity_delta', '30')))) ->> 'status',
  'applied',
  'restock is applied');

select tests.act_as_postgres();
select is(
  (select quantity from public.stock_levels where store_id = tests.id('store.pst') and variant_id = tests.variant('KBR-TSU-250')),
  29.000::numeric,
  'stock after restock is 29');
select is(
  (select count(*)::int from public.alerts
   where alert_type = 'LOW_STOCK' and status <> 'resolved'
     and store_id = tests.id('store.pst') and variant_id = tests.variant('KBR-TSU-250')),
  0,
  'the LOW_STOCK alert resolved itself after restocking');

select * from finish();
rollback;
