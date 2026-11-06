-- Row level security: terminals, cashiers and managers only see their store;
-- owners see all; unpaired, revoked and anon callers see nothing.
begin;
create extension if not exists pgtap with schema extensions;
select plan(32);

-- Fixtures (as the database owner, RLS bypassed)
insert into public.orders (id, store_id, order_number, cashier_id, ordered_at) values
  (tests.uuid('010:order:pst'), tests.id('store.pst'), 'PST-RLS-0001', tests.id('emp.eko'),    now()),
  (tests.uuid('010:order:bks'), tests.id('store.bks'), 'BKS-RLS-0001', tests.id('emp.gilang'), now());

insert into auth.users (id, aud, role, is_anonymous, created_at, updated_at) values
  (tests.uuid('010:anon'),    'authenticated', 'authenticated', true, now(), now()),
  (tests.uuid('010:revoked'), 'authenticated', 'authenticated', true, now(), now());
insert into public.devices (id, store_id, auth_user_id, code, name, is_active, revoked_at)
values (tests.uuid('010:revoked-device'), tests.id('store.pst'), tests.uuid('010:revoked'), 'T9', 'Old tablet', false, now());

-- Terminal at PST ------------------------------------------------------------------
select tests.act_as(tests.id('user.device_pst'));

select is((select count(*)::int from public.orders where id = tests.uuid('010:order:pst')), 1,
  'terminal sees its own store''s orders');
select is((select count(*)::int from public.orders where id = tests.uuid('010:order:bks')), 0,
  'terminal cannot see another store''s orders');
select is((select array_agg(code order by code) from public.stores), array['PST'],
  'terminal sees only its own store');
select is((select count(*)::int from public.stock_levels where store_id <> tests.id('store.pst')), 0,
  'terminal sees no stock of other stores');
select ok((select count(*) from public.stock_levels) > 0,
  'terminal sees its own stock levels');
select ok((select count(*) from public.product_variants) >= 46,
  'terminal reads the company catalog');
select ok((select count(*) from public.customers) > 0,
  'terminal reads company-wide customers');
select is((select count(*)::int from public.employee_pins), 0,
  'PIN hashes are never readable directly');
select is((select count(*)::int from public.audit_log), 0,
  'terminals cannot read the audit log');
select is((select count(*)::int from public.expenses), 0,
  'terminals cannot read expenses');
select throws_ok(
  $$insert into public.orders (id, store_id, order_number, cashier_id, ordered_at)
    values (gen_random_uuid(), tests.id('store.pst'), 'PST-HACK-0001', tests.id('emp.eko'), now())$$,
  '42501', null,
  'terminals cannot insert orders directly (only through sync_push)');
select lives_ok(
  $$update public.stock_levels set quantity = 999 where store_id = tests.id('store.pst')$$,
  'a direct stock update is silently filtered out');
select is((select count(*)::int from public.stock_levels where quantity = 999), 0,
  'terminals cannot change stock directly');
select is(
  public.sync_push(gen_random_uuid(), 'order', 'upsert',
    tests.order_payload(gen_random_uuid(), tests.id('store.bks'), null, tests.id('emp.gilang'), 'BKS-HACK-0001',
                        '[{"sku":"MNM-AIR-600","qty":"1"}]'::jsonb, 'open')) ->> 'code',
  'store_mismatch',
  'a terminal cannot write orders for another store');

-- Terminal at BKS --------------------------------------------------------------------
select tests.act_as(tests.id('user.device_bks'));
select is(
  (select array_agg(order_number) from public.orders
   where id in (tests.uuid('010:order:pst'), tests.uuid('010:order:bks'))),
  array['BKS-RLS-0001'],
  'BKS terminal sees exactly its own order');

-- Cashier with an email login at PST ---------------------------------------------------
select tests.act_as(tests.id('user.cashier_pst'));
select is((select count(*)::int from public.orders where id = tests.uuid('010:order:bks')), 0,
  'cashier of store A cannot read store B orders');
select is((select count(*)::int from public.orders where id = tests.uuid('010:order:pst')), 1,
  'cashier reads their own store''s orders');
select is((select array_agg(code order by code) from public.stores), array['PST'],
  'cashier sees only their store');
select is((select count(*)::int from public.employees where id = tests.id('emp.gilang')), 0,
  'cashier cannot see staff of another store');
select is((select count(*)::int from public.expenses), 0,
  'cashiers cannot read expenses');
select is((select count(*)::int from public.stock_movements), 0,
  'cashiers cannot read stock movements without inventory.view');

-- Manager at PST ------------------------------------------------------------------------
select tests.act_as(tests.id('user.manager_pst'));
select is((select count(*)::int from public.orders where id = tests.uuid('010:order:bks')), 0,
  'manager of store A cannot read store B orders');
select ok((select count(*) from public.expenses where store_id = tests.id('store.pst')) > 0,
  'manager reads their store''s expenses');
select is((select count(*)::int from public.expenses where store_id <> tests.id('store.pst')), 0,
  'manager cannot read other stores'' expenses');
select ok((select count(*) from public.audit_log where store_id = tests.id('store.pst')) > 0,
  'manager reads their store''s audit log');
select lives_ok(
  $$update public.store_settings set receipt_footer = 'diretas' where store_id = tests.id('store.bks')$$,
  'an update aimed at another store is filtered out');
select tests.act_as_postgres();
select isnt((select receipt_footer from public.store_settings where store_id = tests.id('store.bks')), 'diretas',
  'manager cannot change another store''s settings');

-- Owner -------------------------------------------------------------------------------------
select tests.act_as(tests.id('user.owner'));
select is(
  (select count(*)::int from public.orders where id in (tests.uuid('010:order:pst'), tests.uuid('010:order:bks'))),
  2,
  'owner sees every store');

-- Unpaired anonymous sign-in -------------------------------------------------------------------
select tests.act_as(tests.uuid('010:anon'));
select is(
  (select count(*)::int from public.stores) + (select count(*)::int from public.products)
    + (select count(*)::int from public.customers),
  0,
  'an unpaired anonymous sign-in sees nothing');
select is(
  public.sync_push(gen_random_uuid(), 'audit', 'log', '{"action":"pos.test"}'::jsonb) ->> 'code',
  'not_a_member',
  'an unpaired sign-in cannot sync');

-- Revoked terminal --------------------------------------------------------------------------------
select tests.act_as(tests.uuid('010:revoked'));
select is((select count(*)::int from public.stores), 0,
  'a revoked terminal loses access immediately');

-- Not signed in at all ------------------------------------------------------------------------------
select tests.act_as_postgres();
set local role anon;
select throws_ok('select count(*) from public.stores', '42501', null,
  'the anon role cannot read any table');
reset role;

select * from finish();
rollback;
