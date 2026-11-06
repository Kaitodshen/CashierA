-- Phase 5 review fixes: approvals naming someone else only from a paired
-- terminal; payments only on completed orders; expected cash counts only
-- completed and voided sales.
begin;
create extension if not exists pgtap with schema extensions;
select plan(8);

create or replace function pg_temp.refund(p_seed text, p_by uuid, p_approver uuid)
returns jsonb language sql as $$
  select public.sync_push(gen_random_uuid(), 'refund', 'create',
    jsonb_build_object('id', tests.uuid('170:refund:' || p_seed), 'order_id', tests.uuid('170:order'),
      'refund_number', 'R-170-' || p_seed, 'reason', 'Kemasan sobek', 'amount', 3500,
      'method_type', 'cash', 'restock', false, 'employee_id', p_by, 'approved_by', p_approver,
      'shift_id', tests.uuid('170:shift'),
      'items', jsonb_build_array(jsonb_build_object('id', tests.uuid('170:item:' || p_seed),
        'order_item_id', md5(tests.uuid('170:order')::text || ':item:1')::uuid, 'quantity', '1', 'amount', 3500))))
$$;

select tests.act_as(tests.id('user.device_pst'));
select tests.open_shift('170:shift', tests.id('store.pst'), tests.id('emp.eko'), 100000);
select is(public.sync_push(gen_random_uuid(), 'order', 'upsert',
  tests.order_payload(tests.uuid('170:order'), tests.id('store.pst'), tests.uuid('170:shift'), tests.id('emp.eko'),
    'PST-T1-261107-1701', '[{"sku":"MIE-GRG-ORI","qty":"4"}]'::jsonb, 'completed', 1,
    '{"payments":[{"method":"cash","tendered":20000}]}'::jsonb)) ->> 'status', 'applied', 'a cash sale of Rp 14.000');

-- Approvals ----------------------------------------------------------------------------------
select tests.act_as(tests.id('user.cashier_pst'));
select is(pg_temp.refund('a', tests.id('emp.eko'), tests.id('emp.budi')) ->> 'code',
  'approval_requires_terminal', 'a cashier signed in by email cannot name the manager as approver');
select tests.act_as(tests.id('user.manager_pst'));
select is(pg_temp.refund('b', tests.id('emp.budi'), tests.id('emp.budi')) ->> 'status',
  'applied', 'a manager signed in by email approves their own refund');
select tests.act_as(tests.id('user.device_pst'));
select is(pg_temp.refund('c', tests.id('emp.eko'), tests.id('emp.budi')) ->> 'status',
  'applied', 'on the terminal (PIN checked there) the manager approves the cashier''s refund');

-- Payments and expected cash -------------------------------------------------------------------
select is(public.sync_push(gen_random_uuid(), 'order', 'upsert',
  tests.order_payload(tests.uuid('170:held'), tests.id('store.pst'), tests.uuid('170:shift'), tests.id('emp.eko'),
    'PST-T1-261107-1702', '[{"sku":"MIE-GRG-ORI","qty":"10"}]'::jsonb, 'held', 1,
    '{"payments":[{"method":"cash","tendered":35000}]}'::jsonb)) ->> 'code',
  'payments_require_completion', 'a held order cannot carry a payment');
select is(public.sync_push(gen_random_uuid(), 'order', 'upsert',
  tests.order_payload(tests.uuid('170:held'), tests.id('store.pst'), tests.uuid('170:shift'), tests.id('emp.eko'),
    'PST-T1-261107-1702', '[{"sku":"MIE-GRG-ORI","qty":"10"}]'::jsonb, 'held')) ->> 'status',
  'applied', 'without payments it is held');

-- A payment row that reached a held order some other way is not drawer cash.
select tests.act_as_postgres();
insert into public.payments (id, order_id, store_id, shift_id, payment_method_id, method_type, amount, tendered_amount, status, paid_at)
select gen_random_uuid(), tests.uuid('170:held'), tests.id('store.pst'), tests.uuid('170:shift'), pm.id, 'cash', 35000,
35000, 'paid', now()
from public.payment_methods pm where pm.code = 'cash';
select tests.act_as(tests.id('user.device_pst'));
select is(app.shift_expected_cash(tests.uuid('170:shift')), (100000 + 14000 - 3500 - 3500)::bigint,
  'expected cash leaves out the held order''s payment');
select is((public.shift_summary(tests.uuid('170:shift')) -> 'cash' ->> 'cash_sales')::bigint, 14000::bigint,
  'the X report''s cash sales leave it out too');

select * from finish();
rollback;
