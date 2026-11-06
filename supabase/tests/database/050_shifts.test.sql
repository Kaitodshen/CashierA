-- Shift cash: kas awal, cash / QRIS / split / kasbon sales, petty cash, kasbon
-- repayment, X and Z reports, selisih, one open shift per terminal.
begin;
create extension if not exists pgtap with schema extensions;
select plan(21);

create temporary table t_payload (name text primary key, payload jsonb not null);
grant select on t_payload to authenticated;
insert into t_payload values
  ('s1', tests.order_payload(tests.uuid('050:order:1'), tests.id('store.pst'), tests.uuid('050:shift:1'), tests.id('emp.eko'),
     'PST-T1-261105-0301', '[{"sku":"MIE-GRG-ORI","qty":"2"}]'::jsonb, 'completed', 1,
     '{"payments":[{"method":"cash","tendered":10000}]}'::jsonb)),
  ('s2', tests.order_payload(tests.uuid('050:order:2'), tests.id('store.pst'), tests.uuid('050:shift:1'), tests.id('emp.eko'),
     'PST-T1-261105-0302', '[{"sku":"SMB-MYK-2L","qty":"1"}]'::jsonb, 'completed', 1,
     '{"payments":[{"method":"qris"}]}'::jsonb)),
  ('s3', tests.order_payload(tests.uuid('050:order:3'), tests.id('store.pst'), tests.uuid('050:shift:1'), tests.id('emp.eko'),
     'PST-T1-261105-0303', '[{"sku":"SMB-BRS-5KG","qty":"1"}]'::jsonb, 'completed', 1,
     '{"payments":[{"method":"cash","amount":50000,"tendered":50000},{"method":"debit","reference":"APR123"}]}'::jsonb)),
  ('s4', tests.order_payload(tests.uuid('050:order:4'), tests.id('store.pst'), tests.uuid('050:shift:1'), tests.id('emp.eko'),
     'PST-T1-261105-0304', '[{"sku":"SMB-GLA-1KG","qty":"1"}]'::jsonb, 'completed', 1,
     jsonb_build_object('customer_id', tests.customer(4), 'earn_points', false,
                        'payments', jsonb_build_array(jsonb_build_object('method', 'kasbon')))));

create or replace function pg_temp.cash(p_seed text, p_type text, p_amount bigint, p_reason text, p_shift text default '050:shift:1')
returns jsonb language sql as $$
  select jsonb_build_object('id', tests.uuid('050:cash:' || p_seed), 'shift_id', tests.uuid(p_shift),
                            'movement_type', p_type, 'amount', p_amount, 'reason', p_reason,
                            'employee_id', tests.id('emp.eko'), 'occurred_at', now())
$$;

create or replace function pg_temp.close(p_shift text, p_counted bigint, p_client_expected bigint)
returns jsonb language sql as $$
  select jsonb_build_object('id', tests.uuid(p_shift), 'closed_by', tests.id('emp.eko'), 'closed_at', now(),
                            'counted_cash', p_counted, 'client_expected_cash', p_client_expected)
$$;

select tests.act_as(tests.id('user.device_pst'));
select tests.open_shift('050:shift:1', tests.id('store.pst'), tests.id('emp.eko'), 300000);

select is(public.sync_push(tests.uuid('050:push:1'), 'order', 'upsert', (select payload from t_payload where name = 's1')) ->> 'status',
  'applied', 'cash sale');
select is(public.sync_push(tests.uuid('050:push:2'), 'order', 'upsert', (select payload from t_payload where name = 's2')) ->> 'status',
  'applied', 'QRIS sale');
select is(public.sync_push(tests.uuid('050:push:3'), 'order', 'upsert', (select payload from t_payload where name = 's3')) ->> 'status',
  'applied', 'split cash + debit sale');
select is(public.sync_push(tests.uuid('050:push:4'), 'order', 'upsert', (select payload from t_payload where name = 's4')) ->> 'status',
  'applied', 'kasbon sale');
select is(public.sync_push(tests.uuid('050:push:in'), 'cash_movement', 'create',
            pg_temp.cash('in', 'in', 100000, 'Tambahan uang kembalian')) ->> 'status',
  'applied', 'petty cash in');
select is(public.sync_push(tests.uuid('050:push:out'), 'cash_movement', 'create',
            pg_temp.cash('out', 'out', 25000, 'Beli es batu')) ->> 'status',
  'applied', 'petty cash out');
select is(public.sync_push(tests.uuid('050:push:bad'), 'cash_movement', 'create',
            pg_temp.cash('bad', 'out', 5000, 'x')) ->> 'code',
  'db_23514', 'petty cash needs a real note');
select is(public.sync_push(tests.uuid('050:push:repay'), 'receivable_payment', 'create',
            jsonb_build_object('id', tests.uuid('050:repay'), 'order_id', tests.uuid('050:order:4'), 'amount', 10000,
                               'method_type', 'cash', 'employee_id', tests.id('emp.eko'),
                               'shift_id', tests.uuid('050:shift:1'), 'paid_at', now())) -> 'result' ->> 'balance',
  '8500', 'a kasbon repayment in cash leaves Rp 8.500 owed');

-- X-report -------------------------------------------------------------------------------------
select is((public.shift_summary(tests.uuid('050:shift:1')) -> 'cash' ->> 'expected_cash')::bigint, 442000::bigint,
  'expected cash = 300.000 + 7.000 + 50.000 + 100.000 - 25.000 + 10.000');
select is(public.shift_summary(tests.uuid('050:shift:1')) ->> 'report', 'X',
  'an open shift gives an X-report');
select is((public.shift_summary(tests.uuid('050:shift:1')) -> 'sales' ->> 'grand_total')::bigint, 141500::bigint,
  'sales total of the four orders');
select is(
  (select (x ->> 'amount')::bigint from jsonb_array_elements(public.shift_summary(tests.uuid('050:shift:1')) -> 'payments') x
   where x ->> 'method_type' = 'qris'),
  38000::bigint, 'the payment mix shows QRIS');

-- Close (Z-report) -----------------------------------------------------------------------------
select is(public.sync_push(tests.uuid('050:push:close'), 'shift', 'close', pg_temp.close('050:shift:1', 440000, 442000))
            -> 'result' ->> 'cash_difference',
  '-2000', 'closing records a selisih of -Rp 2.000');
select is(public.sync_push(tests.uuid('050:push:close-again'), 'shift', 'close', pg_temp.close('050:shift:1', 440000, 442000))
            -> 'result' ->> 'noop',
  'true', 'closing twice is a no-op');
select is(public.sync_push(tests.uuid('050:push:late-cash'), 'cash_movement', 'create',
            pg_temp.cash('late', 'out', 1000, 'Parkir motor')) ->> 'code',
  'shift_closed', 'no petty cash after the shift is closed');
select is(public.shift_summary(tests.uuid('050:shift:1')) ->> 'report', 'Z',
  'a closed shift gives a Z-report');

select tests.act_as_postgres();
select is((select count(*)::int from public.alerts where alert_type = 'CASH_DISCREPANCY' and reference_id = tests.uuid('050:shift:1')),
  0, 'terminal and server agree on expected cash');

-- Next shift on the same terminal ----------------------------------------------------------------
select tests.act_as(tests.id('user.device_pst'));
select ok(tests.open_shift('050:shift:2', tests.id('store.pst'), tests.id('emp.fitri'), 100000) is not null,
  'the next shift opens on the same terminal');
select is(public.sync_push(tests.uuid('050:push:open3'), 'shift', 'open',
            jsonb_build_object('id', tests.uuid('050:shift:3'), 'store_id', tests.id('store.pst'),
                               'opened_by', tests.id('emp.fitri'), 'opened_at', now(), 'opening_cash', 0)) ->> 'code',
  'db_23505', 'only one open shift per terminal');
select is(public.sync_push(tests.uuid('050:push:close2'), 'shift', 'close', pg_temp.close('050:shift:2', 100000, 99999))
            -> 'result' ->> 'expected_cash',
  '100000', 'the server computes expected cash itself');

select tests.act_as_postgres();
select is((select count(*)::int from public.alerts where alert_type = 'CASH_DISCREPANCY' and reference_id = tests.uuid('050:shift:2')),
  1, 'a terminal/server mismatch raises CASH_DISCREPANCY');

select * from finish();
rollback;
