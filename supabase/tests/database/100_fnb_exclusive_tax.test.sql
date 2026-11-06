-- F&B mode at one store: exclusive tax + service charge, table occupancy,
-- kitchen tickets (KDS), cancelling a dine-in order.
begin;
create extension if not exists pgtap with schema extensions;
select plan(13);

update public.stores set fnb_mode = true where id = tests.id('store.tgr');
update public.store_settings
   set tax_name = 'PB1', tax_rate_bps = 1000, tax_inclusive = false,
       service_charge_enabled = true, service_charge_bps = 500, service_charge_taxable = true
 where store_id = tests.id('store.tgr');
insert into public.dining_tables (id, store_id, name, area, capacity)
values (tests.uuid('100:table'), tests.id('store.tgr'), 'Meja 1', 'Teras', 4);

create or replace function pg_temp.dine_in(p_seed text, p_status text, p_version integer)
returns jsonb language sql as $$
  select jsonb_set(
    tests.order_payload(tests.uuid('100:order:' || p_seed), tests.id('store.tgr'), tests.uuid('100:shift'), tests.id('emp.indra'),
      'TGR-T1-261105-' || p_seed, '[{"sku":"MNM-TEH-350","qty":"2"}]'::jsonb, p_status, p_version, '{"order_type":"dine_in"}'::jsonb)
      || jsonb_build_object('table_id', tests.uuid('100:table')),
    '{items,0,kitchen_station}', '"bar"')
$$;

create temporary table t_payload (name text primary key, payload jsonb not null);
grant select on t_payload to authenticated;
insert into t_payload values
  ('a1', pg_temp.dine_in('0001', 'open', 1)),
  ('a2', pg_temp.dine_in('0001', 'completed', 2)),
  ('b1', pg_temp.dine_in('0002', 'open', 1)),
  ('b2', pg_temp.dine_in('0002', 'cancelled', 2)
         || jsonb_build_object('cancel', jsonb_build_object('cancelled_by', tests.id('emp.indra'), 'reason', 'Tamu batal pesan')));

create or replace function pg_temp.ticket(p_status text, p_employee uuid)
returns jsonb language sql as $$
  select jsonb_build_object('order_id', tests.uuid('100:order:0001'), 'station', 'bar', 'status', p_status, 'employee_id', p_employee)
$$;

select tests.act_as(tests.id('user.device_tgr'));
select tests.open_shift('100:shift', tests.id('store.tgr'), tests.id('emp.indra'), 0);

select is(public.sync_push(tests.uuid('100:push:a1'), 'order', 'upsert', (select payload from t_payload where name = 'a1'))
            -> 'result' ->> 'status',
  'open', 'a dine-in order is opened on Meja 1');
select tests.act_as_postgres();
select ok(
  (select status = 'occupied' and current_order_id = tests.uuid('100:order:0001') from public.dining_tables where id = tests.uuid('100:table')),
  'the table shows as occupied by that order');
select is(
  (select status from public.order_status where order_id = tests.uuid('100:order:0001') and station = 'bar'),
  'new', 'a bar ticket appears on the kitchen display');

select tests.act_as(tests.id('user.device_tgr'));
select is(public.sync_push(gen_random_uuid(), 'kitchen', 'status', pg_temp.ticket('preparing', tests.id('emp.indra'))) ->> 'code',
  'permission_denied', 'a cashier without kitchen.view cannot move tickets');
select is(public.sync_push(gen_random_uuid(), 'kitchen', 'status', pg_temp.ticket('preparing', tests.id('emp.dewi'))) ->> 'status',
  'applied', 'kitchen staff mark the ticket as preparing');

-- Exclusive tax and service charge, checked by hand:
--   2 x Teh Melati @ Rp 6.000 (TGR price) = 12.000 · service 5% = 600
--   PB1 10% on (12.000 + 600) = 1.260 · grand = 12.000 + 600 + 1.260 = 13.860
select is(public.sync_push(tests.uuid('100:push:a2'), 'order', 'upsert', (select payload from t_payload where name = 'a2')) ->> 'status',
  'applied', 'the bill is paid');
select tests.act_as_postgres();
select is(
  (select array[gross_total, service_charge_total, tax_total, grand_total] from public.orders where id = tests.uuid('100:order:0001')),
  array[12000, 600, 1260, 13860]::bigint[], 'exclusive tax is added on top of the subtotal plus service');
select ok(
  (select status = 'cleaning' and current_order_id is null from public.dining_tables where id = tests.uuid('100:table')),
  'paying frees the table for cleaning');

select tests.act_as(tests.id('user.device_tgr'));
select is(public.sync_push(gen_random_uuid(), 'dining_table', 'status',
            jsonb_build_object('table_id', tests.uuid('100:table'), 'status', 'available', 'employee_id', tests.id('emp.indra'))) ->> 'status',
  'applied', 'the cashier marks the table clean');
select is(public.sync_push(tests.uuid('100:push:b1'), 'order', 'upsert', (select payload from t_payload where name = 'b1'))
            -> 'result' ->> 'status',
  'open', 'a new party sits at the table');
select is(public.sync_push(tests.uuid('100:push:b2'), 'order', 'upsert', (select payload from t_payload where name = 'b2'))
            -> 'result' ->> 'status',
  'cancelled', 'the unprinted order is cancelled without a manager');
select tests.act_as_postgres();
select ok(
  (select t.status = 'available' and t.current_order_id is null
          and (select os.status from public.order_status os where os.order_id = tests.uuid('100:order:0002') and os.station = 'bar') = 'cancelled'
   from public.dining_tables t where t.id = tests.uuid('100:table')),
  'cancelling releases the table and cancels the kitchen ticket');
select is(
  (select count(*)::int from public.audit_log where action = 'order.cancelled' and entity_id = tests.uuid('100:order:0002')),
  1, 'the cancellation is audited');

select * from finish();
rollback;
