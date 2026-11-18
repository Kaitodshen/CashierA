-- =============================================================================
-- Staff invitations and the staff overview for the back office.
--
-- The staff-invite Edge Function first calls prepare_staff_invite as the
-- signed-in person (so the usual "who may manage whom" rules apply), then
-- invites the email with the service role and links the new login with
-- link_staff_login, which only the service role may run.
--
-- staff_overview tells the back office who has a PIN and who has set a
-- password, since employee_pins and auth.users are not readable by clients.
-- =============================================================================

-- True when the employee already has an unconfirmed login with this email
-- (the invitation is sent again); false for a first invitation.
create or replace function public.prepare_staff_invite(p_employee_id uuid, p_email text)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := app.current_employee_id();
  v_email text := lower(trim(coalesce(p_email, '')));
  v_target public.employees%rowtype;
  v_login_email text;
  v_login_confirmed timestamptz;
begin
  if v_actor is null or not app.can_manage_employee(v_actor, p_employee_id) then
    perform app.fail('permission_denied', 'you cannot invite this employee');
  end if;

  select * into v_target from public.employees where id = p_employee_id;
  if not found then
    perform app.fail('not_found', 'employee not found');
  end if;

  if v_email !~* '^[^@\s]+@[^@\s]+\.[^@\s]+$' then
    perform app.fail('invalid_email', 'not an email address');
  end if;

  if v_target.auth_user_id is not null then
    select lower(u.email), u.email_confirmed_at into v_login_email, v_login_confirmed
    from auth.users u where u.id = v_target.auth_user_id;
    if v_login_confirmed is not null or v_login_email is distinct from v_email then
      perform app.fail('already_linked', 'this employee already has a login');
    end if;
    return true;
  end if;

  if exists (select 1 from public.employees e where lower(e.email) = v_email and e.id <> p_employee_id)
     or exists (select 1 from auth.users u where lower(u.email) = v_email) then
    perform app.fail('email_taken', 'this email already belongs to someone');
  end if;

  return false;
end;
$$;

-- Service role only: attach the invited login to the employee.
create or replace function public.link_staff_login(p_employee_id uuid, p_auth_user_id uuid, p_email text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if exists (
    select 1 from public.employees
    where id = p_employee_id and auth_user_id is not null and auth_user_id <> p_auth_user_id
  ) then
    perform app.fail('already_linked', 'this employee already has a login');
  end if;

  update public.employees
     set auth_user_id = p_auth_user_id, email = lower(trim(p_email)), updated_at = now()
   where id = p_employee_id;
  if not found then
    perform app.fail('not_found', 'employee not found');
  end if;

  insert into public.audit_log (action, entity_type, entity_id, details)
  values ('employee.invited', 'employee', p_employee_id, jsonb_build_object('email', lower(trim(p_email))));
end;
$$;

-- PIN and login state of the employees the caller may see.
create or replace function public.staff_overview()
returns table (employee_id uuid, has_pin boolean, login_confirmed boolean)
language sql
stable
security definer
set search_path = ''
as $$
  select e.id,
         exists (select 1 from public.employee_pins p where p.employee_id = e.id),
         coalesce((select u.email_confirmed_at is not null from auth.users u where u.id = e.auth_user_id), false)
  from public.employees e
  where app.can_see_employee(e.id);
$$;

revoke execute on function public.prepare_staff_invite(uuid, text),
  public.link_staff_login(uuid, uuid, text),
  public.staff_overview()
  from public, anon, authenticated;
grant execute on function public.prepare_staff_invite(uuid, text), public.staff_overview()
  to authenticated, service_role;
grant execute on function public.link_staff_login(uuid, uuid, text) to service_role;
