-- Customers registered on a terminal, duplicate phones, protected loyalty
-- balance, terminal audit events (drawer open needs a manager PIN).
begin;
create extension if not exists pgtap with schema extensions;
select plan(12);

create or replace function pg_temp.customer(p_seed text, p_phone text, p_employee uuid)
returns jsonb language sql as $$
  select jsonb_build_object('id', tests.uuid('110:customer:' || p_seed), 'name', 'Pelanggan ' || p_seed,
                            'phone', p_phone, 'employee_id', p_employee)
$$;

create or replace function pg_temp.drawer(p_seed text, p_approver uuid)
returns jsonb language sql as $$
  select jsonb_build_object('id', tests.uuid('110:audit:' || p_seed), 'action', 'pos.drawer_open_no_sale',
                            'actor_employee_id', tests.id('emp.eko'), 'approver_employee_id', p_approver,
                            'occurred_at', now(), 'details', jsonb_build_object('reason', 'Tukar uang receh'))
$$;

select tests.act_as(tests.id('user.device_pst'));
select is(public.sync_push(tests.uuid('110:push:1'), 'customer', 'upsert', pg_temp.customer('baru', '081299990001', tests.id('emp.eko'))) ->> 'status',
  'applied', 'a terminal registers a new customer');
select tests.act_as_postgres();
select ok((select code ~ '^C[0-9]{6}$' from public.customers where id = tests.uuid('110:customer:baru')),
  'the server assigns a customer code');
select is((select created_store_id from public.customers where id = tests.uuid('110:customer:baru')), tests.id('store.pst'),
  'the customer remembers the store that registered them');

select tests.act_as(tests.id('user.device_pst'));
select is(public.sync_push(tests.uuid('110:push:2'), 'customer', 'upsert', pg_temp.customer('baru', '081299990002', tests.id('emp.eko')))
            -> 'result' ->> 'customer_id',
  tests.uuid('110:customer:baru')::text, 'updating the same id edits the customer');
select is(public.sync_push(tests.uuid('110:push:3'), 'customer', 'upsert', pg_temp.customer('kembar', '081200000001', tests.id('emp.eko'))) ->> 'status',
  'applied', 'a customer with an existing phone is still saved (offline-safe)');
select tests.act_as_postgres();
select ok(
  (select phone = '081299990002' from public.customers where id = tests.uuid('110:customer:baru'))
  and (select count(*) = 1 from public.alerts where alert_type = 'CUSTOMER_DUPLICATE' and reference_id = tests.uuid('110:customer:kembar')),
  'the phone was updated, and the duplicate raised CUSTOMER_DUPLICATE for merging');

select tests.act_as(tests.id('user.device_pst'));
select is(public.sync_push(tests.uuid('110:push:4'), 'customer', 'upsert', pg_temp.customer('gudang', '081299990003', tests.id('emp.kurniawan'))) ->> 'code',
  'permission_denied', 'staff without customer.manage cannot register customers');

select tests.act_as(tests.id('user.manager_pst'));
select throws_ok($$update public.customers set points_balance = 99999 where id = tests.customer(1)$$,
  '42501', null, 'nobody can write a loyalty balance directly');

-- Terminal audit events --------------------------------------------------------------------------
select tests.act_as(tests.id('user.device_pst'));
select is(public.sync_push(tests.uuid('110:push:drawer1'), 'audit', 'log', pg_temp.drawer('1', null)) ->> 'code',
  'approval_required', 'opening the drawer without a sale needs a manager PIN');
select is(public.sync_push(tests.uuid('110:push:drawer2'), 'audit', 'log', pg_temp.drawer('2', tests.id('emp.budi'))) ->> 'status',
  'applied', 'with the manager''s PIN it is recorded');
select is(public.sync_push(tests.uuid('110:push:fake'), 'audit', 'log',
            jsonb_build_object('action', 'data.delete', 'entity_type', 'orders')) ->> 'code',
  'invalid_input', 'terminals cannot forge database change events');
select tests.act_as_postgres();
select is(
  (select count(*)::int from public.audit_log
   where action = 'pos.drawer_open_no_sale' and approver_employee_id = tests.id('emp.budi') and store_id = tests.id('store.pst')),
  1, 'the drawer event is in the audit log with store and approver');

select * from finish();
rollback;
