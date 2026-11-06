-- Phase 5 fixture: a printed sale from shift A is voided in shift B, so its
-- cash comes off B. B also has a split sale, a partial cash refund and cash
-- in/out. The same numbers are pinned in
-- packages/cashiera_core/test/shift/server_fixture_test.dart.
-- Then the back-office reads: shift_overview and audit_entries.
begin;
create extension if not exists pgtap with schema extensions;
select plan(27);

create temporary table t_payload (name text primary key, payload jsonb not null);
grant select on t_payload to authenticated;
insert into t_payload values
  -- 2 x Mie Goreng Rp 3.500 = Rp 7.000, cash 10.000.
  ('o1', tests.order_payload(tests.uuid('140:order:1'), tests.id('store.pst'), tests.uuid('140:shift:a'), tests.id('emp.eko'),
     'PST-T1-261106-0901', '[{"sku":"MIE-GRG-ORI","qty":"2"}]'::jsonb, 'completed', 1,
     '{"payments":[{"method":"cash","tendered":10000}]}'::jsonb)),
  -- 10 x Mie Goreng = Rp 35.000 less an approved bill discount of Rp 10.000 (28%), paid by debit.
  ('o3', tests.order_payload(tests.uuid('140:order:3'), tests.id('store.pst'), tests.uuid('140:shift:a'), tests.id('emp.eko'),
     'PST-T1-261106-0903', '[{"sku":"MIE-GRG-ORI","qty":"10"}]'::jsonb, 'completed', 1,
     jsonb_build_object('bill_discount', jsonb_build_object('amount', 10000, 'approved_by', tests.id('emp.budi')),
                        'payments', jsonb_build_array(jsonb_build_object('method', 'debit', 'reference', 'APR2'))))),
  -- 4 x Mie Goreng = Rp 14.000: debit 4.000 + cash 10.000 (tendered 20.000).
  ('o2', tests.order_payload(tests.uuid('140:order:2'), tests.id('store.pst'), tests.uuid('140:shift:b'), tests.id('emp.eko'),
     'PST-T1-261106-0902', '[{"sku":"MIE-GRG-ORI","qty":"4"}]'::jsonb, 'completed', 1,
     '{"payments":[{"method":"debit","amount":4000,"reference":"APR9"},{"method":"cash","tendered":20000}]}'::jsonb));

create or replace function pg_temp.void(p_approver uuid)
returns jsonb language sql as $$
  select jsonb_build_object('order_id', tests.uuid('140:order:1'), 'voided_by', tests.id('emp.eko'),
                            'approved_by', p_approver, 'reason', 'Salah input barang',
                            'shift_id', tests.uuid('140:shift:b'), 'voided_at', now())
$$;

select tests.act_as(tests.id('user.device_pst'));
select tests.open_shift('140:shift:a', tests.id('store.pst'), tests.id('emp.eko'), 100000);
select is(public.sync_push(tests.uuid('140:push:o1'), 'order', 'upsert', (select payload from t_payload where name = 'o1')) ->> 'status',
  'applied', 'shift A: cash sale');
select is(public.sync_push(tests.uuid('140:push:o3'), 'order', 'upsert', (select payload from t_payload where name = 'o3')) ->> 'status',
  'applied', 'shift A: debit sale with an approved discount');
select is(public.sync_push(tests.uuid('140:push:print1'), 'order', 'mark_printed',
            jsonb_build_object('order_id', tests.uuid('140:order:1'), 'printed_at', now())) ->> 'status',
  'applied', 'its receipt is printed');
select is(public.sync_push(tests.uuid('140:push:close-a'), 'shift', 'close',
            jsonb_build_object('id', tests.uuid('140:shift:a'), 'closed_by', tests.id('emp.eko'), 'closed_at', now(),
                               'counted_cash', 107000, 'client_expected_cash', 107000)) -> 'result' ->> 'cash_difference',
  '0', 'shift A closes even');

select tests.open_shift('140:shift:b', tests.id('store.pst'), tests.id('emp.eko'), 50000);
select is(public.sync_push(tests.uuid('140:push:o2'), 'order', 'upsert', (select payload from t_payload where name = 'o2')) ->> 'status',
  'applied', 'shift B: debit + cash sale');
select is(public.sync_push(tests.uuid('140:push:in'), 'cash_movement', 'create',
            jsonb_build_object('id', tests.uuid('140:cash:in'), 'shift_id', tests.uuid('140:shift:b'), 'movement_type', 'in',
                               'amount', 25000, 'reason', 'Tambah uang kembalian', 'employee_id', tests.id('emp.eko'),
                               'occurred_at', now())) ->> 'status',
  'applied', 'cash in');
select is(public.sync_push(tests.uuid('140:push:out'), 'cash_movement', 'create',
            jsonb_build_object('id', tests.uuid('140:cash:out'), 'shift_id', tests.uuid('140:shift:b'), 'movement_type', 'out',
                               'amount', 5000, 'reason', 'Beli kantong plastik', 'employee_id', tests.id('emp.eko'),
                               'occurred_at', now())) ->> 'status',
  'applied', 'cash out');
select is(public.sync_push(tests.uuid('140:push:void0'), 'order', 'void', pg_temp.void(null)) ->> 'code',
  'approval_required', 'a printed sale needs an approver to void');
select is(public.sync_push(tests.uuid('140:push:void1'), 'order', 'void', pg_temp.void(tests.id('emp.budi'))) ->> 'status',
  'applied', 'the manager approves the void');
select is(public.sync_push(tests.uuid('140:push:refund'), 'refund', 'create',
            jsonb_build_object(
              'id', tests.uuid('140:refund'), 'order_id', tests.uuid('140:order:2'),
              'refund_number', 'R-PST-T1-261106-0001', 'reason', 'Kemasan sobek', 'amount', 3500,
              'method_type', 'cash', 'restock', true, 'employee_id', tests.id('emp.eko'),
              'approved_by', tests.id('emp.eko'), 'shift_id', tests.uuid('140:shift:b'), 'refunded_at', now(),
              'items', jsonb_build_array(jsonb_build_object(
                'id', tests.uuid('140:refund-item'),
                'order_item_id', md5(tests.uuid('140:order:2')::text || ':item:1')::uuid,
                'quantity', '1', 'amount', 3500)))) ->> 'code',
  'approval_denied', 'a cashier cannot approve their own refund');
select is(public.sync_push(tests.uuid('140:push:refund2'), 'refund', 'create',
            jsonb_build_object(
              'id', tests.uuid('140:refund'), 'order_id', tests.uuid('140:order:2'),
              'refund_number', 'R-PST-T1-261106-0001', 'reason', 'Kemasan sobek', 'amount', 3500,
              'method_type', 'cash', 'restock', true, 'employee_id', tests.id('emp.eko'),
              'approved_by', tests.id('emp.budi'), 'shift_id', tests.uuid('140:shift:b'), 'refunded_at', now(),
              'items', jsonb_build_array(jsonb_build_object(
                'id', tests.uuid('140:refund-item'),
                'order_item_id', md5(tests.uuid('140:order:2')::text || ':item:1')::uuid,
                'quantity', '1', 'amount', 3500)))) ->> 'status',
  'applied', '1 of 4 refunded in cash with the manager');

-- X report of shift B -------------------------------------------------------------------------
create temporary table t_x as select public.shift_summary(tests.uuid('140:shift:b')) as r;
select is((select (r -> 'cash' ->> 'expected_cash')::bigint from t_x), 69500::bigint,
  'expected = 50.000 + 10.000 - 7.000 (void from shift A) - 3.500 + 25.000 - 5.000');
select is((select r -> 'voids' from t_x), '{"orders": 1, "grand_total": 7000}'::jsonb,
  'the void from shift A is counted in shift B');
select is((select r -> 'refunds' from t_x), '{"count": 1, "amount": 3500, "cash_amount": 3500}'::jsonb,
  'the refund is counted in shift B');
select is((select jsonb_agg(jsonb_build_array(x ->> 'name', (x ->> 'count')::int, (x ->> 'amount')::bigint))
           from t_x, jsonb_array_elements(r -> 'payments') x),
  '[["Tunai", 1, 10000], ["Kartu Debit", 1, 4000]]'::jsonb, 'payments by method, in method order');
select is((select (r -> 'top_items' -> 0 ->> 'quantity')::numeric from t_x), 3::numeric,
  'top items are net of the refund');
select is((select jsonb_build_array(r -> 'shift' ->> 'device_code', r -> 'shift' ->> 'opened_by_name') from t_x),
  '["T1", "Eko Saputra"]'::jsonb, 'the report names the terminal and the cashier');

select is((select expected_cash from public.shifts where id = tests.uuid('140:shift:a')), 107000::bigint,
  'the closed shift A keeps its expected cash');
select is(public.sync_push(tests.uuid('140:push:close-b'), 'shift', 'close',
            jsonb_build_object('id', tests.uuid('140:shift:b'), 'closed_by', tests.id('emp.eko'), 'closed_at', now(),
                               'counted_cash', 70000, 'client_expected_cash', 69500)) -> 'result' ->> 'cash_difference',
  '500', 'shift B closes Rp 500 over');

-- shift_overview ------------------------------------------------------------------------------
select tests.act_as(tests.id('user.manager_pst'));
select is((select jsonb_build_array(device_code, closed_by_name, cash_difference, order_count, sales_total)
           from public.shift_overview(tests.id('store.pst'), current_date - 1, current_date + 1)
           where shift_id = tests.uuid('140:shift:b')),
  '["T1", "Eko Saputra", 500, 1, 14000]'::jsonb, 'the manager sees shift B with its selisih and sales');
select is((select order_count from public.shift_overview(tests.id('store.pst'))
           where shift_id = tests.uuid('140:shift:a')),
  1::bigint, 'the voided sale no longer counts for shift A');
select tests.act_as(tests.id('user.manager_bks'));
select throws_ok($$ select * from public.shift_overview('a0000000-0000-4000-8000-000000000001'::uuid) $$,
  'P0001', null, 'another store''s manager cannot list Pusat''s shifts');

-- audit_entries -------------------------------------------------------------------------------
select tests.act_as(tests.id('user.manager_pst'));
select is((select jsonb_agg(jsonb_build_array(action, actor_name, approver_name, device_code) order by action)
           from public.audit_entries(tests.id('store.pst'), now() - interval '1 hour', now() + interval '1 hour', true)
           where entity_id in (tests.uuid('140:order:1'), tests.uuid('140:order:2'))),
  '[["order.refunded", "Eko Saputra", "Budi Santoso", "T1"], ["order.voided", "Eko Saputra", "Budi Santoso", "T1"]]'::jsonb,
  'approvals list the void and the refund with both names');
select is((select jsonb_build_array(actor_name, approver_name, (details ->> 'amount')::bigint)
           from public.audit_entries(tests.id('store.pst'), p_only_approvals => true)
           where action = 'order.discount_approved' and entity_id = tests.uuid('140:order:3')),
  '["Eko Saputra", "Budi Santoso", 10000]'::jsonb, 'an approved discount is audited once the sale completes');
select ok((select bool_and(action like 'shift.%') and count(*) >= 4
           from public.audit_entries(tests.id('store.pst'), p_action_prefix => 'shift.')),
  'the action filter keeps shift entries');
select is((select count(*) from (
             select id from public.audit_entries(tests.id('store.pst'), p_limit => 3)
             intersect
             select a.id from public.audit_entries(tests.id('store.pst'), p_limit => 3,
               p_before => (select occurred_at from public.audit_entries(tests.id('store.pst'), p_limit => 3) offset 2 limit 1),
               p_before_id => (select id from public.audit_entries(tests.id('store.pst'), p_limit => 3) offset 2 limit 1)) a) x),
  0::bigint, 'the next page starts after the last row shown');
select tests.act_as(tests.id('user.cashier_pst'));
select throws_ok($$ select * from public.audit_entries() $$,
  'P0001', null, 'a cashier cannot read the audit log');

select * from finish();
rollback;
