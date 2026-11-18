-- Staff invitations: who may invite whom, the service-role link, and the
-- PIN / login overview the back office reads.
begin;
create extension if not exists pgtap with schema extensions;
select plan(13);

create or replace function pg_temp.act_as_service()
returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);
  perform set_config('request.jwt.claim.sub', '', true);
  perform set_config('role', 'service_role', true);
end;
$$;

select tests.act_as_postgres();
grant usage on schema tests to service_role;
grant execute on all functions in schema tests to service_role;

-- The owner may invite anyone without a login.
select tests.act_as(tests.id('user.owner'));
select is(public.prepare_staff_invite(tests.id('emp.fitri'), 'fitri@toko.id'), false,
  'owner: a first invitation is not a resend');

-- A manager may invite staff of their own store only, never all-stores people.
select tests.act_as(tests.id('user.manager_pst'));
select is(public.prepare_staff_invite(tests.id('emp.fitri'), 'fitri@toko.id'), false,
  'PST manager may invite a PST cashier');
select throws_like($$ select public.prepare_staff_invite(tests.id('emp.gilang'), 'gilang@toko.id') $$,
  'permission_denied%', 'PST manager may not invite BKS staff');
select throws_like($$ select public.prepare_staff_invite(tests.id('emp.owner'), 'x@toko.id') $$,
  'permission_denied%', 'a manager may not invite an all-stores person');

-- Refusals the owner sees.
select tests.act_as(tests.id('user.owner'));
select throws_like($$ select public.prepare_staff_invite(tests.id('emp.eko'), 'eko2@toko.id') $$,
  'already_linked%', 'someone with a confirmed login cannot be invited again');
select throws_like($$ select public.prepare_staff_invite(tests.id('emp.fitri'), 'bukan-email') $$,
  'invalid_email%', 'a malformed email is refused');
select throws_like($$ select public.prepare_staff_invite(tests.id('emp.fitri'), 'OWNER@cashiera.test') $$,
  'email_taken%', 'an email that belongs to another login is refused');

-- Linking is for the service role only.
select throws_like($$ select public.link_staff_login(tests.id('emp.fitri'), gen_random_uuid(), 'f@toko.id') $$,
  '%permission denied%', 'signed-in staff cannot link logins themselves');

select tests.act_as_postgres();
insert into auth.users (id, email, aud, role)
values ('21000000-0000-4000-8000-000000000001', 'fitri@toko.id', 'authenticated', 'authenticated');

select pg_temp.act_as_service();
select lives_ok($$ select public.link_staff_login(tests.id('emp.fitri'),
  '21000000-0000-4000-8000-000000000001', 'Fitri@Toko.id') $$, 'the service role links the new login');

select tests.act_as_postgres();
select is(
  (select email || ' ' || auth_user_id::text from public.employees where id = tests.id('emp.fitri')),
  'fitri@toko.id 21000000-0000-4000-8000-000000000001',
  'the email is stored lower-case with the login');
select is((select count(*)::int from public.audit_log
           where action = 'employee.invited' and entity_id = tests.id('emp.fitri')), 1,
  'the invitation is in the audit log');

-- Not confirmed yet: inviting again is a resend.
select tests.act_as(tests.id('user.owner'));
select is(public.prepare_staff_invite(tests.id('emp.fitri'), 'fitri@toko.id'), true,
  'an unconfirmed login can be invited again');

-- The overview: a manager sees their store's staff, with PIN and login state.
select tests.act_as(tests.id('user.manager_pst'));
select ok(
  (select bool_and(o.has_pin) from public.staff_overview() o
   where o.employee_id in (tests.id('emp.eko'), tests.id('emp.fitri')))
  and not exists (select 1 from public.staff_overview() o where o.employee_id = tests.id('emp.gilang')),
  'PST manager sees PST staff with their PINs, and no BKS staff');

select * from finish();
rollback;
