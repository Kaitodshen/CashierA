-- Voids after print need a manager PIN; refunds need approval, restock, and
-- reverse loyalty points; voided and refunded cash leaves the drawer.
begin;
create extension if not exists pgtap with schema extensions;
select plan(19);

create temporary table t_stock as
select variant_id, quantity from public.stock_levels where store_id = tests.id('store.pst');

create temporary table t_payload (name text primary key, payload jsonb not null);
grant select on t_payload to authenticated;
insert into t_payload values
  -- Order A: Cokelat Batang Rp 12.000 + gift paper Rp 5.000 = Rp 17.000, customer Rudi earns 1 point
  ('a', tests.order_payload(tests.uuid('040:order:a'), tests.id('store.pst'), tests.uuid('040:shift'), tests.id('emp.eko'),
     'PST-T1-261105-0201',
     jsonb_build_array(jsonb_build_object('sku', 'SNK-CKL-60', 'qty', '1', 'modifiers', jsonb_build_array(
       jsonb_build_object('modifier_id', md5('cashiera:modifier:gift-paper')::uuid, 'group_name', 'Bungkus Kado',
                          'modifier_name', 'Kertas Kado', 'price_delta', 5000)))),
     'completed', 1,
     jsonb_build_object('customer_id', tests.customer(2),
                        'payments', jsonb_build_array(jsonb_build_object('method', 'cash', 'tendered', 20000))))),
  -- Order B: 6 x Jus Jeruk Rp 21.000 = Rp 126.000, customer Maya earns 12 points
  ('b', tests.order_payload(tests.uuid('040:order:b'), tests.id('store.pst'), tests.uuid('040:shift'), tests.id('emp.eko'),
     'PST-T1-261105-0202', '[{"sku":"MNM-JUS-1L","qty":"6"}]'::jsonb, 'completed', 1,
     jsonb_build_object('customer_id', tests.customer(3),
                        'payments', jsonb_build_array(jsonb_build_object('method', 'cash', 'tendered', 130000)))));

create or replace function pg_temp.refund(p_seed text, p_qty text, p_amount bigint, p_approver uuid)
returns jsonb language sql as $$
  select jsonb_build_object(
    'id', tests.uuid('040:refund:' || p_seed), 'order_id', tests.uuid('040:order:b'),
    'refund_number', 'RF-PST-' || p_seed, 'reason', 'Kemasan rusak', 'amount', p_amount,
    'method_type', 'cash', 'restock', true, 'employee_id', tests.id('emp.eko'), 'approved_by', p_approver,
    'shift_id', tests.uuid('040:shift'),
    'items', jsonb_build_array(jsonb_build_object(
      'id', tests.uuid('040:refund-item:' || p_seed),
      'order_item_id', md5(tests.uuid('040:order:b')::text || ':item:1')::uuid,
      'quantity', p_qty, 'amount', p_amount)))
$$;

create or replace function pg_temp.void(p_approver uuid, p_order text default 'a')
returns jsonb language sql as $$
  select jsonb_build_object('order_id', tests.uuid('040:order:' || p_order), 'voided_by', tests.id('emp.eko'),
                            'approved_by', p_approver, 'reason', 'Salah input', 'shift_id', tests.uuid('040:shift'))
$$;

select tests.act_as(tests.id('user.device_pst'));
select tests.open_shift('040:shift', tests.id('store.pst'), tests.id('emp.eko'), 500000);

-- Void ------------------------------------------------------------------------------------
select is(
  public.sync_push(tests.uuid('040:push:a'), 'order', 'upsert', (select payload from t_payload where name = 'a')) ->> 'status',
  'applied', 'a sale with a gift-wrap modifier is applied');
select is(
  public.sync_push(tests.uuid('040:push:printed'), 'order', 'mark_printed',
    jsonb_build_object('order_id', tests.uuid('040:order:a'), 'printed_at', now())) ->> 'status',
  'applied', 'the receipt is marked as printed');
select is(
  public.sync_push(tests.uuid('040:push:void1'), 'order', 'void', pg_temp.void(null)) ->> 'code',
  'approval_required', 'voiding a printed receipt needs a manager PIN');
select is(
  public.sync_push(tests.uuid('040:push:void2'), 'order', 'void', pg_temp.void(tests.id('emp.eko'))) ->> 'code',
  'approval_denied', 'a cashier cannot approve their own void');
select is(
  public.sync_push(tests.uuid('040:push:void3'), 'order', 'void', pg_temp.void(tests.id('emp.budi'))) ->> 'status',
  'applied', 'the manager''s approval voids the order');

select tests.act_as_postgres();
select is((select status from public.orders where id = tests.uuid('040:order:a')), 'voided',
  'the order is voided');
select is(
  (select quantity from public.stock_levels where store_id = tests.id('store.pst') and variant_id = tests.variant('SNK-CKL-60')),
  (select quantity from t_stock where variant_id = tests.variant('SNK-CKL-60')),
  'voided stock is back on the shelf');
select is((select points_balance from public.customers where id = tests.customer(2)), 45,
  'points from the voided sale are taken back');
select is(
  (select count(*)::int from public.audit_log
   where action = 'order.voided' and entity_id = tests.uuid('040:order:a') and approver_employee_id = tests.id('emp.budi')),
  1, 'the void is audited with the approving manager');

-- Refunds -----------------------------------------------------------------------------------
select tests.act_as(tests.id('user.device_pst'));
select is(
  public.sync_push(tests.uuid('040:push:b'), 'order', 'upsert', (select payload from t_payload where name = 'b')) ->> 'status',
  'applied', 'a second sale is applied');
select is(
  public.sync_push(tests.uuid('040:push:r0'), 'refund', 'create', pg_temp.refund('0', '3', 63000, null)) ->> 'code',
  'approval_required', 'refunds need a manager PIN');
select is(
  public.sync_push(tests.uuid('040:push:r1'), 'refund', 'create', pg_temp.refund('1', '3', 63000, tests.id('emp.budi')))
    -> 'result' ->> 'points_reversed',
  '6', 'refunding half reverses 6 of the 12 points');
select is(
  public.sync_push(tests.uuid('040:push:r2'), 'refund', 'create', pg_temp.refund('2', '4', 63000, tests.id('emp.budi'))) ->> 'code',
  'refund_quantity_exceeded', 'cannot refund more units than were sold');
select is(
  public.sync_push(tests.uuid('040:push:void-b'), 'order', 'void', pg_temp.void(tests.id('emp.budi'), 'b')) ->> 'code',
  'void_after_refund', 'an order with refunds cannot be voided');
select is(
  public.sync_push(tests.uuid('040:push:r3'), 'refund', 'create', pg_temp.refund('3', '3', 63000, tests.id('emp.budi'))) ->> 'status',
  'applied', 'the rest of the order is refunded');

select tests.act_as_postgres();
select is((select refunded_total from public.orders where id = tests.uuid('040:order:b')), 126000::bigint,
  'refunded total equals the bill');
select is(
  (select quantity from public.stock_levels where store_id = tests.id('store.pst') and variant_id = tests.variant('MNM-JUS-1L')),
  (select quantity from t_stock where variant_id = tests.variant('MNM-JUS-1L')),
  'refunded items are restocked');
select is((select points_balance from public.customers where id = tests.customer(3)), 300,
  'all earned points are reversed after a full refund');
select is(app.shift_expected_cash(tests.uuid('040:shift')), 500000::bigint,
  'expected cash: voided and refunded cash left the drawer again');

select * from finish();
rollback;
