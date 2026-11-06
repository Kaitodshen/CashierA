-- Phase 9: dynamic QRIS. A charge is opened by the terminal, settled by the
-- service role (Edge Functions), and a sale can book the payment only once the
-- charge is paid for the same amount.
begin;
create extension if not exists pgtap with schema extensions;
select plan(22);

create or replace function pg_temp.act_as_service()
returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);
  perform set_config('request.jwt.claim.sub', '', true);
  perform set_config('role', 'service_role', true);
end;
$$;

create temporary table t_v (name text primary key, value jsonb);
grant select, insert, update on t_v to authenticated, service_role;

select tests.act_as_postgres();
grant usage on schema tests to service_role;
grant execute on all functions in schema tests to service_role;
select is((select gateway from public.payment_methods where code = 'qris_dynamic'), 'midtrans',
  'QRIS Dinamis is a Midtrans method');
insert into t_v values ('method', to_jsonb((select id from public.payment_methods where code = 'qris_dynamic')));

select tests.act_as(tests.id('user.device_pst'));
select tests.open_shift('200:shift', tests.id('store.pst'), tests.id('emp.eko'), 0);
insert into t_v values ('order', tests.order_payload(tests.uuid('200:order'), tests.id('store.pst'), tests.uuid('200:shift'),
  tests.id('emp.eko'), 'PST-T1-261107-0901', '[{"sku":"MNM-AIR-600","qty":"2"}]'::jsonb, 'completed', 1,
  '{"payments":[{"method":"qris_dynamic"}]}'::jsonb));

create or replace function pg_temp.charge(p_amount bigint default null, p_id uuid default null)
returns jsonb language sql as $$
  select jsonb_build_object(
    'id', coalesce(p_id, (select (value -> 'payments' -> 0 ->> 'id')::uuid from t_v where name = 'order')),
    'store_id', tests.id('store.pst'),
    'payment_method_id', (select value #>> '{}' from t_v where name = 'method'),
    'order_id', tests.uuid('200:order'),
    'order_number', 'PST-T1-261107-0901',
    'amount', coalesce(p_amount, (select (value -> 'payments' -> 0 ->> 'amount')::bigint from t_v where name = 'order')))
$$;
create or replace function pg_temp.pay_id() returns uuid language sql as $$
  select (value -> 'payments' -> 0 ->> 'id')::uuid from t_v where name = 'order'
$$;
create or replace function pg_temp.amount() returns bigint language sql as $$
  select (value -> 'payments' -> 0 ->> 'amount')::bigint from t_v where name = 'order'
$$;

-- Opening ----------------------------------------------------------------------------------------
select tests.act_as(tests.id('user.manager_pst'));
select throws_ok($$ select public.gateway_charge_open(pg_temp.charge()) $$, 'P0001', null,
  'only a paired terminal opens a charge');
select tests.act_as(tests.id('user.device_pst'));
select is(public.gateway_charge_open(pg_temp.charge()) ->> 'status', 'pending', 'the terminal opens a pending charge');
select is(public.gateway_charge_open(pg_temp.charge()) ->> 'status', 'pending', 'opening again returns the same charge');
select throws_ok($$ select public.gateway_charge_open(pg_temp.charge(1)) $$, 'P0001', null,
  'the same id cannot be reused for another amount');
select tests.act_as(tests.id('user.device_bks'));
select throws_ok($$ select public.gateway_charge_status(pg_temp.pay_id()) $$, 'P0001', null,
  'another store cannot read the charge');
select tests.act_as(tests.id('user.device_pst'));
select throws_ok($$ select public.gateway_charge_settle(pg_temp.pay_id(), 'paid') $$, '42501', null,
  'a terminal cannot settle its own charge');

select pg_temp.act_as_service();
select is(public.gateway_charge_attach(pg_temp.pay_id(), 'mt-trx-1', '00020101021226...', now() + interval '15 minutes',
            '{"status_code":"201"}') ->> 'qr_string', '00020101021226...', 'the function stores the QR string');

-- Booking before the money arrived ------------------------------------------------------------------
select tests.act_as(tests.id('user.device_pst'));
select is(public.sync_push(tests.uuid('200:push:early'), 'order', 'upsert', (select value from t_v where name = 'order'))
            ->> 'code', 'gateway_unconfirmed', 'a sale cannot book a pending QRIS payment');

-- Settling -----------------------------------------------------------------------------------------
select pg_temp.act_as_service();
select throws_ok($$ select public.gateway_charge_settle(pg_temp.pay_id(), 'paid', 1) $$, 'P0001', null,
  'a different amount is refused');
select is(public.gateway_charge_status(pg_temp.pay_id()) ->> 'status', 'pending', '... and the charge stays pending');
select is((select jsonb_build_array(r ->> 'status', (r ->> 'changed')::boolean)
           from (select public.gateway_charge_settle(pg_temp.pay_id(), 'paid', pg_temp.amount(), 'mt-trx-1') as r) x),
  '["paid", true]'::jsonb, 'the webhook marks it paid');
select is(public.gateway_charge_settle(pg_temp.pay_id(), 'expired') ->> 'status', 'paid', 'a late expire never undoes paid');
select is((public.gateway_charge_settle(pg_temp.pay_id(), 'paid', pg_temp.amount()) ->> 'changed')::boolean, false,
  'a repeated webhook changes nothing');

-- Booking after ------------------------------------------------------------------------------------
select tests.act_as(tests.id('user.device_pst'));
select is(public.gateway_charge_status(pg_temp.pay_id()) ->> 'status', 'paid', 'the terminal sees it paid');
select is(public.sync_push(tests.uuid('200:push:ok'), 'order', 'upsert', (select value from t_v where name = 'order'))
            ->> 'status', 'applied', 'now the sale books');
select tests.act_as_postgres();
select is((select jsonb_build_array(provider, provider_ref, status) from public.payments where id = pg_temp.pay_id()),
  '["midtrans", "mt-trx-1", "paid"]'::jsonb, 'the payment carries the gateway reference');
select ok(exists (select 1 from public.audit_log where action = 'payment.gateway_paid' and entity_id = pg_temp.pay_id()),
  'the payment is audited');

-- A paid charge without a sale, and a late payment after expiry --------------------------------------
select tests.act_as(tests.id('user.device_pst'));
select public.gateway_charge_open(pg_temp.charge(15000, tests.uuid('200:orphan')));
select public.gateway_charge_open(pg_temp.charge(7000, tests.uuid('200:late')));
select pg_temp.act_as_service();
select public.gateway_charge_settle(tests.uuid('200:orphan'), 'paid', 15000, 'mt-trx-2');
select public.gateway_charge_settle(tests.uuid('200:late'), 'expired');
select is(public.gateway_charge_settle(tests.uuid('200:late'), 'paid', 7000, 'mt-trx-3') ->> 'status', 'paid',
  'money that arrives after expiry still counts');

select tests.act_as(tests.id('user.manager_pst'));
select is((select jsonb_agg(jsonb_build_array(amount, status, matched) order by amount)
           from public.gateway_charge_list(tests.id('store.pst'), current_date - 1, current_date + 1)),
  jsonb_build_array(jsonb_build_array(7000, 'paid', false), jsonb_build_array(pg_temp.amount(), 'paid', true),
                    jsonb_build_array(15000, 'paid', false)),
  'the list flags paid charges that no sale booked');

-- A forged provider on a plain QRIS payment --------------------------------------------------------
select tests.act_as(tests.id('user.device_pst'));
select is(public.sync_push(tests.uuid('200:push:forged'), 'order', 'upsert',
  jsonb_set(tests.order_payload(tests.uuid('200:order2'), tests.id('store.pst'), tests.uuid('200:shift'),
    tests.id('emp.eko'), 'PST-T1-261107-0902', '[{"sku":"MNM-AIR-600","qty":"1"}]'::jsonb, 'completed', 1,
    '{"payments":[{"method":"qris"}]}'::jsonb), '{payments,0,provider}', '"midtrans"')) ->> 'code',
  'gateway_unconfirmed', 'a payment claiming a provider without a charge is refused');
select is(public.sync_push(tests.uuid('200:push:static'), 'order', 'upsert',
  tests.order_payload(tests.uuid('200:order3'), tests.id('store.pst'), tests.uuid('200:shift'),
    tests.id('emp.eko'), 'PST-T1-261107-0903', '[{"sku":"MNM-AIR-600","qty":"1"}]'::jsonb, 'completed', 1,
    '{"payments":[{"method":"qris"}]}'::jsonb)) ->> 'status',
  'applied', 'static QRIS (cashier-recorded) still works offline as before');

select * from finish();
rollback;
