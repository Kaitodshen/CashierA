-- =============================================================================
-- CashierA · 0900 · Audit log, sync infrastructure, shared triggers
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Audit log: append-only. No foreign keys on purpose (a log must outlive rows).
-- ---------------------------------------------------------------------------
create table public.audit_log (
  id uuid primary key default gen_random_uuid(),
  occurred_at timestamptz not null default now(),
  received_at timestamptz not null default now(),
  store_id uuid,
  device_id uuid,
  auth_user_id uuid default auth.uid(),
  actor_employee_id uuid,
  approver_employee_id uuid,
  action text not null check (action ~ '^[a-z]+(_[a-z]+)*(\.[a-z]+(_[a-z]+)*)+$'),
  entity_type text,
  entity_id uuid,
  details jsonb not null default '{}'::jsonb
);
create index audit_log_store_occurred_idx on public.audit_log (store_id, occurred_at desc);
create index audit_log_action_idx on public.audit_log (action, occurred_at desc);
create index audit_log_entity_idx on public.audit_log (entity_type, entity_id);
comment on table public.audit_log is
  'Who did what, when, where, on which terminal. data.* rows come from triggers; others from RPCs and terminals.';

create or replace function app.audit_log_immutable()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  raise exception using
    errcode = 'P0001',
    message = 'audit_log_immutable: audit entries cannot be changed or deleted',
    hint = 'audit_log_immutable';
end;
$$;

create trigger audit_log_no_update_delete
before update or delete on public.audit_log
for each row execute function app.audit_log_immutable();

create trigger audit_log_no_truncate
before truncate on public.audit_log
for each statement execute function app.audit_log_immutable();

-- Generic change audit for sensitive master data (prices, staff, roles, settings...).
create or replace function app.audit_row_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_old jsonb := case when tg_op in ('UPDATE', 'DELETE') then to_jsonb(old) end;
  v_new jsonb := case when tg_op in ('INSERT', 'UPDATE') then to_jsonb(new) end;
  v_row jsonb;
  v_changes jsonb := '{}'::jsonb;
  v_key text;
begin
  v_row := coalesce(v_new, v_old);
  if tg_op = 'UPDATE' then
    for v_key in select jsonb_object_keys(v_new) loop
      -- Heartbeat columns change on every sync; they are not worth an audit row.
      if v_key not in ('updated_at', 'last_seen_at', 'app_version')
         and (v_new -> v_key) is distinct from (v_old -> v_key) then
        v_changes := v_changes || jsonb_build_object(
          v_key, jsonb_build_object('old', v_old -> v_key, 'new', v_new -> v_key));
      end if;
    end loop;
    if v_changes = '{}'::jsonb then
      return new;
    end if;
  end if;

  insert into public.audit_log (store_id, device_id, actor_employee_id, action, entity_type, entity_id, details)
  values (
    case when v_row ? 'store_id' then (v_row ->> 'store_id')::uuid end,
    app.current_device_id(),
    app.current_employee_id(),
    'data.' || lower(tg_op),
    tg_table_name,
    case when (v_row ->> 'id') ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
         then (v_row ->> 'id')::uuid end,
    case tg_op
      when 'UPDATE' then jsonb_build_object('changes', v_changes)
      when 'INSERT' then jsonb_build_object('new', v_new)
      else jsonb_build_object('old', v_old)
    end
  );
  return coalesce(new, old);
end;
$$;

-- ---------------------------------------------------------------------------
-- Sync: idempotency inbox, rejection log, deletion tombstones
-- ---------------------------------------------------------------------------
create table public.sync_inbox (
  client_uuid uuid primary key,
  device_id uuid,
  auth_user_id uuid,
  entity text not null,
  action text not null,
  result jsonb not null default '{}'::jsonb,
  received_at timestamptz not null default now()
);
create index sync_inbox_device_idx on public.sync_inbox (device_id, received_at desc);
comment on table public.sync_inbox is
  'Every applied sync_push call. Replaying a client_uuid returns the stored result instead of re-applying.';

create table public.sync_rejections (
  id bigint generated always as identity primary key,
  client_uuid uuid not null,
  device_id uuid,
  auth_user_id uuid,
  entity text not null,
  action text not null,
  error_code text not null,
  error_message text not null,
  payload jsonb not null,
  received_at timestamptz not null default now()
);
create index sync_rejections_received_idx on public.sync_rejections (received_at desc);
comment on table public.sync_rejections is 'Business-rule rejections, kept for troubleshooting. Not retried automatically.';

create table public.sync_tombstones (
  id bigint generated always as identity primary key,
  table_name text not null,
  row_pk jsonb not null,
  store_id uuid,
  deleted_at timestamptz not null default now()
);
create index sync_tombstones_deleted_idx on public.sync_tombstones (deleted_at);
comment on table public.sync_tombstones is
  'Hard deletes of rows that terminals cache, so incremental pulls can remove them locally.';

-- Trigger arguments: the primary-key column names of the table.
create or replace function app.record_tombstone()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_old jsonb := to_jsonb(old);
  v_pk jsonb := '{}'::jsonb;
  v_col text;
begin
  foreach v_col in array tg_argv loop
    v_pk := v_pk || jsonb_build_object(v_col, v_old -> v_col);
  end loop;
  insert into public.sync_tombstones (table_name, row_pk, store_id)
  values (tg_table_name, v_pk, case when v_old ? 'store_id' then (v_old ->> 'store_id')::uuid end);
  return old;
end;
$$;

-- ---------------------------------------------------------------------------
-- Attach shared triggers
-- ---------------------------------------------------------------------------

-- updated_at on every public table that has the column.
do $$
declare
  r record;
begin
  for r in
    select c.table_name
    from information_schema.columns c
    join information_schema.tables t
      on t.table_schema = c.table_schema and t.table_name = c.table_name and t.table_type = 'BASE TABLE'
    where c.table_schema = 'public' and c.column_name = 'updated_at'
    order by c.table_name
  loop
    execute format(
      'create trigger %I before update on public.%I for each row execute function app.touch_updated_at()',
      r.table_name || '_touch_updated_at', r.table_name);
  end loop;
end;
$$;

-- Tombstones for tables that terminals mirror.
do $$
declare
  r record;
begin
  for r in
    select * from (values
      ('units', 'id'), ('categories', 'id'), ('suppliers', 'id'), ('products', 'id'),
      ('product_variants', 'id'), ('modifier_groups', 'id'), ('modifiers', 'id'),
      ('product_modifier_groups', 'product_id,group_id'), ('recipe_items', 'id'),
      ('modifier_recipe_items', 'id'), ('store_variant_settings', 'store_id,variant_id'),
      ('store_favorites', 'store_id,product_id'), ('customers', 'id'), ('payment_methods', 'id'),
      ('store_payment_methods', 'store_id,payment_method_id'), ('promotions', 'id'),
      ('promotion_stores', 'promotion_id,store_id'), ('vouchers', 'id'), ('dining_tables', 'id'),
      ('printers', 'id'), ('employees', 'id'), ('employee_stores', 'employee_id,store_id'),
      ('roles', 'id'), ('role_permissions', 'role_id,permission_code'), ('expense_categories', 'id')
    ) as t(table_name, pk)
  loop
    execute format(
      'create trigger %I after delete on public.%I for each row execute function app.record_tombstone(%s)',
      r.table_name || '_tombstone', r.table_name,
      (select string_agg(quote_literal(trim(col)), ', ') from unnest(string_to_array(r.pk, ',')) as col));
  end loop;
end;
$$;

-- Change audit for sensitive master data.
do $$
declare
  v_table text;
begin
  foreach v_table in array array[
    'business_profile', 'stores', 'store_settings', 'roles', 'role_permissions', 'employees',
    'employee_stores', 'devices', 'products', 'product_variants', 'store_variant_settings',
    'payment_methods', 'store_payment_methods', 'promotions', 'promotion_stores', 'vouchers',
    'expenses', 'printers'
  ] loop
    execute format(
      'create trigger %I after insert or update or delete on public.%I for each row execute function app.audit_row_change()',
      v_table || '_audit', v_table);
  end loop;
end;
$$;
