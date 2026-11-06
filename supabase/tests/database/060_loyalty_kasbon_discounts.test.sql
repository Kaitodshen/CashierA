-- Loyalty redeem/earn, kasbon (full, partial, installments, overpay, limit),
-- manual discount approval above the threshold, vouchers.
begin;
create extension if not exists pgtap with schema extensions;
select plan(21);

create temporary table t_payload (name text primary key, payload jsonb not null);
grant select on t_payload to authenticated;

create or replace function pg_temp.order(p_name text, p_lines jsonb, p_options jsonb)
returns jsonb language sql as $$
  select tests.order_payload(tests.uuid('060:order:' || p_name), tests.id('store.pst'), tests.uuid('060:shift'),
                             tests.id('emp.eko'), 'PST-T1-261105-04' || lpad(p_name, 2, '0'), p_lines, 'completed', 1, p_options)
$$;

insert into t_payload values
  -- Sari (120 points) redeems 50 points = Rp 5.000 on a Rp 21.000 juice; earns floor(16.000 / 10.000) = 1
  ('l1', pg_temp.order('1', '[{"sku":"MNM-JUS-1L","qty":"1"}]',
     jsonb_build_object('customer_id', tests.customer(1), 'points_redeemed', 50))),
  ('l2', pg_temp.order('2', '[{"sku":"MNM-JUS-1L","qty":"1"}]', '{"points_redeemed":10}')),
  ('k1', pg_temp.order('3', '[{"sku":"SMB-TLR-30","qty":"1"}]',
     jsonb_build_object('customer_id', tests.customer(4), 'earn_points', false,
                        'payments', jsonb_build_array(jsonb_build_object('method', 'kasbon'))))),
  ('k2', pg_temp.order('4', '[{"sku":"SMB-MYK-2L","qty":"2"}]',
     jsonb_build_object('customer_id', tests.customer(4), 'earn_points', false,
                        'payments', jsonb_build_array(jsonb_build_object('method', 'cash', 'amount', 50000, 'tendered', 50000),
                                                      jsonb_build_object('method', 'kasbon'))))),
  ('k3', pg_temp.order('5', '[{"sku":"SMB-TLR-30","qty":"1"}]', '{"payments":[{"method":"kasbon"}]}')),
  -- Lina's kasbon limit is Rp 500.000; this sale is Rp 504.000
  ('k4', pg_temp.order('6', '[{"sku":"SMB-TLR-30","qty":"6"}]',
     jsonb_build_object('customer_id', tests.customer(6), 'earn_points', false,
                        'payments', jsonb_build_array(jsonb_build_object('method', 'kasbon'))))),
  -- 4 x Kopi Susu = Rp 34.000; 25% off (Rp 8.500) is above the 20% threshold
  ('d1', pg_temp.order('7', '[{"sku":"MNM-KOPI-240","qty":"4"}]', '{"bill_discount":{"amount":8500}}')),
  ('d2', pg_temp.order('8', '[{"sku":"MNM-KOPI-240","qty":"4"}]',
     jsonb_build_object('bill_discount', jsonb_build_object('amount', 8500, 'approved_by', tests.id('emp.budi'))))),
  ('d3', pg_temp.order('9', '[{"sku":"MNM-KOPI-240","qty":"4"}]', '{"bill_discount":{"amount":3400}}')),
  ('v1', pg_temp.order('10', '[{"sku":"MNM-JUS-1L","qty":"6"}]', '{"voucher":{"code":"HEMAT10","amount":12600}}'));

create or replace function pg_temp.repay(p_seed text, p_amount bigint, p_method text)
returns jsonb language sql as $$
  select jsonb_build_object('id', tests.uuid('060:repay:' || p_seed), 'order_id', tests.uuid('060:order:3'),
                            'amount', p_amount, 'method_type', p_method,
                            'reference', case when p_method <> 'cash' then 'TRF-0001' end,
                            'employee_id', tests.id('emp.eko'), 'shift_id', tests.uuid('060:shift'), 'paid_at', now())
$$;

select tests.act_as(tests.id('user.device_pst'));
select tests.open_shift('060:shift', tests.id('store.pst'), tests.id('emp.eko'), 200000);

-- Loyalty ------------------------------------------------------------------------------------
select is(public.sync_push(tests.uuid('060:push:l1'), 'order', 'upsert', (select payload from t_payload where name = 'l1')) ->> 'status',
  'applied', 'points are redeemed as a bill discount');
select tests.act_as_postgres();
select is((select points_balance from public.customers where id = tests.customer(1)), 71,
  'balance 120 - 50 redeemed + 1 earned = 71');
select is(
  (select array_agg(points order by points) from public.loyalty_ledger where order_id = tests.uuid('060:order:1')),
  array[-50, 1], 'the ledger holds the redeem and the earn entries');
select tests.act_as(tests.id('user.device_pst'));
select is(public.sync_push(tests.uuid('060:push:l2'), 'order', 'upsert', (select payload from t_payload where name = 'l2')) ->> 'code',
  'loyalty_requires_customer', 'points need a customer');

-- Kasbon ---------------------------------------------------------------------------------------
select is(public.sync_push(tests.uuid('060:push:k1'), 'order', 'upsert', (select payload from t_payload where name = 'k1')) ->> 'status',
  'applied', 'a full kasbon sale is applied');
select tests.act_as_postgres();
select ok(
  (select r.amount = 84000 and r.status = 'open' and r.due_date = o.business_date + 30
   from public.receivables r join public.orders o on o.id = r.order_id
   where r.order_id = tests.uuid('060:order:3')),
  'a receivable of Rp 84.000 is opened, due in 30 days');
select tests.act_as(tests.id('user.device_pst'));
select is(public.sync_push(tests.uuid('060:push:k2'), 'order', 'upsert', (select payload from t_payload where name = 'k2')) ->> 'status',
  'applied', 'a part-cash, part-kasbon sale is applied');
select tests.act_as_postgres();
select is((select amount from public.receivables where order_id = tests.uuid('060:order:4')), 26000::bigint,
  'only the unpaid Rp 26.000 becomes kasbon');
select tests.act_as(tests.id('user.device_pst'));
select is(public.sync_push(tests.uuid('060:push:k3'), 'order', 'upsert', (select payload from t_payload where name = 'k3')) ->> 'code',
  'kasbon_requires_customer', 'kasbon needs a named customer');
select is(public.sync_push(tests.uuid('060:push:r1'), 'receivable_payment', 'create', pg_temp.repay('1', 30000, 'cash'))
            -> 'result' ->> 'balance',
  '54000', 'first installment leaves Rp 54.000');
select is(public.sync_push(tests.uuid('060:push:r2'), 'receivable_payment', 'create', pg_temp.repay('2', 54000, 'transfer'))
            -> 'result' ->> 'status',
  'paid', 'second installment settles the kasbon');
select is(public.sync_push(tests.uuid('060:push:r3'), 'receivable_payment', 'create', pg_temp.repay('3', 1000, 'cash')) ->> 'status',
  'applied', 'an accidental extra payment is still recorded (money was received)');
select tests.act_as_postgres();
select is((select count(*)::int from public.alerts where alert_type = 'KASBON_OVERPAID' and store_id = tests.id('store.pst')), 1,
  'and raises KASBON_OVERPAID for a manager');
select tests.act_as(tests.id('user.device_pst'));
select is(public.sync_push(tests.uuid('060:push:k4'), 'order', 'upsert', (select payload from t_payload where name = 'k4'))
            -> 'result' ->> 'needs_review',
  'true', 'going over a kasbon limit is accepted but flagged');
select tests.act_as_postgres();
select is((select count(*)::int from public.alerts where alert_type = 'KASBON_LIMIT' and reference_id = tests.uuid('060:order:6')), 1,
  'and raises KASBON_LIMIT');

-- Manual discounts ---------------------------------------------------------------------------------
select tests.act_as(tests.id('user.device_pst'));
select is(public.sync_push(tests.uuid('060:push:d1'), 'order', 'upsert', (select payload from t_payload where name = 'd1')) ->> 'code',
  'approval_required', 'a 25% discount needs a manager PIN');
select is(public.sync_push(tests.uuid('060:push:d2'), 'order', 'upsert', (select payload from t_payload where name = 'd2')) ->> 'status',
  'applied', 'with the manager''s approval it goes through');
select tests.act_as_postgres();
select is(
  (select count(*)::int from public.audit_log
   where action = 'pos.discount_override' and entity_id = tests.uuid('060:order:8') and approver_employee_id = tests.id('emp.budi')),
  1, 'the override is audited with the approver');
select tests.act_as(tests.id('user.device_pst'));
select is(public.sync_push(tests.uuid('060:push:d3'), 'order', 'upsert', (select payload from t_payload where name = 'd3')) ->> 'status',
  'applied', 'a 10% discount needs no approval');

-- Vouchers ------------------------------------------------------------------------------------------
select is(public.sync_push(tests.uuid('060:push:v1'), 'order', 'upsert', (select payload from t_payload where name = 'v1')) ->> 'status',
  'applied', 'a voucher sale is applied');
select tests.act_as_postgres();
select is((select used_count from public.vouchers where code = 'HEMAT10'), 1,
  'the voucher use is counted');

select * from finish();
rollback;
