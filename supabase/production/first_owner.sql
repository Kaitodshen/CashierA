-- =============================================================================
-- CashierA · first owner (production, run ONCE in the Supabase SQL Editor)
--
-- A new project has no employees, so nobody can sign in to the back office
-- yet. This turns one email login into the first owner; everything after
-- that is done from the app.
--
-- Before running:
--   1. Dashboard → Authentication → Users → Add user → Create new user.
--      Type the owner's email and a strong password, tick "Auto Confirm User".
--   2. Change the four values in the DECLARE block below, then click Run.
--
-- Safe to run again: it refuses if the login is missing, is already an
-- employee, or if an owner already exists. It never touches demo data
-- (there is none in production).
-- =============================================================================
do $$
declare
  -- ↓↓↓ change these ↓↓↓
  v_email    text := 'owner@contoh.com';       -- the login made in step 1
  v_name     text := 'Nama Lengkap Owner';
  v_phone    text := '';                        -- optional, e.g. '081234567890'
  v_business text := 'Nama Usaha';              -- shown on receipts and reports
  -- ↑↑↑ change these ↑↑↑
  v_user uuid;
  v_role uuid;
begin
  if v_email = 'owner@contoh.com' or v_name = 'Nama Lengkap Owner' then
    raise exception 'Ganti dulu email dan nama owner di bagian DECLARE.';
  end if;

  select id into v_user from auth.users where lower(email) = lower(trim(v_email));
  if v_user is null then
    raise exception 'Akun % belum ada. Buat dulu di Authentication → Users → Add user.', v_email;
  end if;

  if exists (select 1 from public.employees where auth_user_id = v_user) then
    raise exception 'Akun % sudah terdaftar sebagai karyawan.', v_email;
  end if;

  if exists (
    select 1 from public.employees e join public.roles r on r.id = e.role_id
    where r.code = 'owner'
  ) then
    raise exception 'Sudah ada owner. Script ini hanya untuk owner pertama; tambah staf dari aplikasi.';
  end if;

  select id into v_role from public.roles where code = 'owner';

  insert into public.employees (auth_user_id, role_id, full_name, email, phone)
  values (v_user, v_role, trim(v_name), lower(trim(v_email)), nullif(trim(v_phone), ''));

  if trim(v_business) <> '' and v_business <> 'Nama Usaha' then
    update public.business_profile set name = trim(v_business) where id = 1;
  end if;

  raise notice 'Selesai: % adalah owner. Silakan login ke back office.', trim(v_name);
end $$;
