-- Phase 6: points follow the company rules, kasbon is repaid in
-- installments, managers adjust points, and the back office reads the
-- kasbon overview and a customer statement.
begin;
create extension if not exists pgtap with schema extensions;
select plan(22);

-- Sari (customer 1) starts with 120 points. 10 x Mie Goreng = Rp 35.000 net.
create or replace function pg_temp.sale(p_seed text, p_options jsonb, p_qty text default '10')
returns jsonb language sql as $$
  select tests.order_payload(tests.uuid('160:order:' || p_seed), tests.id('store.pst'), tests.uuid('160:shift'),
    tests.id('emp.eko'), 'PST-T1-261107-' || p_seed, jsonb_build_array(jsonb_build_object('sku', 'MIE-GRG-ORI', 'qty', p_qty)),
    'completed', 1, p_options)
$$;
create or replace function pg_temp.push(p_seed text, p_payload jsonb)
returns jsonb language sql as $$
  select public.sync_push(tests.uuid('160:push:' || p_seed), 'order', 'upsert', p_payload)
$$;

select tests.act_as(tests.id('user.device_pst'));
select tests.open_shift('160:shift', tests.id('store.pst'), tests.id('emp.eko'), 100000);

-- Points ----------------------------------------------------------------------------------------
select is(pg_temp.push('a', jsonb_set(pg_temp.sale('0001', jsonb_build_object('customer_id', tests.customer(1))),
                                      '{points_earned}', '5')) ->> 'code',
  'points_earned_mismatch', 'more points than floor(net / Rp 10.000) are refused');
select is(pg_temp.push('b', pg_temp.sale('0002', jsonb_build_object('customer_id', tests.customer(1)))) -> 'result' ->> 'status',
  'completed', 'Rp 35.000 earns exactly 3 points');
select is((select points_balance from public.customers where id = tests.customer(1)), 123,
  'balance 120 + 3');
create temporary table t_c as select pg_temp.sale('0003', jsonb_build_object('customer_id', tests.customer(1),
                                                                  'points_redeemed', 20)) as p;
select tests.act_as_postgres();
update public.business_profile set loyalty_point_value = 200;
select tests.act_as(tests.id('user.device_pst'));
select is(pg_temp.push('c', (select p from t_c)) ->> 'code',
  'points_value_mismatch', 'points must be valued at the company rate');
select tests.act_as_postgres();
update public.business_profile set loyalty_point_value = 100;
select tests.act_as(tests.id('user.device_pst'));
select is(pg_temp.push('d', pg_temp.sale('0004', jsonb_build_object('customer_id', tests.customer(1),
                                                                    'points_redeemed', 20))) ->> 'status',
  'applied', '20 points redeemed for Rp 2.000: net Rp 33.000 earns 3');
select is((select points_balance from public.customers where id = tests.customer(1)), 106,
  'balance 123 - 20 + 3');

select tests.act_as_postgres();
update public.business_profile set loyalty_min_redeem_points = 50;
select tests.act_as(tests.id('user.device_pst'));
select is(pg_temp.push('e', pg_temp.sale('0005', jsonb_build_object('customer_id', tests.customer(1),
                                                                    'points_redeemed', 20))) ->> 'code',
  'points_below_minimum', 'below the minimum redemption is refused');

select tests.act_as_postgres();
update public.business_profile set loyalty_min_redeem_points = 0, loyalty_enabled = false;
select tests.act_as(tests.id('user.device_pst'));
select is(pg_temp.push('f', pg_temp.sale('0006', jsonb_build_object('customer_id', tests.customer(1)))) ->> 'code',
  'loyalty_disabled', 'with loyalty off, no points may be earned');
select is(pg_temp.push('g', pg_temp.sale('0007', jsonb_build_object('customer_id', tests.customer(1),
                                                                    'earn_points', false))) ->> 'status',
  'applied', 'with loyalty off, a sale without points goes through');
select tests.act_as_postgres();
update public.business_profile set loyalty_enabled = true;

-- Kasbon in installments ------------------------------------------------------------------------
select tests.act_as(tests.id('user.device_pst'));
select is(pg_temp.push('k', pg_temp.sale('0010', jsonb_build_object('customer_id', tests.customer(2),
           'payments', jsonb_build_array(jsonb_build_object('method', 'kasbon'))))) ->> 'status',
  'applied', 'Rudi takes Rp 35.000 on kasbon');
create or replace function pg_temp.repay(p_seed text, p_amount bigint, p_method text)
returns jsonb language sql as $$
  select public.sync_push(tests.uuid('160:repay:' || p_seed), 'receivable_payment', 'create',
    jsonb_build_object('id', tests.uuid('160:rp:' || p_seed), 'order_id', tests.uuid('160:order:0010'),
                       'amount', p_amount, 'method_type', p_method, 'employee_id', tests.id('emp.eko'),
                       'shift_id', tests.uuid('160:shift'), 'paid_at', now(),
                       'reference', case when p_method = 'transfer' then 'TRF-01' end))
$$;
select is(pg_temp.repay('1', 15000, 'cash') -> 'result' ->> 'status', 'partial',
  'the first installment leaves it partly paid');
select is(pg_temp.repay('1', 15000, 'cash') ->> 'status', 'duplicate',
  'the same installment sent twice is booked once');
select is(pg_temp.repay('2', 20000, 'transfer') -> 'result' ->> 'balance', '0',
  'the second installment settles it');
select is((select status from public.receivables where order_id = tests.uuid('160:order:0010')), 'paid',
  'the kasbon is paid');
select is((public.shift_summary(tests.uuid('160:shift')) -> 'kasbon' ->> 'repaid_cash')::bigint, 15000::bigint,
  'only the cash installment counts in the drawer');

-- Adjusting points --------------------------------------------------------------------------------
select tests.act_as(tests.id('user.cashier_pst'));
select throws_ok($$ select public.adjust_points(md5('cashiera:customer:1')::uuid, 10, 'Bonus') $$,
  'P0001', null, 'a cashier cannot adjust points');
select tests.act_as(tests.id('user.manager_pst'));
select is(public.adjust_points(tests.customer(1), 10, 'Bonus ulang tahun') ->> 'points_balance', '116',
  'a manager adds 10 points');
select throws_ok($$ select public.adjust_points(md5('cashiera:customer:1')::uuid, -1000, 'Koreksi') $$,
  'P0001', null, 'the balance cannot go below 0');
select tests.act_as_postgres();
select ok(exists (select 1 from public.audit_log where action = 'loyalty.adjusted' and entity_id = tests.customer(1)),
  'the adjustment is audited');
select tests.act_as(tests.id('user.manager_pst'));

-- Back-office reads -------------------------------------------------------------------------------
select tests.act_as(tests.id('user.device_pst'));
select is(pg_temp.push('m', pg_temp.sale('0011', jsonb_build_object('customer_id', tests.customer(4),
           'kasbon_due_date', current_date - 3,
           'payments', jsonb_build_array(jsonb_build_object('method', 'kasbon'))), '2')) ->> 'status',
  'applied', 'Toko Berkah Jaya takes Rp 7.000 on kasbon, already 3 days late');
select tests.act_as(tests.id('user.manager_pst'));
select is((select jsonb_build_array(customer_name, outstanding, overdue)
           from public.kasbon_overview(tests.id('store.pst'), current_date) where customer_id = tests.customer(4)),
  '["Toko Berkah Jaya", 7000, 7000]'::jsonb, 'the overview shows the overdue kasbon');
select is((select jsonb_build_array(
             jsonb_array_length(s -> 'kasbon'),
             (s -> 'kasbon' -> 0 ->> 'status'),
             jsonb_array_length(s -> 'kasbon' -> 0 -> 'payments'))
           from (select public.customer_statement(tests.customer(2)) as s) x),
  '[1, "paid", 2]'::jsonb, 'Rudi''s statement shows the kasbon and both installments');

select * from finish();
rollback;
