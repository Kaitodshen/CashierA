-- =============================================================================
-- CashierA · 0300 · Access helpers
-- Who is calling (employee or paired terminal), which stores they may see,
-- and which permissions they hold. Used by RLS policies and RPCs.
-- All helpers are SECURITY DEFINER so they can read identity tables without
-- tripping RLS, and pin search_path to '' (every object is schema-qualified).
-- =============================================================================

-- Active employee linked to the signed-in auth user.
create or replace function app.current_employee_id()
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select e.id from public.employees e
  where e.auth_user_id = auth.uid() and e.is_active
$$;

-- Active paired terminal for the signed-in auth user.
create or replace function app.current_device_id()
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select d.id from public.devices d
  where d.auth_user_id = auth.uid() and d.is_active
$$;

create or replace function app.current_device_store_id()
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select d.store_id from public.devices d
  where d.auth_user_id = auth.uid() and d.is_active
$$;

create or replace function app.is_device()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select app.current_device_id() is not null
$$;

-- Any active principal (employee or terminal). Unpaired anonymous users are not members.
create or replace function app.is_member()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select app.current_employee_id() is not null or app.current_device_id() is not null
$$;

create or replace function app.is_owner()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.employees e
    join public.roles r on r.id = e.role_id
    where e.auth_user_id = auth.uid() and e.is_active and r.code = 'owner'
  )
$$;

-- ---------------------------------------------------------------------------
-- Employee-level checks (used for payload actors such as cashier_id, approved_by)
-- ---------------------------------------------------------------------------
create or replace function app.employee_has_permission(p_employee_id uuid, p_permission text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.employees e
    join public.roles r on r.id = e.role_id
    where e.id = p_employee_id
      and e.is_active
      and (
        r.code = 'owner'
        or exists (
          select 1 from public.role_permissions rp
          where rp.role_id = r.id and rp.permission_code = p_permission
        )
      )
  )
$$;

create or replace function app.employee_store_ids(p_employee_id uuid)
returns uuid[]
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_scope text;
  v_ids uuid[];
begin
  select r.scope into v_scope
  from public.employees e
  join public.roles r on r.id = e.role_id
  where e.id = p_employee_id and e.is_active;

  if v_scope is null then
    return '{}'::uuid[];
  elsif v_scope = 'all_stores' then
    select coalesce(array_agg(s.id order by s.id), '{}') into v_ids from public.stores s;
  else
    select coalesce(array_agg(es.store_id order by es.store_id), '{}') into v_ids
    from public.employee_stores es
    where es.employee_id = p_employee_id;
  end if;
  return v_ids;
end;
$$;

create or replace function app.employee_can_access_store(p_employee_id uuid, p_store_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select p_store_id = any (app.employee_store_ids(p_employee_id))
$$;

create or replace function app.employee_can(p_employee_id uuid, p_store_id uuid, p_permission text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select app.employee_can_access_store(p_employee_id, p_store_id)
     and app.employee_has_permission(p_employee_id, p_permission)
$$;

-- ---------------------------------------------------------------------------
-- Current-principal checks (used directly in RLS policies)
-- ---------------------------------------------------------------------------
create or replace function app.has_permission(p_permission text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(app.employee_has_permission(app.current_employee_id(), p_permission), false)
$$;

-- Stores the caller may read for a module.
--   * paired terminal          -> its own store (terminals read everything in their store)
--   * employee                 -> accessible stores, if they hold ANY of p_permissions
--   * p_permissions null/empty -> no permission needed, just store access
--   * p_allow_device = false   -> terminals get nothing (e.g. audit log, expenses)
-- Wrap calls in (select ...) inside policies so Postgres evaluates them once per query.
create or replace function app.store_ids_with(p_permissions text[] default null, p_allow_device boolean default true)
returns uuid[]
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_device_store uuid;
  v_employee uuid;
begin
  v_device_store := app.current_device_store_id();
  if v_device_store is not null then
    return case when p_allow_device then array[v_device_store] else '{}'::uuid[] end;
  end if;

  v_employee := app.current_employee_id();
  if v_employee is null then
    return '{}'::uuid[];
  end if;

  if coalesce(cardinality(p_permissions), 0) > 0 and not exists (
    select 1 from unnest(p_permissions) as p(code)
    where app.employee_has_permission(v_employee, p.code)
  ) then
    return '{}'::uuid[];
  end if;

  return app.employee_store_ids(v_employee);
end;
$$;

-- Can the current employee manage the target employee (PINs, profile)?
-- Owners manage everyone. Holders of employee.manage manage non-owner staff
-- who share one of their stores, or who have no store yet.
create or replace function app.can_manage_employee(p_actor uuid, p_target uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    exists (
      select 1 from public.employees e join public.roles r on r.id = e.role_id
      where e.id = p_actor and e.is_active and r.code = 'owner'
    )
    or (
      app.employee_has_permission(p_actor, 'employee.manage')
      and not exists (
        select 1 from public.employees t join public.roles r on r.id = t.role_id
        where t.id = p_target and r.scope = 'all_stores'
      )
      and (
        not exists (select 1 from public.employee_stores es where es.employee_id = p_target)
        or exists (
          select 1 from public.employee_stores es
          where es.employee_id = p_target
            and es.store_id = any (app.employee_store_ids(p_actor))
        )
      )
    )
$$;

-- ---------------------------------------------------------------------------
-- Assertions for RPC handlers (raise app.fail on violation)
-- ---------------------------------------------------------------------------

-- The caller may write documents for this store.
create or replace function app.assert_write_scope(p_store_id uuid)
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_device_store uuid := app.current_device_store_id();
  v_employee uuid;
begin
  if p_store_id is null then
    perform app.fail('invalid_input', 'store_id is required');
  end if;
  if v_device_store is not null then
    if p_store_id <> v_device_store then
      perform app.fail('store_mismatch', 'a terminal can only write for its own store');
    end if;
    return;
  end if;
  v_employee := app.current_employee_id();
  if v_employee is null then
    perform app.fail('not_a_member', 'sign in as staff or pair this terminal first');
  end if;
  if not app.employee_can_access_store(v_employee, p_store_id) then
    perform app.fail('store_forbidden', 'you are not assigned to this store');
  end if;
end;
$$;

-- The named employee performs the action. Terminals may act for any PIN-verified
-- staff of their store; people signed in to the back office act only as themselves.
create or replace function app.assert_actor(p_employee_id uuid, p_store_id uuid, p_permission text, p_label text default 'employee')
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if p_employee_id is null then
    perform app.fail('invalid_input', p_label || ' is required');
  end if;
  if not app.is_device() and p_employee_id is distinct from app.current_employee_id() then
    perform app.fail('actor_mismatch', 'back-office callers act as themselves');
  end if;
  if not app.employee_can(p_employee_id, p_store_id, p_permission) then
    perform app.fail('permission_denied', format('%s lacks %s at this store', p_label, p_permission));
  end if;
end;
$$;

-- A second employee approves (manager PIN). Any caller may present an approver.
create or replace function app.assert_approver(p_employee_id uuid, p_store_id uuid, p_permission text)
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if p_employee_id is null then
    perform app.fail('approval_required', 'needs approval: ' || p_permission);
  end if;
  if not app.employee_can(p_employee_id, p_store_id, p_permission) then
    perform app.fail('approval_denied', format('approver lacks %s at this store', p_permission));
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- Guards on identity tables
-- ---------------------------------------------------------------------------

-- New stores get default settings and every active payment method (see 0500).
create or replace function app.on_store_created()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.store_settings (store_id, receipt_header)
  values (new.id, new.name)
  on conflict (store_id) do nothing;
  return new;
end;
$$;

create trigger stores_on_created
after insert on public.stores
for each row execute function app.on_store_created();

-- The owner role can't be renamed, re-scoped or deleted; system roles can't be deleted.
create or replace function app.protect_system_roles()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'DELETE' then
    if old.is_system then
      perform app.fail('role_protected', 'system roles cannot be deleted');
    end if;
    return old;
  end if;
  if old.code = 'owner' and (new.code <> 'owner' or new.scope <> 'all_stores' or not new.is_system) then
    perform app.fail('role_protected', 'the owner role cannot be changed');
  end if;
  if old.is_system and new.code <> old.code then
    perform app.fail('role_protected', 'system role codes cannot be changed');
  end if;
  return new;
end;
$$;

create trigger roles_protect
before update or delete on public.roles
for each row execute function app.protect_system_roles();

-- Removing a permission from the owner role is meaningless and confusing.
create or replace function app.protect_owner_permissions()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if exists (select 1 from public.roles r where r.id = old.role_id and r.code = 'owner') then
    perform app.fail('role_protected', 'the owner role always holds every permission');
  end if;
  return old;
end;
$$;

create trigger role_permissions_protect_owner
before delete on public.role_permissions
for each row execute function app.protect_owner_permissions();

-- Only owners may create or change all-stores employees, and one active owner must remain.
-- Runs for API callers only (auth.uid() is null for migrations, seeds and the service role).
create or replace function app.guard_employee_changes()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_new_scope text;
  v_old_scope text;
  v_old_is_owner boolean := false;
begin
  if auth.uid() is null then
    return new;
  end if;

  select r.scope into v_new_scope from public.roles r where r.id = new.role_id;
  if tg_op = 'UPDATE' then
    select r.scope, r.code = 'owner' into v_old_scope, v_old_is_owner
    from public.roles r where r.id = old.role_id;
  end if;

  if (v_new_scope = 'all_stores' or v_old_scope = 'all_stores') and not app.is_owner() then
    perform app.fail('owner_only', 'only an owner can create or change an all-stores employee');
  end if;

  if tg_op = 'UPDATE' and v_old_is_owner and old.is_active
     and (not new.is_active or new.role_id <> old.role_id)
     and not exists (
       select 1 from public.employees e join public.roles r on r.id = e.role_id
       where r.code = 'owner' and e.is_active and e.id <> old.id
     ) then
    perform app.fail('last_owner', 'at least one active owner is required');
  end if;

  return new;
end;
$$;

create trigger employees_guard
before insert or update on public.employees
for each row execute function app.guard_employee_changes();
