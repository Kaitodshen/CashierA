-- =============================================================================
-- CashierA · 1200 · Row Level Security
--
-- Reading rules:
--   company tables  -> any active member (employee or paired terminal)
--   store tables    -> store_id in app.store_ids_with(<module permissions>)
--                      owner: all stores · staff: assigned stores · terminal: own store
-- Writing rules:
--   operational data (orders, shifts, payments, refunds, kasbon, stock) has NO
--   write policies: it only changes through validated RPCs (sync_push & co).
--   master data is written directly by staff holding the module permission.
--
-- Note: `x in (select unnest(f()))` is an uncorrelated subquery, so Postgres
-- evaluates f() once per query (not per row). Scalar helpers are wrapped as
-- `(select f())` for the same reason.
-- =============================================================================

do $$
declare
  r record;
begin
  for r in select tablename from pg_tables where schemaname = 'public' order by tablename loop
    execute format('alter table public.%I enable row level security', r.tablename);
  end loop;
end;
$$;

create or replace function app.has_any_permission(p_permissions text[])
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from unnest(p_permissions) as p(code) where app.has_permission(p.code))
$$;

-- Who may see an employee row.
create or replace function app.can_see_employee(p_employee_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    exists (select 1 from public.employees e where e.id = p_employee_id and e.auth_user_id = auth.uid())
    or app.is_owner()
    or exists (
      select 1 from public.employee_stores es
      where es.employee_id = p_employee_id and es.store_id = any (app.store_ids_with()))
    or (app.has_permission('employee.manage')
        and not exists (select 1 from public.employee_stores es where es.employee_id = p_employee_id))
    or (app.is_member() and exists (
      select 1 from public.employees e join public.roles r on r.id = e.role_id
      where e.id = p_employee_id and r.scope = 'all_stores'))
$$;

-- ---------------------------------------------------------------------------
-- Company profile, stores, settings
-- ---------------------------------------------------------------------------
create policy business_profile_select on public.business_profile
  for select to authenticated using ((select app.is_member()));
create policy business_profile_update on public.business_profile
  for update to authenticated using ((select app.is_owner())) with check ((select app.is_owner()));

create policy stores_select on public.stores
  for select to authenticated using (id in (select unnest(app.store_ids_with())));
create policy stores_insert on public.stores
  for insert to authenticated with check ((select app.is_owner()));
create policy stores_update on public.stores
  for update to authenticated using ((select app.is_owner())) with check ((select app.is_owner()));

create policy store_settings_select on public.store_settings
  for select to authenticated using (store_id in (select unnest(app.store_ids_with())));
create policy store_settings_update on public.store_settings
  for update to authenticated
  using (store_id in (select unnest(app.store_ids_with(array['settings.manage'], false))))
  with check (store_id in (select unnest(app.store_ids_with(array['settings.manage'], false))));

-- ---------------------------------------------------------------------------
-- Roles, permissions, employees, terminals
-- ---------------------------------------------------------------------------
create policy permissions_select on public.permissions
  for select to authenticated using ((select app.is_member()));

create policy roles_select on public.roles
  for select to authenticated using ((select app.is_member()));
create policy roles_insert on public.roles
  for insert to authenticated with check ((select app.is_owner()));
create policy roles_update on public.roles
  for update to authenticated using ((select app.is_owner())) with check ((select app.is_owner()));
create policy roles_delete on public.roles
  for delete to authenticated using ((select app.is_owner()));

create policy role_permissions_select on public.role_permissions
  for select to authenticated using ((select app.is_member()));
create policy role_permissions_insert on public.role_permissions
  for insert to authenticated with check ((select app.is_owner()));
create policy role_permissions_delete on public.role_permissions
  for delete to authenticated using ((select app.is_owner()));

create policy employees_select on public.employees
  for select to authenticated using (app.can_see_employee(id));
create policy employees_insert on public.employees
  for insert to authenticated with check ((select app.has_permission('employee.manage')));
create policy employees_update on public.employees
  for update to authenticated
  using (app.can_manage_employee((select app.current_employee_id()), id))
  with check (app.can_manage_employee((select app.current_employee_id()), id));

-- employee_pins: RLS on, no policies -> no client access at all.

create policy employee_stores_select on public.employee_stores
  for select to authenticated
  using (store_id in (select unnest(app.store_ids_with())) or employee_id = (select app.current_employee_id()));
create policy employee_stores_insert on public.employee_stores
  for insert to authenticated
  with check (store_id in (select unnest(app.store_ids_with(array['employee.manage'], false)))
              and app.can_manage_employee((select app.current_employee_id()), employee_id));
create policy employee_stores_delete on public.employee_stores
  for delete to authenticated
  using (store_id in (select unnest(app.store_ids_with(array['employee.manage'], false)))
         and app.can_manage_employee((select app.current_employee_id()), employee_id));

create policy devices_select on public.devices
  for select to authenticated
  using (auth_user_id = (select auth.uid())
         or store_id in (select unnest(app.store_ids_with(array['device.manage'], false))));

-- device_pairing_codes: RPC only.

-- ---------------------------------------------------------------------------
-- Company catalog (read: members; write: holders of the listed permissions)
-- ---------------------------------------------------------------------------
do $$
declare
  r record;
begin
  for r in
    select * from (values
      ('units',                  array['catalog.manage']),
      ('categories',             array['catalog.manage']),
      ('products',               array['catalog.manage']),
      ('product_variants',       array['catalog.manage']),
      ('modifier_groups',        array['catalog.manage']),
      ('modifiers',              array['catalog.manage']),
      ('product_modifier_groups',array['catalog.manage']),
      ('recipe_items',           array['catalog.manage']),
      ('modifier_recipe_items',  array['catalog.manage']),
      ('suppliers',              array['catalog.manage', 'purchase.manage']),
      ('promotions',             array['promo.manage']),
      ('promotion_stores',       array['promo.manage']),
      ('vouchers',               array['promo.manage']),
      ('expense_categories',     array['expense.manage'])
    ) as t(table_name, perms)
  loop
    execute format(
      'create policy %I on public.%I for select to authenticated using ((select app.is_member()))',
      r.table_name || '_select', r.table_name);
    execute format(
      'create policy %I on public.%I for insert to authenticated with check ((select app.has_any_permission(%L::text[])))',
      r.table_name || '_insert', r.table_name, r.perms);
    execute format(
      'create policy %I on public.%I for update to authenticated using ((select app.has_any_permission(%L::text[]))) with check ((select app.has_any_permission(%L::text[])))',
      r.table_name || '_update', r.table_name, r.perms, r.perms);
    execute format(
      'create policy %I on public.%I for delete to authenticated using ((select app.has_any_permission(%L::text[])))',
      r.table_name || '_delete', r.table_name, r.perms);
  end loop;
end;
$$;

create policy payment_methods_select on public.payment_methods
  for select to authenticated using ((select app.is_member()));
create policy payment_methods_write on public.payment_methods
  for all to authenticated using ((select app.is_owner())) with check ((select app.is_owner()));

create policy customers_select on public.customers
  for select to authenticated using ((select app.is_member()));
create policy customers_insert on public.customers
  for insert to authenticated with check ((select app.has_permission('customer.manage')));
create policy customers_update on public.customers
  for update to authenticated
  using ((select app.has_permission('customer.manage')))
  with check ((select app.has_permission('customer.manage')));

create policy loyalty_ledger_select on public.loyalty_ledger
  for select to authenticated using ((select app.is_member()));

-- ---------------------------------------------------------------------------
-- Store-scoped settings written by staff (read: anyone in the store)
-- ---------------------------------------------------------------------------
do $$
declare
  r record;
begin
  for r in
    select * from (values
      ('store_variant_settings', array['pricing.store_override']),
      ('store_favorites',        array['settings.manage']),
      ('store_payment_methods',  array['settings.manage']),
      ('dining_tables',          array['settings.manage']),
      ('printers',               array['settings.manage'])
    ) as t(table_name, perms)
  loop
    execute format(
      'create policy %I on public.%I for select to authenticated using (store_id in (select unnest(app.store_ids_with())))',
      r.table_name || '_select', r.table_name);
    execute format(
      'create policy %I on public.%I for insert to authenticated with check (store_id in (select unnest(app.store_ids_with(%L::text[], false))))',
      r.table_name || '_insert', r.table_name, r.perms);
    execute format(
      'create policy %I on public.%I for update to authenticated using (store_id in (select unnest(app.store_ids_with(%L::text[], false)))) with check (store_id in (select unnest(app.store_ids_with(%L::text[], false))))',
      r.table_name || '_update', r.table_name, r.perms, r.perms);
    execute format(
      'create policy %I on public.%I for delete to authenticated using (store_id in (select unnest(app.store_ids_with(%L::text[], false))))',
      r.table_name || '_delete', r.table_name, r.perms);
  end loop;
end;
$$;

-- ---------------------------------------------------------------------------
-- Store-scoped operational data: read-only for clients (RPCs write it)
-- ---------------------------------------------------------------------------
do $$
declare
  r record;
begin
  for r in
    select * from (values
      ('shifts',                 array['shift.manage', 'reports.view'],                        true),
      ('cash_movements',         array['shift.manage', 'reports.view'],                        true),
      ('orders',                 array['pos.sell', 'reports.view', 'kitchen.view'],            true),
      ('order_items',            array['pos.sell', 'reports.view', 'kitchen.view'],            true),
      ('order_item_modifiers',   array['pos.sell', 'reports.view', 'kitchen.view'],            true),
      ('order_discounts',        array['pos.sell', 'reports.view'],                            true),
      ('payments',               array['pos.sell', 'reports.view'],                            true),
      ('refunds',                array['pos.sell', 'reports.view'],                            true),
      ('refund_items',           array['pos.sell', 'reports.view'],                            true),
      ('receivables',            array['kasbon.manage', 'reports.view'],                       true),
      ('receivable_payments',    array['kasbon.manage', 'reports.view'],                       true),
      ('voucher_redemptions',    array['pos.sell', 'reports.view'],                            true),
      ('order_status',           array['pos.sell', 'kitchen.view', 'reports.view'],            true),
      ('stock_levels',           array['inventory.view', 'pos.sell', 'reports.view'],          true),
      ('stock_movements',        array['inventory.view', 'reports.view'],                      true),
      ('stock_adjustments',      array['inventory.view', 'reports.view'],                      true),
      ('stock_adjustment_items', array['inventory.view', 'reports.view'],                      true),
      ('stock_opnames',          array['inventory.view', 'inventory.opname', 'reports.view'],  true),
      ('stock_opname_items',     array['inventory.view', 'inventory.opname', 'reports.view'],  true),
      ('purchase_orders',        array['purchase.manage', 'inventory.view', 'reports.view'],   true),
      ('goods_receipts',         array['inventory.receive', 'inventory.view', 'reports.view'], true),
      ('goods_receipt_items',    array['inventory.receive', 'inventory.view', 'reports.view'], true),
      ('expenses',               array['expense.manage', 'reports.view'],                      false)
    ) as t(table_name, perms, allow_device)
  loop
    execute format(
      'create policy %I on public.%I for select to authenticated using (store_id in (select unnest(app.store_ids_with(%L::text[], %L))))',
      r.table_name || '_select', r.table_name, r.perms, r.allow_device);
  end loop;
end;
$$;

-- Kitchen display in the back office may update ticket status directly.
create policy order_status_update on public.order_status
  for update to authenticated
  using (store_id in (select unnest(app.store_ids_with(array['kitchen.view'], false))))
  with check (store_id in (select unnest(app.store_ids_with(array['kitchen.view'], false))));

-- Stock opname drafts are edited directly; completion goes through complete_stock_opname().
create policy stock_opnames_insert on public.stock_opnames
  for insert to authenticated
  with check (store_id in (select unnest(app.store_ids_with(array['inventory.opname'], false))) and status = 'draft');
create policy stock_opnames_update on public.stock_opnames
  for update to authenticated
  using (store_id in (select unnest(app.store_ids_with(array['inventory.opname'], false))) and status = 'draft')
  with check (store_id in (select unnest(app.store_ids_with(array['inventory.opname'], false)))
              and status in ('draft', 'cancelled'));
create policy stock_opname_items_insert on public.stock_opname_items
  for insert to authenticated
  with check (store_id in (select unnest(app.store_ids_with(array['inventory.opname'], false))));
create policy stock_opname_items_update on public.stock_opname_items
  for update to authenticated
  using (store_id in (select unnest(app.store_ids_with(array['inventory.opname'], false))))
  with check (store_id in (select unnest(app.store_ids_with(array['inventory.opname'], false))));
create policy stock_opname_items_delete on public.stock_opname_items
  for delete to authenticated
  using (store_id in (select unnest(app.store_ids_with(array['inventory.opname'], false))));

-- Purchase orders (back office).
create policy purchase_orders_insert on public.purchase_orders
  for insert to authenticated
  with check (store_id in (select unnest(app.store_ids_with(array['purchase.manage'], false)))
              and status in ('draft', 'ordered'));
create policy purchase_orders_update on public.purchase_orders
  for update to authenticated
  using (store_id in (select unnest(app.store_ids_with(array['purchase.manage'], false)))
         and status in ('draft', 'ordered', 'partially_received'))
  with check (store_id in (select unnest(app.store_ids_with(array['purchase.manage'], false)))
              and status in ('draft', 'ordered', 'partially_received', 'cancelled'));

create policy purchase_order_items_select on public.purchase_order_items
  for select to authenticated
  using (exists (
    select 1 from public.purchase_orders po
    where po.id = purchase_order_id
      and po.store_id in (select unnest(app.store_ids_with(array['purchase.manage', 'inventory.view', 'reports.view'])))));
create policy purchase_order_items_insert on public.purchase_order_items
  for insert to authenticated
  with check (exists (
    select 1 from public.purchase_orders po
    where po.id = purchase_order_id and po.status in ('draft', 'ordered')
      and po.store_id in (select unnest(app.store_ids_with(array['purchase.manage'], false)))));
create policy purchase_order_items_update on public.purchase_order_items
  for update to authenticated
  using (exists (
    select 1 from public.purchase_orders po
    where po.id = purchase_order_id and po.status in ('draft', 'ordered')
      and po.store_id in (select unnest(app.store_ids_with(array['purchase.manage'], false)))))
  with check (exists (
    select 1 from public.purchase_orders po
    where po.id = purchase_order_id and po.status in ('draft', 'ordered')
      and po.store_id in (select unnest(app.store_ids_with(array['purchase.manage'], false)))));
create policy purchase_order_items_delete on public.purchase_order_items
  for delete to authenticated
  using (exists (
    select 1 from public.purchase_orders po
    where po.id = purchase_order_id and po.status = 'draft'
      and po.store_id in (select unnest(app.store_ids_with(array['purchase.manage'], false)))));

-- Goods receipts are inserted directly; triggers apply stock and cost.
create policy goods_receipts_insert on public.goods_receipts
  for insert to authenticated
  with check (store_id in (select unnest(app.store_ids_with(array['inventory.receive'], false))));
create policy goods_receipt_items_insert on public.goods_receipt_items
  for insert to authenticated
  with check (store_id in (select unnest(app.store_ids_with(array['inventory.receive'], false))));

-- Transfers are visible to both stores; they change only through the transfer RPCs.
create policy stock_transfers_select on public.stock_transfers
  for select to authenticated
  using (from_store_id in (select unnest(app.store_ids_with(array['inventory.view', 'transfer.request', 'transfer.approve', 'reports.view'])))
         or to_store_id in (select unnest(app.store_ids_with(array['inventory.view', 'transfer.request', 'transfer.approve', 'reports.view']))));
create policy stock_transfer_items_select on public.stock_transfer_items
  for select to authenticated
  using (exists (
    select 1 from public.stock_transfers t
    where t.id = transfer_id
      and (t.from_store_id in (select unnest(app.store_ids_with(array['inventory.view', 'transfer.request', 'transfer.approve', 'reports.view'])))
           or t.to_store_id in (select unnest(app.store_ids_with(array['inventory.view', 'transfer.request', 'transfer.approve', 'reports.view']))))));

-- Alerts: store staff with inventory or report access see them; managers resolve them.
create policy alerts_select on public.alerts
  for select to authenticated
  using (store_id in (select unnest(app.store_ids_with(array['inventory.view', 'reports.view'])))
         or (store_id is null and (select app.is_owner())));
create policy alerts_update on public.alerts
  for update to authenticated
  using (store_id in (select unnest(app.store_ids_with(array['reports.view'], false)))
         or (store_id is null and (select app.is_owner())))
  with check (store_id in (select unnest(app.store_ids_with(array['reports.view'], false)))
              or (store_id is null and (select app.is_owner())));

-- Expenses (back office).
create policy expenses_insert on public.expenses
  for insert to authenticated
  with check (store_id in (select unnest(app.store_ids_with(array['expense.manage'], false))));
create policy expenses_update on public.expenses
  for update to authenticated
  using (store_id in (select unnest(app.store_ids_with(array['expense.manage'], false))))
  with check (store_id in (select unnest(app.store_ids_with(array['expense.manage'], false))));

-- ---------------------------------------------------------------------------
-- Audit and sync
-- ---------------------------------------------------------------------------
create policy audit_log_select on public.audit_log
  for select to authenticated
  using (store_id in (select unnest(app.store_ids_with(array['audit.view'], false)))
         or (store_id is null and (select app.is_owner())));

-- sync_inbox: no client access.
create policy sync_rejections_select on public.sync_rejections
  for select to authenticated using ((select app.is_owner()));

create policy sync_tombstones_select on public.sync_tombstones
  for select to authenticated
  using ((select app.is_member()) and (store_id is null or store_id in (select unnest(app.store_ids_with()))));
