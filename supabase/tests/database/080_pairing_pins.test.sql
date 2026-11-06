-- Terminal pairing (one-time code + anonymous sign-in), staff roster for
-- offline PIN checks, online PIN verification with lockout, PIN management,
-- current_principal, revocation.
begin;
create extension if not exists pgtap with schema extensions;
select plan(23);

create temporary table t_code (code text);
grant select, insert on t_code to authenticated;

insert into auth.users (id, aud, role, is_anonymous, created_at, updated_at) values
  (tests.uuid('080:new-terminal'),    'authenticated', 'authenticated', true, now(), now()),
  (tests.uuid('080:second-terminal'), 'authenticated', 'authenticated', true, now(), now());

-- Pairing ------------------------------------------------------------------------------------
select tests.act_as(tests.id('user.manager_pst'));
insert into t_code select public.create_device_pairing_code(tests.id('store.pst'), 'Kasir 2 Pusat') ->> 'code';
select is((select length(code) from t_code), 8, 'the manager gets an 8-character pairing code');

select tests.act_as(tests.id('user.cashier_pst'));
select throws_like($$select public.create_device_pairing_code(tests.id('store.pst'), 'Tablet X')$$,
  'permission_denied%', 'cashiers cannot create pairing codes');

select tests.act_as(tests.uuid('080:new-terminal'));
select is(public.pair_device((select code from t_code), 'android', '0.1.0') ->> 'device_code', 'T2',
  'the new terminal pairs as T2');
select is((select array_agg(code) from public.stores), array['PST'],
  'the paired terminal sees its store');
select is(public.current_principal() ->> 'kind', 'device',
  'current_principal identifies a terminal');
select is((select count(*)::int from public.device_staff()), 5,
  'the roster has the owner and the 4 PST staff');
select is((select count(*)::int from public.device_staff() where employee_id = tests.id('emp.gilang')), 0,
  'the roster excludes other stores'' staff');
select is(public.verify_employee_pin(tests.id('emp.eko'), '482913') ->> 'ok', 'true',
  'a correct PIN verifies online');
select is(public.verify_employee_pin(tests.id('emp.eko'), '000001') ->> 'reason', 'mismatch',
  'a wrong PIN is rejected');
select throws_like($$select public.verify_employee_pin(tests.id('emp.gilang'), '604135')$$,
  'permission_denied%', 'terminals cannot check PINs of other stores');

select tests.act_as(tests.uuid('080:second-terminal'));
select throws_like($$select public.pair_device((select code from t_code))$$,
  'pairing_code_invalid%', 'a pairing code works only once');

select tests.act_as_postgres();
select ok(
  (select extensions.crypt('482913', pin_hash) = pin_hash from public.employee_pins where employee_id = tests.id('emp.eko')),
  'PINs are stored as bcrypt hashes the terminal can check offline');

-- Lockout ----------------------------------------------------------------------------------------
select tests.act_as(tests.id('user.device_pst'));
select public.verify_employee_pin(tests.id('emp.fitri'), '000000') from generate_series(1, 5);
select is(public.verify_employee_pin(tests.id('emp.fitri'), '593024') ->> 'reason', 'locked',
  'five wrong PINs lock the employee for 5 minutes');

-- PIN management -------------------------------------------------------------------------------------
select tests.act_as(tests.id('user.manager_pst'));
select lives_ok($$select public.set_employee_pin(tests.id('emp.fitri'), '809172')$$,
  'the manager resets a cashier''s PIN');
select throws_like($$select public.set_employee_pin(tests.id('emp.fitri'), '1111')$$,
  'weak_pin%', 'repeated-digit PINs are refused');
select throws_like($$select public.set_employee_pin(tests.id('emp.owner'), '809172')$$,
  'permission_denied%', 'a manager cannot change the owner''s PIN');
select throws_like($$select public.set_employee_pin(tests.id('emp.gilang'), '809172')$$,
  'permission_denied%', 'a manager cannot change PINs in another store');
select tests.act_as(tests.id('user.device_pst'));
select is(public.verify_employee_pin(tests.id('emp.fitri'), '809172') ->> 'ok', 'true',
  'the new PIN works and the lock is cleared');

-- Principal of a manager ------------------------------------------------------------------------------
select tests.act_as(tests.id('user.manager_pst'));
select ok((public.current_principal() -> 'permissions') ? 'pos.refund',
  'the manager''s principal carries approval permissions');
select is(public.current_principal() -> 'store_ids', jsonb_build_array(tests.id('store.pst')),
  'the manager''s principal is scoped to PST');

-- Revocation -------------------------------------------------------------------------------------------
select lives_ok(
  $$select public.revoke_device((select id from public.devices where auth_user_id = tests.uuid('080:new-terminal')), 'Tablet hilang')$$,
  'the manager revokes the new terminal');
select tests.act_as(tests.uuid('080:new-terminal'));
select is((select count(*)::int from public.stores), 0,
  'the revoked terminal sees nothing');
select tests.act_as(tests.id('user.cashier_pst'));
select throws_like($$select public.revoke_device(tests.id('device.pst'))$$,
  'permission_denied%', 'cashiers cannot revoke terminals');

select * from finish();
rollback;
