-- =============================================================================
-- CashierA · 1100 · RPC API (PostgREST: POST /rest/v1/rpc/<name>)
--
--   Identity  : current_principal, create_device_pairing_code, pair_device,
--               revoke_device, device_heartbeat, device_staff,
--               set_employee_pin, verify_employee_pin
--   Sync      : sync_push(client_uuid, entity, action, payload)
--   Inventory : request_stock_transfer, transition_stock_transfer,
--               complete_stock_opname
--   Reports   : shift_summary (X / Z report data)
--
-- Every function is SECURITY DEFINER (RLS is bypassed inside), so each one
-- authorizes explicitly with the app.assert_* helpers.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Identity
-- ---------------------------------------------------------------------------

-- What the signed-in principal is: used by the app to choose a shell.
create or replace function public.current_principal()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_device public.devices%rowtype;
  v_employee uuid := app.current_employee_id();
  v_role public.roles%rowtype;
begin
  select * into v_device from public.devices d where d.auth_user_id = auth.uid() and d.is_active;
  if found then
    return jsonb_build_object(
      'kind', 'device',
      'device', jsonb_build_object('id', v_device.id, 'code', v_device.code, 'name', v_device.name,
                                   'store_id', v_device.store_id),
      'store_ids', jsonb_build_array(v_device.store_id));
  end if;

  if v_employee is null then
    return jsonb_build_object('kind', 'none');
  end if;

  select r.* into v_role
  from public.employees e join public.roles r on r.id = e.role_id
  where e.id = v_employee;

  return jsonb_build_object(
    'kind', 'employee',
    'employee', (select jsonb_build_object('id', e.id, 'full_name', e.full_name, 'email', e.email)
                 from public.employees e where e.id = v_employee),
    'role', jsonb_build_object('id', v_role.id, 'code', v_role.code, 'name', v_role.name, 'scope', v_role.scope),
    'permissions', (
      select coalesce(jsonb_agg(p.code order by p.code), '[]'::jsonb)
      from public.permissions p
      where app.employee_has_permission(v_employee, p.code)),
    'store_ids', to_jsonb(app.employee_store_ids(v_employee)));
end;
$$;

-- A manager creates a one-time code (valid 15 minutes) to pair a terminal.
create or replace function public.create_device_pairing_code(p_store_id uuid, p_device_name text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  c_alphabet constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  v_employee uuid := app.current_employee_id();
  v_bytes bytea := extensions.gen_random_bytes(8);
  v_code text := '';
  v_expires timestamptz := now() + interval '15 minutes';
  i integer;
begin
  if v_employee is null or not app.employee_can(v_employee, p_store_id, 'device.manage') then
    perform app.fail('permission_denied', 'device.manage is required for this store');
  end if;
  if coalesce(length(trim(p_device_name)), 0) = 0 then
    perform app.fail('invalid_input', 'device name is required');
  end if;

  -- 256 is a multiple of 32, so every character is equally likely (40 bits of entropy).
  for i in 0..7 loop
    v_code := v_code || substr(c_alphabet, (get_byte(v_bytes, i) % 32) + 1, 1);
  end loop;

  insert into public.device_pairing_codes (code_hash, store_id, device_name, created_by, expires_at)
  values (encode(extensions.digest(v_code, 'sha256'), 'hex'), p_store_id, trim(p_device_name), v_employee, v_expires);

  insert into public.audit_log (store_id, actor_employee_id, action, entity_type, details)
  values (p_store_id, v_employee, 'device.pairing_code_created', 'store',
          jsonb_build_object('device_name', trim(p_device_name), 'expires_at', v_expires));

  return jsonb_build_object('code', v_code, 'expires_at', v_expires);
end;
$$;

-- Called by the terminal after an anonymous sign-in. Binds this auth user to the store.
create or replace function public.pair_device(p_code text, p_platform text default null, p_app_version text default null)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_pc public.device_pairing_codes%rowtype;
  v_next integer;
  v_device public.devices%rowtype;
begin
  if v_uid is null then
    perform app.fail('not_authenticated', 'sign in (anonymously) before pairing');
  end if;
  if exists (select 1 from public.employees e where e.auth_user_id = v_uid) then
    perform app.fail('pairing_not_allowed', 'staff accounts cannot be paired as terminals');
  end if;
  if exists (select 1 from public.devices d where d.auth_user_id = v_uid) then
    perform app.fail('already_paired', 'this sign-in is already a terminal');
  end if;

  select * into v_pc
  from public.device_pairing_codes pc
  where pc.code_hash = encode(extensions.digest(upper(trim(coalesce(p_code, ''))), 'sha256'), 'hex')
  for update;

  if not found or v_pc.used_at is not null or v_pc.expires_at < now() then
    perform app.fail('pairing_code_invalid', 'the code is wrong, expired or already used');
  end if;

  -- Serialize terminal-code allocation per store.
  perform 1 from public.stores s where s.id = v_pc.store_id for update;
  select coalesce(max(substr(d.code, 2)::integer), 0) + 1 into v_next
  from public.devices d where d.store_id = v_pc.store_id;

  insert into public.devices (store_id, auth_user_id, code, name, platform, app_version, paired_by, last_seen_at)
  values (v_pc.store_id, v_uid, 'T' || v_next, v_pc.device_name, p_platform, p_app_version, v_pc.created_by, now())
  returning * into v_device;

  update public.device_pairing_codes set used_at = now(), device_id = v_device.id where id = v_pc.id;

  insert into public.audit_log (store_id, device_id, actor_employee_id, action, entity_type, entity_id, details)
  values (v_device.store_id, v_device.id, v_pc.created_by, 'device.paired', 'device', v_device.id,
          jsonb_build_object('name', v_device.name, 'platform', p_platform, 'app_version', p_app_version));

  return jsonb_build_object('device_id', v_device.id, 'device_code', v_device.code,
                            'store_id', v_device.store_id, 'name', v_device.name);
end;
$$;

create or replace function public.revoke_device(p_device_id uuid, p_reason text default null)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_employee uuid := app.current_employee_id();
  v_device public.devices%rowtype;
begin
  select * into v_device from public.devices where id = p_device_id for update;
  if not found then
    perform app.fail('device_not_found');
  end if;
  if v_employee is null or not app.employee_can(v_employee, v_device.store_id, 'device.manage') then
    perform app.fail('permission_denied', 'device.manage is required for this store');
  end if;
  if not v_device.is_active then
    return;
  end if;

  update public.devices
     set is_active = false, revoked_at = now(), revoked_by = v_employee
   where id = p_device_id;

  insert into public.audit_log (store_id, device_id, actor_employee_id, action, entity_type, entity_id, details)
  values (v_device.store_id, v_device.id, v_employee, 'device.revoked', 'device', v_device.id,
          jsonb_build_object('reason', p_reason));
end;
$$;

create or replace function public.device_heartbeat(p_app_version text default null)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_device uuid := app.current_device_id();
begin
  if v_device is null then
    perform app.fail('device_required');
  end if;
  update public.devices
     set last_seen_at = now(), app_version = coalesce(p_app_version, app_version)
   where id = v_device;
  return jsonb_build_object('device_id', v_device, 'server_time', now());
end;
$$;

-- Staff roster with PIN hashes for offline PIN checks on a paired terminal.
create or replace function public.device_staff()
returns table (
  employee_id uuid,
  full_name text,
  role_code text,
  permissions text[],
  pin_hash text,
  is_active boolean
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_store uuid := app.current_device_store_id();
begin
  if v_store is null then
    perform app.fail('device_required', 'only paired terminals can download the staff roster');
  end if;
  return query
    select e.id,
           e.full_name,
           r.code,
           case when r.code = 'owner'
                then (select array_agg(p.code order by p.code) from public.permissions p)
                else coalesce((select array_agg(rp.permission_code order by rp.permission_code)
                               from public.role_permissions rp where rp.role_id = r.id), '{}'::text[])
           end,
           ep.pin_hash,
           e.is_active
    from public.employees e
    join public.roles r on r.id = e.role_id
    left join public.employee_pins ep on ep.employee_id = e.id
    where e.is_active
      and (r.scope = 'all_stores'
           or exists (select 1 from public.employee_stores es
                      where es.employee_id = e.id and es.store_id = v_store))
    order by e.full_name;
end;
$$;

create or replace function public.set_employee_pin(p_employee_id uuid, p_pin text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := app.current_employee_id();
begin
  if v_actor is null then
    perform app.fail('permission_denied', 'sign in as staff to set PINs');
  end if;
  if v_actor <> p_employee_id and not app.can_manage_employee(v_actor, p_employee_id) then
    perform app.fail('permission_denied', 'you cannot manage this employee');
  end if;
  if p_pin is null or p_pin !~ '^[0-9]{4,6}$' then
    perform app.fail('invalid_pin', 'PIN must be 4 to 6 digits');
  end if;
  if p_pin ~ '^(.)\1+$' or p_pin in ('1234', '12345', '123456', '4321', '54321', '654321') then
    perform app.fail('weak_pin', 'choose a PIN that is not a repeated digit or a simple sequence');
  end if;

  insert into public.employee_pins (employee_id, pin_hash)
  values (p_employee_id, extensions.crypt(p_pin, extensions.gen_salt('bf', 10)))
  on conflict (employee_id) do update
    set pin_hash = excluded.pin_hash, failed_attempts = 0, locked_until = null, updated_at = now();

  insert into public.audit_log (actor_employee_id, action, entity_type, entity_id)
  values (v_actor, 'employee.pin_set', 'employee', p_employee_id);
end;
$$;

-- Online PIN check with lockout (5 wrong tries -> 5 minutes). Terminals use it for
-- their own store's staff; people may check their own PIN.
create or replace function public.verify_employee_pin(p_employee_id uuid, p_pin text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_pin public.employee_pins%rowtype;
  v_ok boolean;
begin
  if app.is_device() then
    if not app.employee_can_access_store(p_employee_id, app.current_device_store_id()) then
      perform app.fail('permission_denied', 'employee is not assigned to this store');
    end if;
  elsif app.current_employee_id() is distinct from p_employee_id then
    perform app.fail('permission_denied', 'you can only check your own PIN');
  end if;

  select * into v_pin from public.employee_pins where employee_id = p_employee_id for update;
  if not found then
    return jsonb_build_object('ok', false, 'reason', 'no_pin');
  end if;
  if v_pin.locked_until is not null and v_pin.locked_until > now() then
    return jsonb_build_object('ok', false, 'reason', 'locked', 'locked_until', v_pin.locked_until);
  end if;

  v_ok := extensions.crypt(coalesce(p_pin, ''), v_pin.pin_hash) = v_pin.pin_hash;
  if v_ok then
    update public.employee_pins set failed_attempts = 0, locked_until = null where employee_id = p_employee_id;
    return jsonb_build_object('ok', true);
  end if;

  update public.employee_pins
     set failed_attempts = failed_attempts + 1,
         locked_until = case when failed_attempts + 1 >= 5 then now() + interval '5 minutes' end
   where employee_id = p_employee_id;
  return jsonb_build_object('ok', false, 'reason', 'mismatch',
                            'attempts_left', greatest(0, 4 - v_pin.failed_attempts));
end;
$$;

-- ---------------------------------------------------------------------------
-- Sync handlers (app.sync_*): one per entity.action, called by sync_push.
-- Each validates scope + actors, applies, and returns a small JSON result.
-- ---------------------------------------------------------------------------

-- Shared check: the shift is open, in this store, and (for terminals) theirs.
create or replace function app.assert_open_shift(p_shift_id uuid, p_store_id uuid)
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  s public.shifts%rowtype;
begin
  select * into s from public.shifts where id = p_shift_id;
  if not found or s.store_id <> p_store_id then
    perform app.fail('shift_required', 'an open shift of this store is required');
  end if;
  if s.status <> 'open' then
    perform app.fail('shift_closed', 'the shift is already closed');
  end if;
  if app.is_device() and s.device_id <> app.current_device_id() then
    perform app.fail('shift_other_device', 'the shift belongs to another terminal');
  end if;
end;
$$;

create or replace function app.sync_shift_open(p jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid := (p ->> 'id')::uuid;
  v_store uuid := (p ->> 'store_id')::uuid;
  v_by uuid := (p ->> 'opened_by')::uuid;
  v_device uuid := app.current_device_id();
  v_existing public.shifts%rowtype;
begin
  if v_device is null then
    perform app.fail('device_required', 'shifts are opened on a paired terminal');
  end if;
  perform app.assert_write_scope(v_store);
  perform app.assert_actor(v_by, v_store, 'shift.manage', 'opened_by');

  select * into v_existing from public.shifts where id = v_id;
  if found then
    return jsonb_build_object('shift_id', v_id, 'status', v_existing.status, 'noop', true);
  end if;

  insert into public.shifts (id, store_id, device_id, opened_by, opened_at, opening_cash)
  values (v_id, v_store, v_device, v_by, coalesce((p ->> 'opened_at')::timestamptz, now()),
          (p ->> 'opening_cash')::bigint);

  insert into public.audit_log (occurred_at, store_id, device_id, actor_employee_id, action, entity_type, entity_id, details)
  values (coalesce((p ->> 'opened_at')::timestamptz, now()), v_store, v_device, v_by, 'shift.opened', 'shift', v_id,
          jsonb_build_object('opening_cash', (p ->> 'opening_cash')::bigint));

  return jsonb_build_object('shift_id', v_id, 'status', 'open');
end;
$$;

create or replace function app.sync_shift_close(p jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_shift public.shifts%rowtype;
  v_by uuid := (p ->> 'closed_by')::uuid;
  v_counted bigint := (p ->> 'counted_cash')::bigint;
  v_client bigint := (p ->> 'client_expected_cash')::bigint;
  v_expected bigint;
begin
  select * into v_shift from public.shifts where id = (p ->> 'id')::uuid for update;
  if not found then
    perform app.fail('shift_not_found');
  end if;
  perform app.assert_write_scope(v_shift.store_id);

  if v_shift.status = 'closed' then
    return jsonb_build_object('shift_id', v_shift.id, 'status', 'closed', 'expected_cash', v_shift.expected_cash,
                              'counted_cash', v_shift.counted_cash, 'cash_difference', v_shift.cash_difference,
                              'noop', true);
  end if;
  if app.is_device() and v_shift.device_id <> app.current_device_id() then
    perform app.fail('shift_other_device', 'the shift belongs to another terminal');
  end if;
  perform app.assert_actor(v_by, v_shift.store_id, 'shift.manage', 'closed_by');
  if v_counted is null or v_counted < 0 then
    perform app.fail('invalid_input', 'counted_cash must be zero or more');
  end if;

  v_expected := app.shift_expected_cash(v_shift.id);

  update public.shifts
     set status = 'closed',
         closed_by = v_by,
         closed_at = coalesce((p ->> 'closed_at')::timestamptz, now()),
         counted_cash = v_counted,
         expected_cash = v_expected,
         client_expected_cash = v_client,
         cash_difference = v_counted - v_expected,
         close_note = p ->> 'note'
   where id = v_shift.id;

  if v_client is not null and v_client <> v_expected then
    insert into public.alerts (store_id, alert_type, severity, reference_type, reference_id, message, details)
    values (v_shift.store_id, 'CASH_DISCREPANCY', 'critical', 'shift', v_shift.id,
            format('Terminal expected Rp %s but the server computed Rp %s; some transactions may be missing',
                   v_client, v_expected),
            jsonb_build_object('client_expected_cash', v_client, 'expected_cash', v_expected));
  end if;

  insert into public.audit_log (occurred_at, store_id, device_id, actor_employee_id, action, entity_type, entity_id, details)
  values (coalesce((p ->> 'closed_at')::timestamptz, now()), v_shift.store_id, app.current_device_id(), v_by,
          'shift.closed', 'shift', v_shift.id,
          jsonb_build_object('expected_cash', v_expected, 'counted_cash', v_counted,
                             'cash_difference', v_counted - v_expected));

  return jsonb_build_object('shift_id', v_shift.id, 'status', 'closed', 'expected_cash', v_expected,
                            'counted_cash', v_counted, 'cash_difference', v_counted - v_expected);
end;
$$;

create or replace function app.sync_cash_movement(p jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid := (p ->> 'id')::uuid;
  v_shift public.shifts%rowtype;
  v_by uuid := (p ->> 'employee_id')::uuid;
begin
  if exists (select 1 from public.cash_movements cm where cm.id = v_id) then
    return jsonb_build_object('cash_movement_id', v_id, 'noop', true);
  end if;
  select * into v_shift from public.shifts where id = (p ->> 'shift_id')::uuid;
  if not found then
    perform app.fail('shift_not_found');
  end if;
  perform app.assert_write_scope(v_shift.store_id);
  perform app.assert_open_shift(v_shift.id, v_shift.store_id);
  perform app.assert_actor(v_by, v_shift.store_id, 'shift.cash_movement', 'employee');
  if (p ->> 'approved_by') is not null then
    perform app.assert_approver((p ->> 'approved_by')::uuid, v_shift.store_id, 'shift.cash_movement');
  end if;

  insert into public.cash_movements (id, store_id, shift_id, movement_type, amount, reason, employee_id, approved_by, occurred_at)
  values (v_id, v_shift.store_id, v_shift.id, p ->> 'movement_type', (p ->> 'amount')::bigint,
          trim(p ->> 'reason'), v_by, (p ->> 'approved_by')::uuid,
          coalesce((p ->> 'occurred_at')::timestamptz, now()));

  insert into public.audit_log (occurred_at, store_id, device_id, actor_employee_id, approver_employee_id, action, entity_type, entity_id, details)
  values (coalesce((p ->> 'occurred_at')::timestamptz, now()), v_shift.store_id, app.current_device_id(), v_by,
          (p ->> 'approved_by')::uuid, 'cash.movement_' || (p ->> 'movement_type'), 'cash_movement', v_id,
          jsonb_build_object('amount', (p ->> 'amount')::bigint, 'reason', trim(p ->> 'reason')));

  return jsonb_build_object('cash_movement_id', v_id);
end;
$$;

-- Full snapshot of an order (header + items + modifiers + discounts + payments).
-- Open/held orders may be re-sent with a higher version; completion and
-- cancellation are transitions that fire the lifecycle triggers.
create or replace function app.sync_order_upsert(p jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid := (p ->> 'id')::uuid;
  v_store uuid := (p ->> 'store_id')::uuid;
  v_status text := coalesce(p ->> 'status', 'open');
  v_version integer := coalesce((p ->> 'version')::integer, 1);
  v_cashier uuid := (p ->> 'cashier_id')::uuid;
  v_shift_id uuid := (p ->> 'shift_id')::uuid;
  v_table uuid := (p ->> 'table_id')::uuid;
  v_cancel jsonb := p -> 'cancel';
  v_exists boolean;
  v_existing public.orders%rowtype;
  v_shift public.shifts%rowtype;
  v_settings public.store_settings%rowtype;
  v_fnb boolean;
  v_late boolean := false;
  v_item jsonb;
  v_mod jsonb;
  v_disc jsonb;
  v_pay jsonb;
  v_mod_total bigint;
  v_unit_cost bigint;
  v_cost_amount bigint;
  v_base bigint;
  v_bps integer;
  v_result public.orders%rowtype;
begin
  if v_id is null then
    perform app.fail('invalid_input', 'order id is required');
  end if;
  if v_status not in ('open', 'held', 'completed', 'cancelled') then
    perform app.fail('invalid_input', 'status must be open, held, completed or cancelled');
  end if;
  perform app.assert_write_scope(v_store);
  perform app.assert_actor(v_cashier, v_store, 'pos.sell', 'cashier');

  select * into v_existing from public.orders where id = v_id for update;
  v_exists := found;

  if v_exists then
    if v_existing.store_id <> v_store then
      perform app.fail('store_mismatch', 'the order belongs to another store');
    end if;
    if v_existing.status in ('completed', 'voided', 'cancelled') then
      -- Retries and stale snapshots are harmless; a NEWER snapshot of a closed
      -- order means the terminal diverged, so say so instead of hiding it.
      if v_version <= v_existing.version then
        return jsonb_build_object('order_id', v_id, 'status', v_existing.status,
                                  'version', v_existing.version, 'noop', true);
      end if;
      perform app.fail('order_closed', format('the order is %s; use order.void or refund.create', v_existing.status));
    end if;
    if v_version <= v_existing.version then
      return jsonb_build_object('order_id', v_id, 'status', v_existing.status,
                                'version', v_existing.version, 'noop', true);
    end if;
  end if;

  select * into v_settings from public.store_settings where store_id = v_store;
  select s.fnb_mode into v_fnb from public.stores s where s.id = v_store;

  if v_shift_id is not null then
    select * into v_shift from public.shifts where id = v_shift_id;
    if not found or v_shift.store_id <> v_store then
      perform app.fail('shift_invalid', 'shift not found in this store');
    end if;
    if app.is_device() and v_shift.device_id <> app.current_device_id() then
      perform app.fail('shift_other_device', 'the shift belongs to another terminal');
    end if;
    v_late := v_shift.status = 'closed';
  elsif v_status = 'completed' then
    perform app.fail('shift_required', 'completed orders need a shift');
  end if;

  if v_table is not null and not exists (
       select 1 from public.dining_tables t where t.id = v_table and t.store_id = v_store) then
    perform app.fail('table_invalid', 'table not found in this store');
  end if;

  -- Header -----------------------------------------------------------------
  if not v_exists then
    insert into public.orders (
      id, store_id, device_id, shift_id, order_number, order_type, status, table_id, customer_id,
      cashier_id, guest_count, note, gross_total, item_discount_total, bill_discount_total,
      points_redeemed, points_discount, net_total, service_charge_total, tax_total, tax_inclusive,
      tax_rate_bps, service_charge_bps, service_charge_taxable, rounding_amount, grand_total,
      paid_total, change_total, points_earned, kasbon_due_date, version, ordered_at,
      receipt_printed_at, split_from_order_id)
    values (
      v_id, v_store, app.current_device_id(), v_shift_id, p ->> 'order_number',
      coalesce(p ->> 'order_type', 'takeaway'),
      case when v_status = 'held' then 'held' else 'open' end,
      v_table, (p ->> 'customer_id')::uuid, v_cashier, (p ->> 'guest_count')::smallint, p ->> 'note',
      coalesce((p ->> 'gross_total')::bigint, 0), coalesce((p ->> 'item_discount_total')::bigint, 0),
      coalesce((p ->> 'bill_discount_total')::bigint, 0), coalesce((p ->> 'points_redeemed')::integer, 0),
      coalesce((p ->> 'points_discount')::bigint, 0), coalesce((p ->> 'net_total')::bigint, 0),
      coalesce((p ->> 'service_charge_total')::bigint, 0), coalesce((p ->> 'tax_total')::bigint, 0),
      coalesce((p ->> 'tax_inclusive')::boolean, v_settings.tax_inclusive),
      coalesce((p ->> 'tax_rate_bps')::integer, 0), coalesce((p ->> 'service_charge_bps')::integer, 0),
      coalesce((p ->> 'service_charge_taxable')::boolean, v_settings.service_charge_taxable),
      coalesce((p ->> 'rounding_amount')::bigint, 0), coalesce((p ->> 'grand_total')::bigint, 0),
      coalesce((p ->> 'paid_total')::bigint, 0), coalesce((p ->> 'change_total')::bigint, 0),
      coalesce((p ->> 'points_earned')::integer, 0), (p ->> 'kasbon_due_date')::date, v_version,
      coalesce((p ->> 'ordered_at')::timestamptz, now()), (p ->> 'receipt_printed_at')::timestamptz,
      (p ->> 'split_from_order_id')::uuid);
  else
    update public.orders set
      shift_id = v_shift_id,
      order_type = coalesce(p ->> 'order_type', order_type),
      status = case when v_status in ('open', 'held') then v_status else status end,
      table_id = v_table,
      customer_id = (p ->> 'customer_id')::uuid,
      cashier_id = v_cashier,
      guest_count = (p ->> 'guest_count')::smallint,
      note = p ->> 'note',
      gross_total = coalesce((p ->> 'gross_total')::bigint, 0),
      item_discount_total = coalesce((p ->> 'item_discount_total')::bigint, 0),
      bill_discount_total = coalesce((p ->> 'bill_discount_total')::bigint, 0),
      points_redeemed = coalesce((p ->> 'points_redeemed')::integer, 0),
      points_discount = coalesce((p ->> 'points_discount')::bigint, 0),
      net_total = coalesce((p ->> 'net_total')::bigint, 0),
      service_charge_total = coalesce((p ->> 'service_charge_total')::bigint, 0),
      tax_total = coalesce((p ->> 'tax_total')::bigint, 0),
      tax_inclusive = coalesce((p ->> 'tax_inclusive')::boolean, tax_inclusive),
      tax_rate_bps = coalesce((p ->> 'tax_rate_bps')::integer, 0),
      service_charge_bps = coalesce((p ->> 'service_charge_bps')::integer, 0),
      service_charge_taxable = coalesce((p ->> 'service_charge_taxable')::boolean, service_charge_taxable),
      rounding_amount = coalesce((p ->> 'rounding_amount')::bigint, 0),
      grand_total = coalesce((p ->> 'grand_total')::bigint, 0),
      paid_total = coalesce((p ->> 'paid_total')::bigint, 0),
      change_total = coalesce((p ->> 'change_total')::bigint, 0),
      points_earned = coalesce((p ->> 'points_earned')::integer, 0),
      kasbon_due_date = (p ->> 'kasbon_due_date')::date,
      version = v_version,
      ordered_at = coalesce((p ->> 'ordered_at')::timestamptz, ordered_at),
      receipt_printed_at = coalesce((p ->> 'receipt_printed_at')::timestamptz, receipt_printed_at)
    where id = v_id;

    -- Replace lines and discounts with the snapshot (cascades to modifiers).
    delete from public.order_discounts where order_id = v_id;
    delete from public.order_items where order_id = v_id;
  end if;

  -- Lines --------------------------------------------------------------------
  for v_item in select value from jsonb_array_elements(coalesce(p -> 'items', '[]'::jsonb)) loop
    if not exists (
         select 1 from public.product_variants pv
         where pv.id = (v_item ->> 'variant_id')::uuid and pv.product_id = (v_item ->> 'product_id')::uuid) then
      perform app.fail('variant_product_mismatch', coalesce(v_item ->> 'sku', v_item ->> 'variant_id'));
    end if;

    select coalesce(sum((m.value ->> 'price_delta')::bigint), 0) into v_mod_total
    from jsonb_array_elements(coalesce(v_item -> 'modifiers', '[]'::jsonb)) m;
    if v_mod_total <> coalesce((v_item ->> 'modifiers_unit_total')::bigint, 0) then
      perform app.fail('modifiers_mismatch', format('%s: modifiers %s <> modifiers_unit_total %s',
        v_item ->> 'sku', v_mod_total, coalesce((v_item ->> 'modifiers_unit_total')::bigint, 0)));
    end if;

    -- COGS snapshot: the terminal's value, else the current variant cost.
    if v_item ? 'unit_cost' then
      v_unit_cost := (v_item ->> 'unit_cost')::bigint;
      v_cost_amount := coalesce((v_item ->> 'cost_amount')::bigint, round(v_unit_cost * (v_item ->> 'quantity')::numeric));
    else
      select pv.cost into v_unit_cost from public.product_variants pv where pv.id = (v_item ->> 'variant_id')::uuid;
      v_cost_amount := round(v_unit_cost * (v_item ->> 'quantity')::numeric);
    end if;

    insert into public.order_items (
      id, order_id, store_id, product_id, variant_id, product_name, variant_name, sku, quantity,
      unit_price, modifiers_unit_total, gross_amount, item_discount_amount, bill_discount_amount,
      net_amount, tax_amount, is_taxable, unit_cost, cost_amount, note, discount_note,
      kitchen_station, sort_order)
    values (
      (v_item ->> 'id')::uuid, v_id, v_store, (v_item ->> 'product_id')::uuid,
      (v_item ->> 'variant_id')::uuid, v_item ->> 'product_name', v_item ->> 'variant_name',
      v_item ->> 'sku', (v_item ->> 'quantity')::numeric, (v_item ->> 'unit_price')::bigint,
      coalesce((v_item ->> 'modifiers_unit_total')::bigint, 0), (v_item ->> 'gross_amount')::bigint,
      coalesce((v_item ->> 'item_discount_amount')::bigint, 0),
      coalesce((v_item ->> 'bill_discount_amount')::bigint, 0), (v_item ->> 'net_amount')::bigint,
      coalesce((v_item ->> 'tax_amount')::bigint, 0), coalesce((v_item ->> 'is_taxable')::boolean, true),
      v_unit_cost, v_cost_amount, v_item ->> 'note', v_item ->> 'discount_note',
      v_item ->> 'kitchen_station', coalesce((v_item ->> 'sort_order')::integer, 0));

    for v_mod in select value from jsonb_array_elements(coalesce(v_item -> 'modifiers', '[]'::jsonb)) loop
      insert into public.order_item_modifiers (id, order_item_id, store_id, modifier_id, group_name, modifier_name, price_delta)
      values ((v_mod ->> 'id')::uuid, (v_item ->> 'id')::uuid, v_store, (v_mod ->> 'modifier_id')::uuid,
              v_mod ->> 'group_name', v_mod ->> 'modifier_name', coalesce((v_mod ->> 'price_delta')::bigint, 0));
    end loop;
  end loop;

  -- Discounts ---------------------------------------------------------------
  for v_disc in select value from jsonb_array_elements(coalesce(p -> 'discounts', '[]'::jsonb)) loop
    insert into public.order_discounts (
      id, order_id, store_id, order_item_id, source, promotion_id, voucher_id, description, amount,
      discount_bps, approved_by)
    values (
      (v_disc ->> 'id')::uuid, v_id, v_store, (v_disc ->> 'order_item_id')::uuid, v_disc ->> 'source',
      (v_disc ->> 'promotion_id')::uuid, (v_disc ->> 'voucher_id')::uuid, v_disc ->> 'description',
      (v_disc ->> 'amount')::bigint, (v_disc ->> 'discount_bps')::integer, (v_disc ->> 'approved_by')::uuid);

    if v_disc ->> 'source' = 'manual' then
      if not app.employee_has_permission(v_cashier, 'pos.discount') then
        perform app.fail('permission_denied', 'cashier lacks pos.discount');
      end if;
      -- Effective size of the discount against what it applies to.
      if (v_disc ->> 'order_item_id') is not null then
        select oi.gross_amount into v_base from public.order_items oi where oi.id = (v_disc ->> 'order_item_id')::uuid;
      else
        v_base := coalesce((p ->> 'gross_total')::bigint, 0) - coalesce((p ->> 'item_discount_total')::bigint, 0);
      end if;
      v_bps := case when coalesce(v_base, 0) > 0
                    then ceil((v_disc ->> 'amount')::numeric * 10000 / v_base)::integer
                    else 10000 end;
      v_bps := greatest(v_bps, coalesce((v_disc ->> 'discount_bps')::integer, 0));
      if v_bps > v_settings.discount_approval_bps then
        perform app.assert_approver((v_disc ->> 'approved_by')::uuid, v_store, 'pos.discount_override');
        insert into public.audit_log (store_id, device_id, actor_employee_id, approver_employee_id, action, entity_type, entity_id, details)
        values (v_store, app.current_device_id(), v_cashier, (v_disc ->> 'approved_by')::uuid,
                'pos.discount_override', 'order', v_id,
                jsonb_build_object('amount', (v_disc ->> 'amount')::bigint, 'effective_bps', v_bps,
                                   'threshold_bps', v_settings.discount_approval_bps));
      end if;
    end if;
  end loop;

  -- Payments: upsert by id; a gateway-confirmed payment is never downgraded.
  delete from public.payments pay
   where pay.order_id = v_id
     and not exists (select 1 from jsonb_array_elements(coalesce(p -> 'payments', '[]'::jsonb)) x
                     where (x.value ->> 'id')::uuid = pay.id);

  for v_pay in select value from jsonb_array_elements(coalesce(p -> 'payments', '[]'::jsonb)) loop
    if not exists (
         select 1 from public.payment_methods pm
         where pm.id = (v_pay ->> 'payment_method_id')::uuid and pm.method_type = v_pay ->> 'method_type') then
      perform app.fail('payment_method_invalid', coalesce(v_pay ->> 'method_type', 'missing method_type'));
    end if;
    if v_pay ->> 'method_type' = 'kasbon' then
      if not v_settings.kasbon_enabled then
        perform app.fail('kasbon_disabled', 'kasbon is switched off for this store');
      end if;
      if not app.employee_has_permission(v_cashier, 'kasbon.manage') then
        perform app.fail('permission_denied', 'cashier lacks kasbon.manage');
      end if;
    end if;

    insert into public.payments (
      id, order_id, store_id, shift_id, payment_method_id, method_type, amount, tendered_amount,
      change_amount, reference, provider, provider_ref, status, paid_at)
    values (
      (v_pay ->> 'id')::uuid, v_id, v_store, v_shift_id, (v_pay ->> 'payment_method_id')::uuid,
      v_pay ->> 'method_type', (v_pay ->> 'amount')::bigint, (v_pay ->> 'tendered_amount')::bigint,
      coalesce((v_pay ->> 'change_amount')::bigint, 0), v_pay ->> 'reference', v_pay ->> 'provider',
      v_pay ->> 'provider_ref', coalesce(v_pay ->> 'status', 'paid'),
      coalesce((v_pay ->> 'paid_at')::timestamptz,
               case when coalesce(v_pay ->> 'status', 'paid') = 'paid'
                    then coalesce((p ->> 'completed_at')::timestamptz, now()) end))
    on conflict (id) do update set
      shift_id = excluded.shift_id,
      payment_method_id = excluded.payment_method_id,
      method_type = excluded.method_type,
      amount = excluded.amount,
      tendered_amount = excluded.tendered_amount,
      change_amount = excluded.change_amount,
      reference = excluded.reference,
      status = case when public.payments.provider is not null and public.payments.status = 'paid'
                    then 'paid' else excluded.status end,
      paid_at = coalesce(public.payments.paid_at, excluded.paid_at)
    where public.payments.order_id = v_id;
  end loop;

  -- Floor plan and kitchen tickets -------------------------------------------
  if v_status in ('open', 'held') and v_table is not null then
    update public.dining_tables
       set status = 'occupied', current_order_id = v_id
     where id = v_table and (current_order_id is null or current_order_id = v_id);
  end if;

  if v_fnb then
    insert into public.order_status (order_id, store_id, station)
    select distinct v_id, v_store, oi.kitchen_station
    from public.order_items oi
    where oi.order_id = v_id and oi.kitchen_station is not null
    on conflict (order_id, station) do nothing;
  end if;

  -- Transitions ----------------------------------------------------------------
  if v_status = 'completed' then
    update public.orders
       set status = 'completed', completed_at = coalesce((p ->> 'completed_at')::timestamptz, now())
     where id = v_id;

    if v_late then
      update public.orders
         set needs_review = true,
             review_reason = concat_ws('; ', nullif(review_reason, ''), 'late_sync_after_shift_close')
       where id = v_id;
      perform app.recompute_closed_shift(v_shift_id);
      insert into public.alerts (store_id, alert_type, severity, reference_type, reference_id, message, details)
      values (v_store, 'LATE_SYNC', 'warning', 'order', v_id,
              format('Order %s arrived after its shift was closed; the shift cash was recomputed', p ->> 'order_number'),
              jsonb_build_object('shift_id', v_shift_id));
    end if;

  elsif v_status = 'cancelled' then
    if v_cancel is null or (v_cancel ->> 'cancelled_by') is null
       or coalesce(length(trim(v_cancel ->> 'reason')), 0) < 3 then
      perform app.fail('invalid_input', 'cancel.cancelled_by and cancel.reason are required');
    end if;
    perform app.assert_actor((v_cancel ->> 'cancelled_by')::uuid, v_store, 'pos.void', 'cancelled_by');
    if (p ->> 'receipt_printed_at') is not null or v_existing.receipt_printed_at is not null then
      perform app.assert_approver((v_cancel ->> 'approved_by')::uuid, v_store, 'pos.void_after_print');
    end if;

    update public.orders
       set status = 'cancelled',
           cancelled_at = coalesce((v_cancel ->> 'cancelled_at')::timestamptz, now()),
           cancelled_by = (v_cancel ->> 'cancelled_by')::uuid,
           cancel_reason = trim(v_cancel ->> 'reason'),
           void_approved_by = (v_cancel ->> 'approved_by')::uuid,
           merged_into_order_id = (p ->> 'merged_into_order_id')::uuid
     where id = v_id;

    insert into public.audit_log (store_id, device_id, actor_employee_id, approver_employee_id, action, entity_type, entity_id, details)
    values (v_store, app.current_device_id(), (v_cancel ->> 'cancelled_by')::uuid, (v_cancel ->> 'approved_by')::uuid,
            'order.cancelled', 'order', v_id,
            jsonb_build_object('reason', trim(v_cancel ->> 'reason'), 'order_number', p ->> 'order_number',
                               'merged_into_order_id', p ->> 'merged_into_order_id'));
  end if;

  select * into v_result from public.orders where id = v_id;
  return jsonb_build_object('order_id', v_id, 'status', v_result.status, 'version', v_result.version,
                            'needs_review', v_result.needs_review, 'business_date', v_result.business_date);
end;
$$;

create or replace function app.sync_order_void(p jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  o public.orders%rowtype;
  v_by uuid := (p ->> 'voided_by')::uuid;
  v_approver uuid := (p ->> 'approved_by')::uuid;
  v_shift uuid := (p ->> 'shift_id')::uuid;
begin
  select * into o from public.orders where id = (p ->> 'order_id')::uuid for update;
  if not found then
    perform app.fail('order_not_found');
  end if;
  perform app.assert_write_scope(o.store_id);
  if o.status = 'voided' then
    return jsonb_build_object('order_id', o.id, 'status', 'voided', 'noop', true);
  end if;
  if o.status <> 'completed' then
    perform app.fail('order_not_completed', 'only completed orders are voided; cancel open orders instead');
  end if;
  perform app.assert_actor(v_by, o.store_id, 'pos.void', 'voided_by');
  if o.receipt_printed_at is not null or (p ->> 'receipt_printed_at') is not null then
    perform app.assert_approver(v_approver, o.store_id, 'pos.void_after_print');
  end if;
  if coalesce(length(trim(p ->> 'reason')), 0) < 3 then
    perform app.fail('invalid_input', 'a void reason is required');
  end if;
  if v_shift is not null and not exists (
       select 1 from public.shifts s where s.id = v_shift and s.store_id = o.store_id) then
    perform app.fail('shift_invalid', 'shift not found in this store');
  end if;

  update public.orders
     set status = 'voided',
         voided_at = coalesce((p ->> 'voided_at')::timestamptz, now()),
         voided_by = v_by,
         void_approved_by = v_approver,
         void_reason = trim(p ->> 'reason'),
         voided_shift_id = coalesce(v_shift, o.shift_id),
         receipt_printed_at = coalesce(o.receipt_printed_at, (p ->> 'receipt_printed_at')::timestamptz)
   where id = o.id;

  perform app.recompute_closed_shift(coalesce(v_shift, o.shift_id));

  insert into public.audit_log (occurred_at, store_id, device_id, actor_employee_id, approver_employee_id, action, entity_type, entity_id, details)
  values (coalesce((p ->> 'voided_at')::timestamptz, now()), o.store_id, app.current_device_id(), v_by, v_approver,
          'order.voided', 'order', o.id,
          jsonb_build_object('reason', trim(p ->> 'reason'), 'order_number', o.order_number,
                             'grand_total', o.grand_total, 'printed', o.receipt_printed_at is not null));

  return jsonb_build_object('order_id', o.id, 'status', 'voided');
end;
$$;

create or replace function app.sync_order_mark_printed(p jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  o public.orders%rowtype;
begin
  select * into o from public.orders where id = (p ->> 'order_id')::uuid for update;
  if not found then
    perform app.fail('order_not_found');
  end if;
  perform app.assert_write_scope(o.store_id);
  update public.orders
     set receipt_printed_at = coalesce(receipt_printed_at, (p ->> 'printed_at')::timestamptz, now())
   where id = o.id
  returning * into o;
  return jsonb_build_object('order_id', o.id, 'receipt_printed_at', o.receipt_printed_at);
end;
$$;

create or replace function app.sync_refund_create(p jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid := (p ->> 'id')::uuid;
  v_amount bigint := (p ->> 'amount')::bigint;
  v_by uuid := (p ->> 'employee_id')::uuid;
  o public.orders%rowtype;
  oi public.order_items%rowtype;
  v_item jsonb;
  v_received bigint;
  v_items_total bigint := 0;
  v_prev bigint;
  v_points integer := 0;
  v_reversed integer;
  v_restock_ids uuid[];
begin
  if exists (select 1 from public.refunds r where r.id = v_id) then
    return jsonb_build_object('refund_id', v_id, 'noop', true);
  end if;

  select * into o from public.orders where id = (p ->> 'order_id')::uuid for update;
  if not found then
    perform app.fail('order_not_found');
  end if;
  perform app.assert_write_scope(o.store_id);
  if o.status <> 'completed' then
    perform app.fail('refund_order_not_completed', 'only completed orders can be refunded');
  end if;
  perform app.assert_actor(v_by, o.store_id, 'pos.sell', 'employee');
  perform app.assert_approver((p ->> 'approved_by')::uuid, o.store_id, 'pos.refund');
  if v_amount is null or v_amount <= 0 then
    perform app.fail('invalid_input', 'amount must be positive');
  end if;

  -- Money actually received: kasbon counts only once it has been repaid.
  v_received := o.paid_total + coalesce((select r.paid_amount from public.receivables r where r.order_id = o.id), 0);
  if o.refunded_total + v_amount > v_received then
    perform app.fail('refund_exceeds_received',
      format('at most Rp %s was received and not yet refunded', v_received - o.refunded_total));
  end if;

  if p ->> 'method_type' = 'cash' then
    perform app.assert_open_shift((p ->> 'shift_id')::uuid, o.store_id);
  end if;

  if jsonb_typeof(p -> 'items') is distinct from 'array' or jsonb_array_length(p -> 'items') = 0 then
    perform app.fail('invalid_input', 'a refund needs at least one item');
  end if;

  for v_item in select value from jsonb_array_elements(p -> 'items') loop
    select * into oi from public.order_items where id = (v_item ->> 'order_item_id')::uuid;
    if not found or oi.order_id <> o.id then
      perform app.fail('refund_item_mismatch', 'the item belongs to another order');
    end if;
    select coalesce(sum(ri.amount), 0) into v_prev from public.refund_items ri where ri.order_item_id = oi.id;
    if v_prev + (v_item ->> 'amount')::bigint > oi.net_amount then
      perform app.fail('refund_item_amount_exceeded',
        format('%s: at most Rp %s left to refund', oi.sku, oi.net_amount - v_prev));
    end if;
    v_items_total := v_items_total + (v_item ->> 'amount')::bigint;
  end loop;
  if v_items_total <> v_amount then
    perform app.fail('refund_totals_mismatch', format('items %s <> amount %s', v_items_total, v_amount));
  end if;

  -- Reverse earned points in proportion to the refund, never more than were earned.
  if o.points_earned > 0 and o.grand_total > 0 then
    select coalesce(-sum(l.points), 0) into v_reversed
    from public.loyalty_ledger l
    where l.order_id = o.id and l.refund_id is not null and l.entry_type = 'reverse_earn';
    v_points := greatest(0, least(floor(o.points_earned::numeric * v_amount / o.grand_total)::integer,
                                  o.points_earned - v_reversed));
  end if;

  -- Lock restocked stock rows in variant order before touching them (deadlock-safe).
  if coalesce((p ->> 'restock')::boolean, true) then
    select coalesce(array_agg(distinct oi2.variant_id), '{}') into v_restock_ids
    from jsonb_array_elements(p -> 'items') x
    join public.order_items oi2 on oi2.id = (x.value ->> 'order_item_id')::uuid;
    perform app.lock_stock_rows(o.store_id, v_restock_ids);
  end if;

  insert into public.refunds (id, order_id, store_id, shift_id, device_id, refund_number, reason, amount,
                              method_type, restock, points_reversed, employee_id, approved_by, refunded_at)
  values (v_id, o.id, o.store_id, (p ->> 'shift_id')::uuid, app.current_device_id(), p ->> 'refund_number',
          trim(p ->> 'reason'), v_amount, p ->> 'method_type', coalesce((p ->> 'restock')::boolean, true),
          v_points, v_by, (p ->> 'approved_by')::uuid, coalesce((p ->> 'refunded_at')::timestamptz, now()));

  for v_item in
    select value from jsonb_array_elements(p -> 'items') order by value ->> 'order_item_id'
  loop
    insert into public.refund_items (id, refund_id, store_id, order_item_id, quantity, amount)
    values ((v_item ->> 'id')::uuid, v_id, o.store_id, (v_item ->> 'order_item_id')::uuid,
            (v_item ->> 'quantity')::numeric, (v_item ->> 'amount')::bigint);
  end loop;

  insert into public.audit_log (occurred_at, store_id, device_id, actor_employee_id, approver_employee_id, action, entity_type, entity_id, details)
  values (coalesce((p ->> 'refunded_at')::timestamptz, now()), o.store_id, app.current_device_id(), v_by,
          (p ->> 'approved_by')::uuid, 'order.refunded', 'order', o.id,
          jsonb_build_object('refund_id', v_id, 'amount', v_amount, 'method_type', p ->> 'method_type',
                             'reason', trim(p ->> 'reason')));

  return jsonb_build_object('refund_id', v_id, 'amount', v_amount, 'points_reversed', v_points);
end;
$$;

create or replace function app.sync_customer_upsert(p jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid := (p ->> 'id')::uuid;
  v_store uuid := coalesce(app.current_device_store_id(), (p ->> 'store_id')::uuid);
  v_c public.customers%rowtype;
  v_dup uuid;
begin
  if v_id is null then
    perform app.fail('invalid_input', 'customer id is required');
  end if;
  if app.is_device() then
    perform app.assert_actor((p ->> 'employee_id')::uuid, v_store, 'customer.manage', 'employee');
  elsif not app.has_permission('customer.manage') then
    perform app.fail('permission_denied', 'customer.manage is required');
  end if;

  select * into v_c from public.customers where id = v_id for update;
  if found then
    update public.customers set
      name = coalesce(nullif(trim(p ->> 'name'), ''), name),
      phone = case when p ? 'phone' then nullif(trim(p ->> 'phone'), '') else phone end,
      email = case when p ? 'email' then nullif(trim(p ->> 'email'), '') else email end,
      birth_date = case when p ? 'birth_date' then (p ->> 'birth_date')::date else birth_date end,
      address = case when p ? 'address' then p ->> 'address' else address end,
      notes = case when p ? 'notes' then p ->> 'notes' else notes end
    where id = v_id
    returning * into v_c;
  else
    insert into public.customers (id, name, phone, email, birth_date, address, notes, created_store_id)
    values (v_id, trim(p ->> 'name'), nullif(trim(p ->> 'phone'), ''), nullif(trim(p ->> 'email'), ''),
            (p ->> 'birth_date')::date, p ->> 'address', p ->> 'notes', v_store)
    returning * into v_c;
  end if;

  if v_c.phone is not null then
    select c.id into v_dup
    from public.customers c
    where c.phone = v_c.phone and c.id <> v_c.id and c.is_active
    limit 1;
    if v_dup is not null then
      insert into public.alerts (store_id, alert_type, severity, reference_type, reference_id, message, details)
      values (v_store, 'CUSTOMER_DUPLICATE', 'info', 'customer', v_c.id,
              format('Phone %s belongs to more than one customer', v_c.phone),
              jsonb_build_object('other_customer_id', v_dup));
    end if;
  end if;

  return jsonb_build_object('customer_id', v_c.id, 'code', v_c.code, 'points_balance', v_c.points_balance);
end;
$$;

create or replace function app.sync_receivable_payment(p jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid := (p ->> 'id')::uuid;
  v_by uuid := (p ->> 'employee_id')::uuid;
  r public.receivables%rowtype;
begin
  if exists (select 1 from public.receivable_payments rp where rp.id = v_id) then
    select rv.* into r from public.receivables rv
    join public.receivable_payments rp on rp.receivable_id = rv.id where rp.id = v_id;
    return jsonb_build_object('payment_id', v_id, 'receivable_id', r.id, 'paid_amount', r.paid_amount,
                              'balance', greatest(r.amount - r.paid_amount, 0), 'status', r.status, 'noop', true);
  end if;

  if (p ->> 'receivable_id') is not null then
    select * into r from public.receivables where id = (p ->> 'receivable_id')::uuid;
  else
    select * into r from public.receivables where order_id = (p ->> 'order_id')::uuid;
  end if;
  if not found then
    perform app.fail('receivable_not_found');
  end if;

  perform app.assert_write_scope(r.store_id);
  perform app.assert_actor(v_by, r.store_id, 'kasbon.manage', 'employee');
  if p ->> 'method_type' = 'cash' then
    perform app.assert_open_shift((p ->> 'shift_id')::uuid, r.store_id);
  end if;

  insert into public.receivable_payments (id, receivable_id, store_id, shift_id, amount, method_type, reference, employee_id, note, paid_at)
  values (v_id, r.id, r.store_id, (p ->> 'shift_id')::uuid, (p ->> 'amount')::bigint, p ->> 'method_type',
          p ->> 'reference', v_by, p ->> 'note', coalesce((p ->> 'paid_at')::timestamptz, now()));

  select * into r from public.receivables where id = r.id;

  insert into public.audit_log (store_id, device_id, actor_employee_id, action, entity_type, entity_id, details)
  values (r.store_id, app.current_device_id(), v_by, 'kasbon.repayment', 'receivable', r.id,
          jsonb_build_object('payment_id', v_id, 'amount', (p ->> 'amount')::bigint, 'method_type', p ->> 'method_type'));

  return jsonb_build_object('payment_id', v_id, 'receivable_id', r.id, 'paid_amount', r.paid_amount,
                            'balance', greatest(r.amount - r.paid_amount, 0), 'status', r.status);
end;
$$;

create or replace function app.sync_stock_adjustment(p jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid := (p ->> 'id')::uuid;
  v_store uuid := (p ->> 'store_id')::uuid;
  v_by uuid := (p ->> 'employee_id')::uuid;
  v_item jsonb;
  v_ids uuid[];
begin
  if exists (select 1 from public.stock_adjustments a where a.id = v_id) then
    return jsonb_build_object('adjustment_id', v_id, 'noop', true);
  end if;
  perform app.assert_write_scope(v_store);
  perform app.assert_actor(v_by, v_store, 'inventory.adjust', 'employee');
  if jsonb_typeof(p -> 'items') is distinct from 'array' or jsonb_array_length(p -> 'items') = 0 then
    perform app.fail('invalid_input', 'an adjustment needs at least one item');
  end if;
  if (p ->> 'approved_by') is not null then
    perform app.assert_approver((p ->> 'approved_by')::uuid, v_store, 'inventory.adjust');
  end if;

  insert into public.stock_adjustments (id, store_id, adjustment_number, reason, note, employee_id, approved_by, occurred_at)
  values (v_id, v_store, p ->> 'adjustment_number', p ->> 'reason', p ->> 'note', v_by,
          (p ->> 'approved_by')::uuid, coalesce((p ->> 'occurred_at')::timestamptz, now()));

  select coalesce(array_agg((x.value ->> 'variant_id')::uuid), '{}') into v_ids
  from jsonb_array_elements(p -> 'items') x;
  perform app.lock_stock_rows(v_store, v_ids);

  for v_item in
    select value from jsonb_array_elements(p -> 'items') order by value ->> 'variant_id'
  loop
    insert into public.stock_adjustment_items (id, adjustment_id, store_id, variant_id, quantity_delta, unit_cost)
    values ((v_item ->> 'id')::uuid, v_id, v_store, (v_item ->> 'variant_id')::uuid,
            (v_item ->> 'quantity_delta')::numeric, (v_item ->> 'unit_cost')::bigint);
  end loop;

  return jsonb_build_object('adjustment_id', v_id, 'lines', jsonb_array_length(p -> 'items'));
end;
$$;

create or replace function app.sync_stock_opname_submit(p jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid := (p ->> 'id')::uuid;
  v_store uuid := (p ->> 'store_id')::uuid;
  v_by uuid := (p ->> 'employee_id')::uuid;
  v_status text;
begin
  select so.status into v_status from public.stock_opnames so where so.id = v_id;
  if v_status = 'completed' then
    return jsonb_build_object('opname_id', v_id, 'noop', true);
  end if;
  perform app.assert_write_scope(v_store);
  perform app.assert_actor(v_by, v_store, 'inventory.opname', 'employee');
  if v_status is not null then
    perform app.fail('opname_exists', 'this opname already exists as ' || v_status);
  end if;
  if jsonb_typeof(p -> 'items') is distinct from 'array' or jsonb_array_length(p -> 'items') = 0 then
    perform app.fail('invalid_input', 'count at least one item');
  end if;

  insert into public.stock_opnames (id, store_id, opname_number, note, created_by)
  values (v_id, v_store, p ->> 'opname_number', p ->> 'note', v_by);

  insert into public.stock_opname_items (opname_id, store_id, variant_id, counted_qty)
  select v_id, v_store, (x.value ->> 'variant_id')::uuid, (x.value ->> 'counted_qty')::numeric
  from jsonb_array_elements(p -> 'items') x;

  return app.complete_opname(v_id, v_by);
end;
$$;

create or replace function app.sync_audit_log(p jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_store uuid := coalesce(app.current_device_store_id(), (p ->> 'store_id')::uuid);
  v_action text := p ->> 'action';
  v_actor uuid;
  v_id uuid := coalesce((p ->> 'id')::uuid, gen_random_uuid());
begin
  perform app.assert_write_scope(v_store);
  if v_action is null or v_action like 'data.%' then
    perform app.fail('invalid_input', 'action is required and data.* is reserved for the database');
  end if;

  v_actor := case when app.is_device() then (p ->> 'actor_employee_id')::uuid else app.current_employee_id() end;
  if v_actor is not null and not app.employee_can_access_store(v_actor, v_store) then
    perform app.fail('permission_denied', 'the actor is not assigned to this store');
  end if;

  -- Events that must carry a valid manager approval.
  if v_action = 'pos.drawer_open_no_sale' then
    perform app.assert_approver((p ->> 'approver_employee_id')::uuid, v_store, 'pos.open_drawer');
  end if;

  insert into public.audit_log (id, occurred_at, store_id, device_id, actor_employee_id, approver_employee_id,
                                action, entity_type, entity_id, details)
  values (v_id, coalesce((p ->> 'occurred_at')::timestamptz, now()), v_store, app.current_device_id(), v_actor,
          (p ->> 'approver_employee_id')::uuid, v_action, p ->> 'entity_type', (p ->> 'entity_id')::uuid,
          coalesce(p -> 'details', '{}'::jsonb))
  on conflict (id) do nothing;

  return jsonb_build_object('audit_id', v_id);
end;
$$;

create or replace function app.sync_dining_table_status(p jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  t public.dining_tables%rowtype;
  v_status text := p ->> 'status';
begin
  select * into t from public.dining_tables where id = (p ->> 'table_id')::uuid for update;
  if not found then
    perform app.fail('table_not_found');
  end if;
  perform app.assert_write_scope(t.store_id);
  perform app.assert_actor((p ->> 'employee_id')::uuid, t.store_id, 'pos.sell', 'employee');
  if v_status is null or v_status not in ('available', 'occupied', 'reserved', 'cleaning') then
    perform app.fail('invalid_input', 'status must be available, occupied, reserved or cleaning');
  end if;
  if v_status in ('available', 'reserved') and t.current_order_id is not null and exists (
       select 1 from public.orders o where o.id = t.current_order_id and o.status in ('open', 'held')) then
    perform app.fail('table_has_open_order', 'close or move the open order first');
  end if;

  update public.dining_tables
     set status = v_status,
         current_order_id = case when v_status = 'occupied' then current_order_id end
   where id = t.id;
  return jsonb_build_object('table_id', t.id, 'status', v_status);
end;
$$;

create or replace function app.sync_kitchen_status(p jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  t public.order_status%rowtype;
  v_status text := p ->> 'status';
  v_by uuid := (p ->> 'employee_id')::uuid;
begin
  select * into t from public.order_status
  where order_id = (p ->> 'order_id')::uuid and station = p ->> 'station'
  for update;
  if not found then
    perform app.fail('ticket_not_found');
  end if;
  perform app.assert_write_scope(t.store_id);
  perform app.assert_actor(v_by, t.store_id, 'kitchen.view', 'employee');
  if v_status is null or v_status not in ('new', 'preparing', 'ready', 'served') then
    perform app.fail('invalid_input', 'status must be new, preparing, ready or served');
  end if;
  if t.status in ('served', 'cancelled') then
    perform app.fail('ticket_closed', 'the ticket is already ' || t.status);
  end if;

  update public.order_status set status = v_status, updated_by = v_by where id = t.id;
  return jsonb_build_object('order_id', t.order_id, 'station', t.station, 'status', v_status);
end;
$$;

create or replace function app.sync_dispatch(p_entity text, p_action text, p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_key text := p_entity || '.' || p_action;
begin
  if v_key = 'shift.open' then return app.sync_shift_open(p_payload);
  elsif v_key = 'shift.close' then return app.sync_shift_close(p_payload);
  elsif v_key = 'cash_movement.create' then return app.sync_cash_movement(p_payload);
  elsif v_key = 'order.upsert' then return app.sync_order_upsert(p_payload);
  elsif v_key = 'order.void' then return app.sync_order_void(p_payload);
  elsif v_key = 'order.mark_printed' then return app.sync_order_mark_printed(p_payload);
  elsif v_key = 'refund.create' then return app.sync_refund_create(p_payload);
  elsif v_key = 'customer.upsert' then return app.sync_customer_upsert(p_payload);
  elsif v_key = 'receivable_payment.create' then return app.sync_receivable_payment(p_payload);
  elsif v_key = 'stock_adjustment.create' then return app.sync_stock_adjustment(p_payload);
  elsif v_key = 'stock_opname.submit' then return app.sync_stock_opname_submit(p_payload);
  elsif v_key = 'audit.log' then return app.sync_audit_log(p_payload);
  elsif v_key = 'dining_table.status' then return app.sync_dining_table_status(p_payload);
  elsif v_key = 'kitchen.status' then return app.sync_kitchen_status(p_payload);
  end if;
  perform app.fail('unknown_entity', v_key);
  return null;
end;
$$;

-- ---------------------------------------------------------------------------
-- The single write entry point for terminals (and back-office operations that
-- mirror terminal actions). Idempotent on p_client_uuid.
--
-- Returns one of:
--   {"status":"applied",   "result":{...}}
--   {"status":"duplicate", "result":{...}}   -- seen before; original result
--   {"status":"rejected",  "code":"...", "message":"..."}  -- business rule; do not auto-retry
-- Transient failures (deadlock, serialization, timeouts) raise an error instead,
-- and the client retries with backoff.
-- ---------------------------------------------------------------------------
create or replace function public.sync_push(p_client_uuid uuid, p_entity text, p_action text, p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_result jsonb;
  v_state text;
  v_message text;
  v_hint text;
  v_code text;
begin
  if p_client_uuid is null or p_entity is null or p_action is null
     or p_payload is null or jsonb_typeof(p_payload) <> 'object' then
    return jsonb_build_object('status', 'rejected', 'code', 'invalid_request',
                              'message', 'client_uuid, entity, action and an object payload are required');
  end if;
  if not app.is_member() then
    return jsonb_build_object('status', 'rejected', 'code', 'not_a_member',
                              'message', 'sign in as staff or pair this terminal first');
  end if;

  select si.result into v_result from public.sync_inbox si where si.client_uuid = p_client_uuid;
  if found then
    return jsonb_build_object('status', 'duplicate', 'result', v_result);
  end if;

  begin
    v_result := coalesce(app.sync_dispatch(p_entity, p_action, p_payload), '{}'::jsonb);
    insert into public.sync_inbox (client_uuid, device_id, auth_user_id, entity, action, result)
    values (p_client_uuid, app.current_device_id(), auth.uid(), p_entity, p_action, v_result);
  exception
    when sqlstate 'P0001' or integrity_constraint_violation or data_exception then
      get stacked diagnostics v_state = returned_sqlstate, v_message = message_text, v_hint = pg_exception_hint;

      -- A concurrent call with the same client_uuid committed first.
      select si.result into v_result from public.sync_inbox si where si.client_uuid = p_client_uuid;
      if found then
        return jsonb_build_object('status', 'duplicate', 'result', v_result);
      end if;

      v_code := case when v_state = 'P0001'
                     then coalesce(nullif(v_hint, ''), split_part(v_message, ':', 1))
                     else 'db_' || v_state end;
      insert into public.sync_rejections (client_uuid, device_id, auth_user_id, entity, action, error_code, error_message, payload)
      values (p_client_uuid, app.current_device_id(), auth.uid(), p_entity, p_action, v_code, v_message, p_payload);
      return jsonb_build_object('status', 'rejected', 'code', v_code, 'message', v_message, 'sqlstate', v_state);
  end;

  update public.devices set last_seen_at = now() where id = app.current_device_id();
  return jsonb_build_object('status', 'applied', 'result', v_result);
end;
$$;

-- ---------------------------------------------------------------------------
-- Inventory RPCs (back office; terminals pass p_employee_id of the PIN user)
-- ---------------------------------------------------------------------------
create or replace function app.resolve_actor(p_employee_id uuid)
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select case when app.is_device() then p_employee_id else app.current_employee_id() end
$$;

create or replace function public.request_stock_transfer(
  p_from_store_id uuid,
  p_to_store_id uuid,
  p_items jsonb,
  p_note text default null,
  p_employee_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := app.resolve_actor(p_employee_id);
  v_transfer public.stock_transfers%rowtype;
begin
  if app.is_device() then
    perform app.assert_write_scope(p_to_store_id);
  end if;
  perform app.assert_actor(v_actor, p_to_store_id, 'transfer.request', 'employee');
  if p_from_store_id is null or p_from_store_id = p_to_store_id then
    perform app.fail('invalid_input', 'choose a different source store');
  end if;
  if jsonb_typeof(p_items) is distinct from 'array' or jsonb_array_length(p_items) = 0 then
    perform app.fail('invalid_input', 'a transfer needs at least one item');
  end if;

  insert into public.stock_transfers (from_store_id, to_store_id, note, requested_by)
  values (p_from_store_id, p_to_store_id, p_note, v_actor)
  returning * into v_transfer;

  insert into public.stock_transfer_items (transfer_id, variant_id, quantity_requested)
  select v_transfer.id, (x.value ->> 'variant_id')::uuid, (x.value ->> 'quantity')::numeric
  from jsonb_array_elements(p_items) x;

  insert into public.audit_log (store_id, device_id, actor_employee_id, action, entity_type, entity_id, details)
  values (p_to_store_id, app.current_device_id(), v_actor, 'transfer.requested', 'stock_transfer', v_transfer.id,
          jsonb_build_object('from_store_id', p_from_store_id, 'lines', jsonb_array_length(p_items)));

  return jsonb_build_object('transfer_id', v_transfer.id, 'transfer_number', v_transfer.transfer_number,
                            'status', v_transfer.status);
end;
$$;

-- p_items (optional): [{"variant_id":..., "quantity":...}] = shipped quantities
-- (in_transit) or received quantities (received). Missing lines default to the
-- requested / shipped quantity.
create or replace function public.transition_stock_transfer(
  p_transfer_id uuid,
  p_status text,
  p_items jsonb default null,
  p_note text default null,
  p_employee_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  t public.stock_transfers%rowtype;
  v_actor uuid := app.resolve_actor(p_employee_id);
  v_items jsonb := coalesce(p_items, '[]'::jsonb);
begin
  select * into t from public.stock_transfers where id = p_transfer_id for update;
  if not found then
    perform app.fail('transfer_not_found');
  end if;

  if p_status in ('approved', 'rejected', 'in_transit') then
    if app.is_device() then
      perform app.assert_write_scope(t.from_store_id);
    end if;
    perform app.assert_actor(v_actor, t.from_store_id, 'transfer.approve', 'employee');
  elsif p_status = 'received' then
    if app.is_device() then
      perform app.assert_write_scope(t.to_store_id);
    end if;
    perform app.assert_actor(v_actor, t.to_store_id, 'inventory.receive', 'employee');
  elsif p_status = 'cancelled' then
    if v_actor is null then
      perform app.fail('invalid_input', 'employee is required');
    end if;
    if app.is_device() and app.current_device_store_id() not in (t.from_store_id, t.to_store_id) then
      perform app.fail('store_mismatch', 'this terminal is not part of the transfer');
    end if;
    if not (v_actor = t.requested_by
            or app.employee_can(v_actor, t.from_store_id, 'transfer.approve')
            or app.employee_can(v_actor, t.to_store_id, 'transfer.approve')) then
      perform app.fail('permission_denied', 'only the requester or an approver can cancel');
    end if;
  else
    perform app.fail('invalid_input', 'status must be approved, rejected, in_transit, received or cancelled');
  end if;

  if p_status = 'approved' then
    update public.stock_transfers
       set status = 'approved', approved_by = v_actor, approved_at = now(), note = coalesce(p_note, note)
     where id = t.id;
  elsif p_status = 'rejected' then
    if coalesce(length(trim(p_note)), 0) < 3 then
      perform app.fail('invalid_input', 'a rejection reason is required');
    end if;
    update public.stock_transfers
       set status = 'rejected', rejected_by = v_actor, rejected_at = now(), reject_reason = trim(p_note)
     where id = t.id;
  elsif p_status = 'in_transit' then
    update public.stock_transfer_items i
       set quantity_shipped = coalesce(
         (select (x.value ->> 'quantity')::numeric from jsonb_array_elements(v_items) x
          where (x.value ->> 'variant_id')::uuid = i.variant_id limit 1),
         i.quantity_requested)
     where i.transfer_id = t.id;
    update public.stock_transfers
       set status = 'in_transit', shipped_by = v_actor, shipped_at = now()
     where id = t.id;
  elsif p_status = 'received' then
    update public.stock_transfer_items i
       set quantity_received = coalesce(
         (select (x.value ->> 'quantity')::numeric from jsonb_array_elements(v_items) x
          where (x.value ->> 'variant_id')::uuid = i.variant_id limit 1),
         i.quantity_shipped, 0)
     where i.transfer_id = t.id;
    update public.stock_transfers
       set status = 'received', received_by = v_actor, received_at = now()
     where id = t.id;
  elsif p_status = 'cancelled' then
    update public.stock_transfers
       set status = 'cancelled', cancelled_by = v_actor, cancelled_at = now()
     where id = t.id;
  end if;

  insert into public.audit_log (store_id, device_id, actor_employee_id, action, entity_type, entity_id, details)
  values (case when p_status = 'received' then t.to_store_id else t.from_store_id end,
          app.current_device_id(), v_actor, 'transfer.' || p_status, 'stock_transfer', t.id,
          jsonb_build_object('transfer_number', t.transfer_number, 'note', p_note));

  return jsonb_build_object('transfer_id', t.id, 'status', p_status);
end;
$$;

create or replace function public.complete_stock_opname(p_opname_id uuid, p_employee_id uuid default null)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_store uuid;
  v_actor uuid := app.resolve_actor(p_employee_id);
begin
  select so.store_id into v_store from public.stock_opnames so where so.id = p_opname_id;
  if v_store is null then
    perform app.fail('opname_not_found');
  end if;
  perform app.assert_write_scope(v_store);
  perform app.assert_actor(v_actor, v_store, 'inventory.opname', 'employee');
  return app.complete_opname(p_opname_id, v_actor);
end;
$$;

-- ---------------------------------------------------------------------------
-- Shift summary: the data behind the X-report (open shift) and Z-report (closed)
-- ---------------------------------------------------------------------------
create or replace function public.shift_summary(p_shift_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  s public.shifts%rowtype;
begin
  select * into s from public.shifts where id = p_shift_id;
  if not found then
    perform app.fail('shift_not_found');
  end if;
  if not (s.store_id = any (app.store_ids_with(array['shift.manage', 'reports.view']))) then
    perform app.fail('permission_denied', 'shift.manage or reports.view is required for this store');
  end if;

  return jsonb_build_object(
    'report', case when s.status = 'open' then 'X' else 'Z' end,
    'shift', jsonb_build_object(
      'id', s.id, 'store_id', s.store_id, 'device_id', s.device_id, 'status', s.status,
      'business_date', s.business_date, 'opened_by', s.opened_by, 'opened_at', s.opened_at,
      'closed_by', s.closed_by, 'closed_at', s.closed_at),
    'sales', (
      select jsonb_build_object(
        'orders', count(*),
        'gross_total', coalesce(sum(o.gross_total), 0),
        'discount_total', coalesce(sum(o.item_discount_total + o.bill_discount_total + o.points_discount), 0),
        'net_total', coalesce(sum(o.net_total), 0),
        'service_charge_total', coalesce(sum(o.service_charge_total), 0),
        'tax_total', coalesce(sum(o.tax_total), 0),
        'rounding_total', coalesce(sum(o.rounding_amount), 0),
        'grand_total', coalesce(sum(o.grand_total), 0),
        'average_basket', coalesce(round(avg(o.grand_total)), 0))
      from public.orders o
      where o.shift_id = s.id and o.status = 'completed'),
    'voids', (
      select jsonb_build_object('orders', count(*), 'grand_total', coalesce(sum(o.grand_total), 0))
      from public.orders o
      where o.voided_shift_id = s.id and o.status = 'voided'),
    'cancelled_orders', (
      select count(*) from public.orders o where o.shift_id = s.id and o.status = 'cancelled'),
    'payments', (
      select coalesce(jsonb_agg(jsonb_build_object(
               'payment_method_id', x.payment_method_id, 'name', x.name, 'method_type', x.method_type,
               'count', x.n, 'amount', x.amount) order by x.sort_order), '[]'::jsonb)
      from (
        select p.payment_method_id, pm.name, p.method_type, pm.sort_order, count(*) as n, sum(p.amount) as amount
        from public.payments p
        join public.orders o on o.id = p.order_id
        join public.payment_methods pm on pm.id = p.payment_method_id
        where p.shift_id = s.id and p.status = 'paid' and o.status = 'completed'
        group by p.payment_method_id, pm.name, p.method_type, pm.sort_order
      ) x),
    'refunds', (
      select jsonb_build_object(
        'count', count(*),
        'amount', coalesce(sum(r.amount), 0),
        'cash_amount', coalesce(sum(r.amount) filter (where r.method_type = 'cash'), 0))
      from public.refunds r where r.shift_id = s.id),
    'kasbon', jsonb_build_object(
      'issued', (select coalesce(sum(p.amount), 0) from public.payments p
                 join public.orders o on o.id = p.order_id
                 where p.shift_id = s.id and p.method_type = 'kasbon' and o.status = 'completed'),
      'repaid', (select coalesce(sum(rp.amount), 0) from public.receivable_payments rp where rp.shift_id = s.id),
      'repaid_cash', (select coalesce(sum(rp.amount), 0) from public.receivable_payments rp
                      where rp.shift_id = s.id and rp.method_type = 'cash')),
    'cash', jsonb_build_object(
      'opening_cash', s.opening_cash,
      'cash_sales', (select coalesce(sum(p.amount), 0) from public.payments p
                     where p.shift_id = s.id and p.method_type = 'cash' and p.status = 'paid'),
      'voided_cash', (select coalesce(sum(p.amount), 0) from public.payments p
                      join public.orders o on o.id = p.order_id
                      where o.voided_shift_id = s.id and p.method_type = 'cash' and p.status = 'paid'),
      'cash_refunds', (select coalesce(sum(r.amount), 0) from public.refunds r
                       where r.shift_id = s.id and r.method_type = 'cash'),
      'kasbon_cash', (select coalesce(sum(rp.amount), 0) from public.receivable_payments rp
                      where rp.shift_id = s.id and rp.method_type = 'cash'),
      'cash_in', (select coalesce(sum(cm.amount), 0) from public.cash_movements cm
                  where cm.shift_id = s.id and cm.movement_type = 'in'),
      'cash_out', (select coalesce(sum(cm.amount), 0) from public.cash_movements cm
                   where cm.shift_id = s.id and cm.movement_type = 'out'),
      'expected_cash', app.shift_expected_cash(s.id),
      'counted_cash', s.counted_cash,
      'cash_difference', s.cash_difference),
    'top_items', (
      select coalesce(jsonb_agg(jsonb_build_object('variant_id', x.variant_id, 'name', x.name,
                                                   'quantity', x.qty, 'net_amount', x.net)
                                order by x.qty desc, x.name), '[]'::jsonb)
      from (
        select oi.variant_id,
               min(oi.product_name || coalesce(' ' || nullif(oi.variant_name, 'Default'), '')) as name,
               sum(oi.quantity - oi.refunded_quantity) as qty,
               sum(oi.net_amount) as net
        from public.order_items oi
        join public.orders o on o.id = oi.order_id
        where o.shift_id = s.id and o.status = 'completed'
        group by oi.variant_id
        order by sum(oi.quantity - oi.refunded_quantity) desc, min(oi.product_name)
        limit 10
      ) x)
  );
end;
$$;
