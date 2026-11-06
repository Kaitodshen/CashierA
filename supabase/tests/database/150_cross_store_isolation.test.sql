-- Store isolation beyond orders (010): a store A (PST) terminal and a store A
-- cashier signed in by email try to read and change store B (BKS) money data
-- through every Phase 5 path. Every attempt must fail or see nothing.
begin;
create extension if not exists pgtap with schema extensions;
select plan(36);

-- Store B: a shift, a completed cash sale and a cash movement, made by the BKS terminal.
create temporary table t_ids (name text primary key, id uuid not null);
grant select on t_ids to authenticated;
insert into t_ids values
  ('shift', tests.uuid('150:shift:bks')),
  ('order', tests.uuid('150:order:bks')),
  ('item', md5(tests.uuid('150:order:bks')::text || ':item:1')::uuid);

select tests.act_as(tests.id('user.device_bks'));
select tests.open_shift('150:shift:bks', tests.id('store.bks'), tests.id('emp.gilang'), 100000);
select is(public.sync_push(tests.uuid('150:push:sale'), 'order', 'upsert',
            tests.order_payload(tests.uuid('150:order:bks'), tests.id('store.bks'), tests.uuid('150:shift:bks'),
                                tests.id('emp.gilang'), 'BKS-T1-261106-0001', '[{"sku":"MIE-GRG-ORI","qty":"2"}]'::jsonb,
                                'completed', 1, '{"payments":[{"method":"cash","tendered":10000}]}'::jsonb)) ->> 'status',
  'applied', 'fixture: store B sells for cash');
select is(public.sync_push(tests.uuid('150:push:cash'), 'cash_movement', 'create',
            jsonb_build_object('id', tests.uuid('150:cash:bks'), 'shift_id', tests.uuid('150:shift:bks'),
                               'movement_type', 'in', 'amount', 5000, 'reason', 'Uang kecil',
                               'employee_id', tests.id('emp.gilang'), 'occurred_at', now())) ->> 'status',
  'applied', 'fixture: store B cash in');

-- The same attempts for both store A principals.
create or replace function pg_temp.attempts(p_actor uuid)
returns table (what text, code text)
language sql as $$
  select 'void', public.sync_push(gen_random_uuid(), 'order', 'void',
           jsonb_build_object('order_id', (select id from t_ids where name = 'order'), 'voided_by', p_actor,
                              'approved_by', tests.id('emp.budi'), 'reason', 'Coba void',
                              'shift_id', (select id from t_ids where name = 'shift'))) ->> 'code'
  union all
  select 'mark_printed', public.sync_push(gen_random_uuid(), 'order', 'mark_printed',
           jsonb_build_object('order_id', (select id from t_ids where name = 'order'), 'printed_at', now())) ->> 'code'
  union all
  select 'refund', public.sync_push(gen_random_uuid(), 'refund', 'create',
           jsonb_build_object('id', gen_random_uuid(), 'order_id', (select id from t_ids where name = 'order'),
                              'refund_number', 'R-HACK-1', 'reason', 'Coba refund', 'amount', 3500,
                              'method_type', 'cash', 'restock', true, 'employee_id', p_actor,
                              'approved_by', tests.id('emp.budi'), 'shift_id', (select id from t_ids where name = 'shift'),
                              'items', jsonb_build_array(jsonb_build_object('id', gen_random_uuid(),
                                'order_item_id', (select id from t_ids where name = 'item'),
                                'quantity', '1', 'amount', 3500)))) ->> 'code'
  union all
  select 'shift_close', public.sync_push(gen_random_uuid(), 'shift', 'close',
           jsonb_build_object('id', (select id from t_ids where name = 'shift'), 'closed_by', p_actor,
                              'closed_at', now(), 'counted_cash', 0, 'client_expected_cash', 0)) ->> 'code'
  union all
  select 'cash_out', public.sync_push(gen_random_uuid(), 'cash_movement', 'create',
           jsonb_build_object('id', gen_random_uuid(), 'shift_id', (select id from t_ids where name = 'shift'),
                              'movement_type', 'out', 'amount', 50000, 'reason', 'Ambil uang',
                              'employee_id', p_actor, 'occurred_at', now())) ->> 'code'
  union all
  select 'stock_adjustment', public.sync_push(gen_random_uuid(), 'stock_adjustment', 'create',
           jsonb_build_object('id', gen_random_uuid(), 'store_id', tests.id('store.bks'), 'reason', 'stock_out',
                              'adjustment_number', 'ADJ-HACK-1', 'employee_id', p_actor, 'occurred_at', now(),
                              'items', jsonb_build_array(jsonb_build_object('id', gen_random_uuid(),
                                'variant_id', tests.variant('MIE-GRG-ORI'), 'quantity_delta', '-5')))) ->> 'code'
$$;

-- Store A terminal ----------------------------------------------------------------------------------
select tests.act_as(tests.id('user.device_pst'));
select is(
  (select jsonb_object_agg(what, code) from pg_temp.attempts(tests.id('emp.eko'))),
  '{"void": "store_mismatch", "mark_printed": "store_mismatch", "refund": "store_mismatch",
    "shift_close": "store_mismatch", "cash_out": "store_mismatch", "stock_adjustment": "store_mismatch"}'::jsonb,
  'the store A terminal cannot void, print, refund, close, take cash or adjust stock in store B');
select is((select count(*)::int from public.shifts where store_id = tests.id('store.bks')), 0,
  'terminal: no store B shifts');
select is((select count(*)::int from public.payments where store_id = tests.id('store.bks')), 0,
  'terminal: no store B payments');
select is((select count(*)::int from public.order_items where order_id = (select id from t_ids where name = 'order')), 0,
  'terminal: no store B order lines');
select is((select count(*)::int from public.cash_movements where store_id = tests.id('store.bks')), 0,
  'terminal: no store B petty cash');
select is((select count(*)::int from public.stock_movements where store_id = tests.id('store.bks')), 0,
  'terminal: no store B stock movements');
select is((select count(*)::int from public.alerts where store_id = tests.id('store.bks')), 0,
  'terminal: no store B alerts');
select throws_ok($$ select public.shift_summary((select id from t_ids where name = 'shift')) $$,
  'P0001', null, 'terminal: no X/Z report of a store B shift');
select is(public.sync_push(gen_random_uuid(), 'audit', 'log',
            jsonb_build_object('id', tests.uuid('150:audit:pst'), 'store_id', tests.id('store.bks'),
                               'action', 'receipt.reprinted', 'actor_employee_id', tests.id('emp.eko'))) ->> 'status',
  'applied', 'terminal: an audit entry naming store B is accepted ...');
select tests.act_as_postgres();
select is((select store_id from public.audit_log where id = tests.uuid('150:audit:pst')), tests.id('store.pst'),
  '... but it is filed under the terminal''s own store');

-- Store A cashier signed in by email ----------------------------------------------------------------
select tests.act_as(tests.id('user.cashier_pst'));
select is(
  (select jsonb_object_agg(what, code) from pg_temp.attempts(tests.id('emp.eko'))),
  '{"void": "store_forbidden", "mark_printed": "store_forbidden", "refund": "store_forbidden",
    "shift_close": "store_forbidden", "cash_out": "store_forbidden", "stock_adjustment": "store_forbidden"}'::jsonb,
  'the store A cashier cannot void, print, refund, close, take cash or adjust stock in store B');
select is(
  public.sync_push(gen_random_uuid(), 'order', 'upsert',
    tests.order_payload(gen_random_uuid(), tests.id('store.bks'), null, tests.id('emp.eko'), 'BKS-HACK-0002',
                        '[{"sku":"MIE-GRG-ORI","qty":"1"}]'::jsonb, 'open')) ->> 'code',
  'store_forbidden', 'cashier: no orders in store B');
select is(
  public.sync_push(gen_random_uuid(), 'audit', 'log',
    jsonb_build_object('store_id', tests.id('store.bks'), 'action', 'receipt.reprinted')) ->> 'code',
  'store_forbidden', 'cashier: no audit entries in store B');
select is((select count(*)::int from public.shifts where store_id = tests.id('store.bks')), 0,
  'cashier: no store B shifts');
select is((select count(*)::int from public.payments where store_id = tests.id('store.bks')), 0,
  'cashier: no store B payments');
select is((select count(*)::int from public.cash_movements where store_id = tests.id('store.bks')), 0,
  'cashier: no store B petty cash');
select is((select count(*)::int from public.refunds where store_id = tests.id('store.bks')), 0,
  'cashier: no store B refunds');
select is((select count(*)::int from public.receivables where store_id = tests.id('store.bks')), 0,
  'cashier: no store B kasbon');
select throws_ok($$ select public.shift_summary((select id from t_ids where name = 'shift')) $$,
  'P0001', null, 'cashier: no X/Z report of a store B shift');
select throws_ok($$ select * from public.shift_overview('a0000000-0000-4000-8000-000000000002'::uuid) $$,
  'P0001', null, 'cashier: no store B shift list');
select is((select count(*)::int from public.shift_overview() where store_id = tests.id('store.bks')), 0,
  'cashier: the all-stores shift list leaves store B out');

-- Direct table writes (PostgREST) by the store A cashier --------------------------------------------
select throws_ok(
  $$ insert into public.shifts (id, store_id, device_id, opened_by, opened_at, opening_cash)
     values (gen_random_uuid(), 'a0000000-0000-4000-8000-000000000002', 'd0000000-0000-4000-8000-000000000002',
             'e0000000-0000-4000-8000-000000000021', now(), 0) $$,
  '42501', null, 'cashier: cannot open a store B shift directly');
select throws_ok(
  $$ insert into public.cash_movements (id, store_id, shift_id, movement_type, amount, reason, employee_id, occurred_at)
     values (gen_random_uuid(), 'a0000000-0000-4000-8000-000000000002', (select id from t_ids where name = 'shift'),
             'out', 1, 'Ambil uang', 'e0000000-0000-4000-8000-000000000021', now()) $$,
  '42501', null, 'cashier: cannot insert petty cash directly');
select throws_ok(
  $$ insert into public.audit_log (store_id, action) values ('a0000000-0000-4000-8000-000000000002', 'pos.test') $$,
  '42501', null, 'cashier: cannot write the audit log directly');
select lives_ok(
  $$ update public.shifts set opening_cash = 0 where store_id = 'a0000000-0000-4000-8000-000000000002' $$,
  'cashier: an update of store B shifts runs ...');
select lives_ok(
  $$ update public.store_variant_settings set price_override = 1
      where store_id = 'a0000000-0000-4000-8000-000000000002' $$,
  'cashier: an update of store B prices runs ...');

-- Store A manager -----------------------------------------------------------------------------------
select tests.act_as(tests.id('user.manager_pst'));
select is((select count(*)::int from public.audit_entries() where store_name = 'CashierA Bekasi'), 0,
  'manager: the audit log leaves store B out');
select throws_ok($$ select * from public.audit_entries('a0000000-0000-4000-8000-000000000002'::uuid) $$,
  'P0001', null, 'manager: no audit log of store B');
select lives_ok(
  $$ update public.store_payment_methods set is_enabled = false
      where store_id = 'a0000000-0000-4000-8000-000000000002' $$,
  'manager: an update of store B payment methods runs ...');

-- Nothing in store B changed ------------------------------------------------------------------------
select tests.act_as_postgres();
select is((select status from public.orders where id = (select id from t_ids where name = 'order')), 'completed',
  '... and the store B sale is still completed and unprinted')
  ;
select is((select receipt_printed_at from public.orders where id = (select id from t_ids where name = 'order')), null,
  'the store B receipt was not marked printed');
select is((select (status, opening_cash)::text from public.shifts where id = (select id from t_ids where name = 'shift')),
  '(open,100000)', 'the store B shift is still open with its opening cash');
select is((select count(*)::int from public.store_variant_settings
           where store_id = tests.id('store.bks') and price_override = 1), 0,
  'store B prices are unchanged');
select is((select count(*)::int from public.store_payment_methods
           where store_id = tests.id('store.bks') and not is_enabled), 0,
  'store B payment methods are unchanged');

select * from finish();
rollback;
