-- Audit log immutability, change auditing, role/owner protections, closed
-- orders frozen, append-only stock history, promotion rule validation,
-- tombstones for terminal sync.
begin;
create extension if not exists pgtap with schema extensions;
select plan(21);

-- Audit log ------------------------------------------------------------------------------------
select throws_like($$update public.audit_log set action = 'x.y' where true$$,
  '%audit_log_immutable%', 'audit entries cannot be edited, not even by the database owner');
select throws_like($$delete from public.audit_log$$,
  '%audit_log_immutable%', 'audit entries cannot be deleted');

update public.product_variants set price = 4200 where sku = 'MNM-AIR-600';
select is(
  (select (details -> 'changes' -> 'price' ->> 'new')::bigint from public.audit_log
   where action = 'data.update' and entity_type = 'product_variants' and entity_id = tests.variant('MNM-AIR-600')),
  4200::bigint, 'price changes are recorded with old and new values');

-- Staff management guards -------------------------------------------------------------------------
select tests.act_as(tests.id('user.manager_pst'));
select throws_like(
  $$insert into public.employees (full_name, role_id) values ('Pemilik Palsu', (select id from public.roles where code = 'owner'))$$,
  'owner_only%', 'managers cannot create owners');
select lives_ok(
  $$insert into public.employees (id, full_name, role_id)
    values (tests.uuid('090:new-cashier'), 'Kasir Baru', (select id from public.roles where code = 'cashier'))$$,
  'managers can add a cashier');
select lives_ok(
  $$insert into public.employee_stores (employee_id, store_id) values (tests.uuid('090:new-cashier'), tests.id('store.pst'))$$,
  'and assign them to their own store');
select throws_ok(
  $$insert into public.employee_stores (employee_id, store_id) values (tests.uuid('090:new-cashier'), tests.id('store.bks'))$$,
  '42501', null, 'but not to another store');

select tests.act_as(tests.id('user.owner'));
select throws_like($$update public.employees set is_active = false where id = tests.id('emp.owner')$$,
  'last_owner%', 'the last owner cannot be deactivated');
select throws_like($$update public.roles set scope = 'assigned_stores' where code = 'owner'$$,
  'role_protected%', 'the owner role cannot be re-scoped');
select throws_like(
  $$delete from public.role_permissions
    where role_id = (select id from public.roles where code = 'owner') and permission_code = 'pos.refund'$$,
  'role_protected%', 'owner permissions cannot be removed');
select lives_ok(
  $$delete from public.role_permissions
    where role_id = (select id from public.roles where code = 'cashier') and permission_code = 'pos.void'$$,
  'owners can edit other roles'' permissions');
select tests.act_as_postgres();
select is(app.employee_has_permission(tests.id('emp.eko'), 'pos.void'), false,
  'a permission change takes effect immediately');

-- Closed orders are frozen ------------------------------------------------------------------------------
create temporary table t_payload (payload jsonb not null);
grant select on t_payload to authenticated;
insert into t_payload values (tests.order_payload(tests.uuid('090:order'), tests.id('store.pst'), tests.uuid('090:shift'),
  tests.id('emp.eko'), 'PST-T1-261105-0601', '[{"sku":"MNM-TEH-350","qty":"2"}]'::jsonb));

select tests.act_as(tests.id('user.device_pst'));
select tests.open_shift('090:shift', tests.id('store.pst'), tests.id('emp.eko'), 0);
select is(public.sync_push(tests.uuid('090:push'), 'order', 'upsert', (select payload from t_payload)) ->> 'status',
  'applied', 'a completed sale to test against');
select tests.act_as_postgres();
select throws_like($$update public.orders set grand_total = 1 where id = tests.uuid('090:order')$$,
  'order_immutable%', 'a completed order''s money cannot be edited, even by the database owner');
select throws_like($$update public.order_items set note = 'diubah' where order_id = tests.uuid('090:order')$$,
  'order_immutable%', 'its lines cannot be edited');
select throws_like($$delete from public.stock_movements where reference_id = tests.uuid('090:order')$$,
  'immutable%', 'stock history is append-only');
select throws_like($$update public.orders set status = 'open' where id = tests.uuid('090:order')$$,
  'order_invalid_transition%', 'a completed order cannot be reopened');

-- Promotion rules ----------------------------------------------------------------------------------------
select throws_ok(
  $$insert into public.promotions (name, promo_type, rules) values ('Rusak', 'tiered_qty',
    '{"scope":{"all":true},"tiers":[{"min_quantity":5,"discount":{"type":"percent","bps":500}},{"min_quantity":3,"discount":{"type":"percent","bps":900}}]}')$$,
  '23514', null, 'promotion rules are validated (tiers must ascend)');
select lives_ok(
  $$insert into public.promotions (name, promo_type, rules) values ('Valid', 'min_purchase',
    '{"min_subtotal":100000,"discount":{"type":"fixed","amount":5000}}')$$,
  'a valid promotion is accepted');

-- Tombstones and audit of terminal events ------------------------------------------------------------------
insert into public.categories (id, name) values (tests.uuid('090:category'), 'Kategori Sementara');
delete from public.categories where id = tests.uuid('090:category');
select is(
  (select row_pk ->> 'id' from public.sync_tombstones where table_name = 'categories' order by id desc limit 1),
  tests.uuid('090:category')::text, 'a delete leaves a tombstone so terminals can remove the row');
select is(
  (select count(*)::int from public.audit_log where action = 'shift.opened' and entity_id = tests.uuid('090:shift')),
  1, 'opening a shift is in the audit log');

select * from finish();
rollback;
