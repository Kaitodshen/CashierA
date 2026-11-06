-- =============================================================================
-- CashierA · demo seed (local development and tests only, never production)
--
-- 3 stores, 11 staff, 3 paired demo terminals, 43 products / 46 SKUs with
-- stock, customers with points, promotions, vouchers, printers, expenses.
-- Replace with your real catalog later via docs/templates/products-template.csv.
--
-- Demo sign-ins (local Supabase only):
--   back office (email + password), password for every account: CashierA-Demo-2026
--     owner@cashiera.test        Andi Pratama    (Owner, all stores)
--     manager.pst@cashiera.test  Budi Santoso    (Manager, PST)
--     manager.bks@cashiera.test  Citra Lestari   (Manager, BKS)
--     manager.tgr@cashiera.test  Dewi Anggraini  (Manager, TGR)
--     kasir.pst@cashiera.test    Eko Saputra     (Cashier, PST)
--   terminal PINs:
--     Andi 135790 · Budi 246802 · Citra 357913 · Dewi 468024
--     Eko 482913 · Fitri 593024 (PST) · Gilang 604135 · Hana 715246 (BKS)
--     Indra 826357 · Joko 937468 (TGR) · Kurniawan 159260 (Inventory, PST)
--
-- Deterministic ids (tests rely on them):
--   stores    a0000000-0000-4000-8000-00000000000{1,2,3}   PST, BKS, TGR
--   people    b0000000-...  auth users  ·  e0000000-...  employees (same suffix)
--   terminals b1000000-...  auth users  ·  d0000000-...  devices
--   catalog   md5('cashiera:product:<key>')::uuid, md5('cashiera:variant:<sku>')::uuid
-- =============================================================================

-- Company ------------------------------------------------------------------------
update public.business_profile
   set name = 'CashierA',
       legal_name = 'PT CashierA Ritel Nusantara (demo)',
       address = 'Jl. Contoh Raya No. 1, Jakarta Selatan',
       phone = '021-5550100',
       email = 'halo@cashiera.test'
 where id = 1;

-- Stores (settings and payment methods are created by trigger) --------------------
insert into public.stores (id, code, name, address, phone, timezone) values
  ('a0000000-0000-4000-8000-000000000001', 'PST', 'CashierA Pusat',     'Jl. Contoh Raya No. 1, Jakarta Selatan', '021-5550101', 'Asia/Jakarta'),
  ('a0000000-0000-4000-8000-000000000002', 'BKS', 'CashierA Bekasi',    'Jl. Contoh Timur No. 22, Bekasi',        '021-5550102', 'Asia/Jakarta'),
  ('a0000000-0000-4000-8000-000000000003', 'TGR', 'CashierA Tangerang', 'Jl. Contoh Barat No. 7, Tangerang',      '021-5550103', 'Asia/Jakarta');

update public.store_settings
   set receipt_header = s.name || E'\n' || s.address || E'\nTelp ' || s.phone,
       receipt_paper_mm = case s.code when 'TGR' then 80 else 58 end
  from public.stores s
 where s.id = store_settings.store_id;

-- Auth users (email accounts) -----------------------------------------------------
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, email_change, email_change_token_new, recovery_token)
select '00000000-0000-0000-0000-000000000000', u.id, 'authenticated', 'authenticated', u.email,
       extensions.crypt('CashierA-Demo-2026', extensions.gen_salt('bf')), now(),
       '{"provider":"email","providers":["email"]}'::jsonb, jsonb_build_object('full_name', u.full_name),
       now(), now(), '', '', '', ''
from (values
  ('b0000000-0000-4000-8000-000000000001'::uuid, 'owner@cashiera.test',       'Andi Pratama'),
  ('b0000000-0000-4000-8000-000000000011'::uuid, 'manager.pst@cashiera.test', 'Budi Santoso'),
  ('b0000000-0000-4000-8000-000000000012'::uuid, 'manager.bks@cashiera.test', 'Citra Lestari'),
  ('b0000000-0000-4000-8000-000000000013'::uuid, 'manager.tgr@cashiera.test', 'Dewi Anggraini'),
  ('b0000000-0000-4000-8000-000000000021'::uuid, 'kasir.pst@cashiera.test',   'Eko Saputra')
) as u(id, email, full_name);

insert into auth.identities (id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
select gen_random_uuid(), u.id, u.id::text,
       jsonb_build_object('sub', u.id::text, 'email', u.email, 'email_verified', true),
       'email', now(), now(), now()
from auth.users u
where u.email like '%@cashiera.test';

-- Auth users for the three demo terminals (anonymous sign-ins)
insert into auth.users (instance_id, id, aud, role, is_anonymous, raw_app_meta_data, raw_user_meta_data,
                        created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
select '00000000-0000-0000-0000-000000000000', d.id, 'authenticated', 'authenticated', true,
       '{}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', ''
from (values
  ('b1000000-0000-4000-8000-000000000001'::uuid),
  ('b1000000-0000-4000-8000-000000000002'::uuid),
  ('b1000000-0000-4000-8000-000000000003'::uuid)
) as d(id);

-- Employees --------------------------------------------------------------------------
insert into public.employees (id, auth_user_id, role_id, full_name, email, phone)
select e.id, e.auth_user_id, r.id, e.full_name, e.email, e.phone
from (values
  ('e0000000-0000-4000-8000-000000000001'::uuid, 'b0000000-0000-4000-8000-000000000001'::uuid, 'owner',     'Andi Pratama',    'owner@cashiera.test',       '081211110001'),
  ('e0000000-0000-4000-8000-000000000011'::uuid, 'b0000000-0000-4000-8000-000000000011'::uuid, 'manager',   'Budi Santoso',    'manager.pst@cashiera.test', '081211110011'),
  ('e0000000-0000-4000-8000-000000000012'::uuid, 'b0000000-0000-4000-8000-000000000012'::uuid, 'manager',   'Citra Lestari',   'manager.bks@cashiera.test', '081211110012'),
  ('e0000000-0000-4000-8000-000000000013'::uuid, 'b0000000-0000-4000-8000-000000000013'::uuid, 'manager',   'Dewi Anggraini',  'manager.tgr@cashiera.test', '081211110013'),
  ('e0000000-0000-4000-8000-000000000021'::uuid, 'b0000000-0000-4000-8000-000000000021'::uuid, 'cashier',   'Eko Saputra',     'kasir.pst@cashiera.test',   '081211110021'),
  ('e0000000-0000-4000-8000-000000000022'::uuid, null,                                         'cashier',   'Fitri Handayani', null,                        '081211110022'),
  ('e0000000-0000-4000-8000-000000000023'::uuid, null,                                         'cashier',   'Gilang Ramadhan', null,                        '081211110023'),
  ('e0000000-0000-4000-8000-000000000024'::uuid, null,                                         'cashier',   'Hana Puspita',    null,                        '081211110024'),
  ('e0000000-0000-4000-8000-000000000025'::uuid, null,                                         'cashier',   'Indra Wijaya',    null,                        '081211110025'),
  ('e0000000-0000-4000-8000-000000000026'::uuid, null,                                         'cashier',   'Joko Susilo',     null,                        '081211110026'),
  ('e0000000-0000-4000-8000-000000000031'::uuid, null,                                         'inventory', 'Kurniawan Hadi',  null,                        '081211110031')
) as e(id, auth_user_id, role_code, full_name, email, phone)
join public.roles r on r.code = e.role_code;

insert into public.employee_stores (employee_id, store_id) values
  ('e0000000-0000-4000-8000-000000000011', 'a0000000-0000-4000-8000-000000000001'),
  ('e0000000-0000-4000-8000-000000000012', 'a0000000-0000-4000-8000-000000000002'),
  ('e0000000-0000-4000-8000-000000000013', 'a0000000-0000-4000-8000-000000000003'),
  ('e0000000-0000-4000-8000-000000000021', 'a0000000-0000-4000-8000-000000000001'),
  ('e0000000-0000-4000-8000-000000000022', 'a0000000-0000-4000-8000-000000000001'),
  ('e0000000-0000-4000-8000-000000000023', 'a0000000-0000-4000-8000-000000000002'),
  ('e0000000-0000-4000-8000-000000000024', 'a0000000-0000-4000-8000-000000000002'),
  ('e0000000-0000-4000-8000-000000000025', 'a0000000-0000-4000-8000-000000000003'),
  ('e0000000-0000-4000-8000-000000000026', 'a0000000-0000-4000-8000-000000000003'),
  ('e0000000-0000-4000-8000-000000000031', 'a0000000-0000-4000-8000-000000000001');

insert into public.employee_pins (employee_id, pin_hash)
select p.employee_id, extensions.crypt(p.pin, extensions.gen_salt('bf', 10))
from (values
  ('e0000000-0000-4000-8000-000000000001'::uuid, '135790'),
  ('e0000000-0000-4000-8000-000000000011'::uuid, '246802'),
  ('e0000000-0000-4000-8000-000000000012'::uuid, '357913'),
  ('e0000000-0000-4000-8000-000000000013'::uuid, '468024'),
  ('e0000000-0000-4000-8000-000000000021'::uuid, '482913'),
  ('e0000000-0000-4000-8000-000000000022'::uuid, '593024'),
  ('e0000000-0000-4000-8000-000000000023'::uuid, '604135'),
  ('e0000000-0000-4000-8000-000000000024'::uuid, '715246'),
  ('e0000000-0000-4000-8000-000000000025'::uuid, '826357'),
  ('e0000000-0000-4000-8000-000000000026'::uuid, '937468'),
  ('e0000000-0000-4000-8000-000000000031'::uuid, '159260')
) as p(employee_id, pin);

-- Paired terminals, one per store ----------------------------------------------------
insert into public.devices (id, store_id, auth_user_id, code, name, platform, app_version, paired_by, last_seen_at) values
  ('d0000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000001', 'b1000000-0000-4000-8000-000000000001', 'T1', 'Kasir 1 Pusat',     'android', '0.1.0', 'e0000000-0000-4000-8000-000000000011', now()),
  ('d0000000-0000-4000-8000-000000000002', 'a0000000-0000-4000-8000-000000000002', 'b1000000-0000-4000-8000-000000000002', 'T1', 'Kasir 1 Bekasi',    'android', '0.1.0', 'e0000000-0000-4000-8000-000000000012', now()),
  ('d0000000-0000-4000-8000-000000000003', 'a0000000-0000-4000-8000-000000000003', 'b1000000-0000-4000-8000-000000000003', 'T1', 'Kasir 1 Tangerang', 'windows', '0.1.0', 'e0000000-0000-4000-8000-000000000013', now());

insert into public.printers (store_id, device_id, name, connection, address, paper_mm, purpose, opens_cash_drawer) values
  ('a0000000-0000-4000-8000-000000000001', 'd0000000-0000-4000-8000-000000000001', 'Printer Kasir 1', 'bluetooth', '00:11:22:33:44:01', 58, 'receipt', false),
  ('a0000000-0000-4000-8000-000000000002', 'd0000000-0000-4000-8000-000000000002', 'Printer Kasir 1', 'bluetooth', '00:11:22:33:44:02', 58, 'receipt', false),
  ('a0000000-0000-4000-8000-000000000003', 'd0000000-0000-4000-8000-000000000003', 'Printer Kasir 1', 'network',   '192.168.1.50:9100', 80, 'receipt', true);

-- Catalog ----------------------------------------------------------------------------
insert into public.categories (name, sort_order, color, icon) values
  ('Minuman',          10, '#0EA5E9', 'local_drink'),
  ('Makanan Ringan',   20, '#F59E0B', 'cookie'),
  ('Mie & Instan',     30, '#EF4444', 'ramen_dining'),
  ('Sembako',          40, '#10B981', 'rice_bowl'),
  ('Bumbu Dapur',      50, '#A855F7', 'soup_kitchen'),
  ('Perawatan Diri',   60, '#EC4899', 'spa'),
  ('Kebersihan Rumah', 70, '#14B8A6', 'cleaning_services'),
  ('Frozen Food',      80, '#6366F1', 'ac_unit'),
  ('Sayur & Buah',     90, '#84CC16', 'nutrition');

insert into public.suppliers (name, contact_name, phone, email, address) values
  ('PT Sumber Pangan Demo', 'Rahmat',  '021-5550201', 'order@sumberpangan.test', 'Kawasan Industri Pulogadung, Jakarta'),
  ('CV Segar Abadi Demo',   'Wati',    '021-5550202', 'sales@segarabadi.test',   'Pasar Induk Kramat Jati, Jakarta'),
  ('UD Mitra Grosir Demo',  'Hendra',  '021-5550203', 'cs@mitragrosir.test',     'Jl. Grosir No. 5, Tangerang');

-- EAN-13 for demo barcodes in the in-store range (prefix 20), so they never collide with real products.
create or replace function pg_temp.ean13(p12 text)
returns text language sql immutable as $$
  select p12 || ((10 - (sum(case when i % 2 = 1 then d else d * 3 end) % 10)) % 10)::text
  from (select i, substr(p12, i, 1)::integer as d from generate_series(1, 12) as i) x
$$;

create temporary table seed_catalog (
  seq integer primary key,
  product_key text not null,
  product_name text not null,
  category text not null,
  unit text not null,
  taxable boolean not null,
  variant_name text not null,
  sku text not null,
  price bigint not null,
  cost bigint not null,
  has_barcode boolean not null default true
);

insert into seed_catalog (seq, product_key, product_name, category, unit, taxable, variant_name, sku, price, cost, has_barcode) values
  ( 1, 'air-mineral',     'Air Mineral',                 'Minuman',          'pcs',     true,  '600 ml',     'MNM-AIR-600',   4000,  2600, true),
  ( 2, 'air-mineral',     'Air Mineral',                 'Minuman',          'pcs',     true,  '1500 ml',    'MNM-AIR-1500',  7000,  4700, true),
  ( 3, 'teh-melati',      'Teh Melati Botol 350 ml',     'Minuman',          'pcs',     true,  'Default',    'MNM-TEH-350',   5500,  3900, true),
  ( 4, 'kopi-susu',       'Kopi Susu Kaleng 240 ml',     'Minuman',          'pcs',     true,  'Default',    'MNM-KOPI-240',  8500,  6200, true),
  ( 5, 'susu-uht',        'Susu UHT Cokelat 200 ml',     'Minuman',          'pcs',     true,  'Default',    'MNM-UHT-200',   6000,  4300, true),
  ( 6, 'isotonik',        'Minuman Isotonik 500 ml',     'Minuman',          'pcs',     true,  'Default',    'MNM-ISO-500',   7500,  5400, true),
  ( 7, 'jus-jeruk',       'Jus Jeruk 1 L',               'Minuman',          'pcs',     true,  'Default',    'MNM-JUS-1L',   21000, 15500, true),
  ( 8, 'keripik-kentang', 'Keripik Kentang 68 g',        'Makanan Ringan',   'pcs',     true,  'Original',   'SNK-KRP-ORI',  11500,  8300, true),
  ( 9, 'keripik-kentang', 'Keripik Kentang 68 g',        'Makanan Ringan',   'pcs',     true,  'Balado',     'SNK-KRP-BLD',  11500,  8300, true),
  (10, 'biskuit-cokelat', 'Biskuit Cokelat 120 g',       'Makanan Ringan',   'pcs',     true,  'Default',    'SNK-BSK-120',   9000,  6400, true),
  (11, 'wafer-vanila',    'Wafer Vanila 150 g',          'Makanan Ringan',   'pcs',     true,  'Default',    'SNK-WFR-150',  10500,  7600, true),
  (12, 'kacang-atom',     'Kacang Atom 250 g',           'Makanan Ringan',   'pcs',     true,  'Default',    'SNK-KCG-250',  14000, 10100, true),
  (13, 'cokelat-batang',  'Cokelat Batang 60 g',         'Makanan Ringan',   'pcs',     true,  'Default',    'SNK-CKL-60',   12000,  8700, true),
  (14, 'permen-mint',     'Permen Mint Kaleng',          'Makanan Ringan',   'pcs',     true,  'Default',    'SNK-PRM-01',   15000, 10800, true),
  (15, 'mie-goreng',      'Mie Goreng Instan',           'Mie & Instan',     'pcs',     true,  'Original',   'MIE-GRG-ORI',   3500,  2700, true),
  (16, 'mie-goreng',      'Mie Goreng Instan',           'Mie & Instan',     'pcs',     true,  'Pedas',      'MIE-GRG-PDS',   3700,  2850, true),
  (17, 'mie-kuah',        'Mie Kuah Ayam Bawang',        'Mie & Instan',     'pcs',     true,  'Default',    'MIE-KUA-AYB',   3300,  2550, true),
  (18, 'bubur-instan',    'Bubur Ayam Instan',           'Mie & Instan',     'pcs',     true,  'Default',    'MIE-BBR-01',    6500,  4800, true),
  (19, 'sarden',          'Sarden Kaleng 155 g',         'Mie & Instan',     'pcs',     true,  'Default',    'MIE-SRD-155',  12500,  9200, true),
  (20, 'kornet',          'Kornet Sapi 198 g',           'Mie & Instan',     'pcs',     true,  'Default',    'MIE-KRN-198',  27000, 20500, true),
  (21, 'beras-premium',   'Beras Premium 5 kg',          'Sembako',          'pcs',     false, 'Default',    'SMB-BRS-5KG',  78000, 70000, true),
  (22, 'gula-pasir',      'Gula Pasir 1 kg',             'Sembako',          'pcs',     false, 'Default',    'SMB-GLA-1KG',  18500, 16200, true),
  (23, 'minyak-goreng',   'Minyak Goreng 2 L',           'Sembako',          'pcs',     true,  'Default',    'SMB-MYK-2L',   38000, 33500, true),
  (24, 'telur-ayam',      'Telur Ayam',                  'Sembako',          'pcs',     false, '10 butir',   'SMB-TLR-10',   29000, 25500, true),
  (25, 'telur-ayam',      'Telur Ayam',                  'Sembako',          'pcs',     false, '30 butir',   'SMB-TLR-30',   84000, 75000, true),
  (26, 'tepung-terigu',   'Tepung Terigu 1 kg',          'Sembako',          'pcs',     true,  'Default',    'SMB-TPG-1KG',  14000, 11800, true),
  (27, 'garam-dapur',     'Garam Dapur 250 g',           'Sembako',          'pcs',     false, 'Default',    'SMB-GRM-250',   4000,  2900, true),
  (28, 'kecap-manis',     'Kecap Manis 520 ml',          'Bumbu Dapur',      'pcs',     true,  'Default',    'BMB-KCP-520',  24000, 18900, true),
  (29, 'saus-sambal',     'Saus Sambal 340 ml',          'Bumbu Dapur',      'pcs',     true,  'Default',    'BMB-SMB-340',  15500, 11600, true),
  (30, 'kaldu-ayam',      'Kaldu Ayam Bubuk 100 g',      'Bumbu Dapur',      'pcs',     true,  'Default',    'BMB-KLD-100',   8000,  5800, true),
  (31, 'sabun-mandi',     'Sabun Mandi Batang 85 g',     'Perawatan Diri',   'pcs',     true,  'Default',    'PRW-SBN-85',    4500,  3200, true),
  (32, 'sampo-sachet',    'Sampo Sachet isi 12',         'Perawatan Diri',   'renceng', true,  'Default',    'PRW-SMP-12',   13000,  9600, true),
  (33, 'pasta-gigi',      'Pasta Gigi 190 g',            'Perawatan Diri',   'pcs',     true,  'Default',    'PRW-PST-190',  16500, 12300, true),
  (34, 'sikat-gigi',      'Sikat Gigi Medium',           'Perawatan Diri',   'pcs',     true,  'Default',    'PRW-SKT-01',    9500,  6700, true),
  (35, 'deodoran',        'Deodoran Roll-On 50 ml',      'Perawatan Diri',   'pcs',     true,  'Default',    'PRW-DEO-50',   22000, 16400, true),
  (36, 'sabun-piring',    'Sabun Cuci Piring 780 ml',    'Kebersihan Rumah', 'pcs',     true,  'Default',    'KBR-SCP-780',  17500, 13200, true),
  (37, 'deterjen',        'Deterjen Bubuk',              'Kebersihan Rumah', 'pcs',     true,  '800 g',      'KBR-DTJ-800',  21000, 16100, true),
  (38, 'deterjen',        'Deterjen Bubuk',              'Kebersihan Rumah', 'pcs',     true,  '1,8 kg',     'KBR-DTJ-1800', 44000, 34500, true),
  (39, 'pewangi',         'Pewangi Pakaian 900 ml',      'Kebersihan Rumah', 'pcs',     true,  'Default',    'KBR-PWG-900',  19500, 14600, true),
  (40, 'tisu-wajah',      'Tisu Wajah 250 lembar',       'Kebersihan Rumah', 'pcs',     true,  'Default',    'KBR-TSU-250',  13500,  9900, true),
  (41, 'pembersih-lantai','Pembersih Lantai 800 ml',     'Kebersihan Rumah', 'pcs',     true,  'Default',    'KBR-PBL-800',  16000, 11900, true),
  (42, 'nugget-ayam',     'Nugget Ayam 500 g',           'Frozen Food',      'pcs',     true,  'Default',    'FRZ-NGT-500',  48000, 38000, true),
  (43, 'sosis-sapi',      'Sosis Sapi 375 g',            'Frozen Food',      'pcs',     true,  'Default',    'FRZ-SSS-375',  36500, 28700, true),
  (44, 'es-krim-cone',    'Es Krim Cone Vanila',         'Frozen Food',      'pcs',     true,  'Default',    'FRZ-ESK-CON',   9000,  6300, true),
  (45, 'bawang-merah',    'Bawang Merah Curah',          'Sayur & Buah',     'kg',      false, 'Per kg',     'SYR-BWM-KG',   42000, 34000, false),
  (46, 'jeruk-medan',     'Jeruk Medan',                 'Sayur & Buah',     'kg',      false, 'Per kg',     'SYR-JRK-KG',   28000, 21500, false);

insert into public.products (id, category_id, unit_id, name, is_taxable)
select distinct on (s.product_key)
       md5('cashiera:product:' || s.product_key)::uuid, c.id, u.id, s.product_name, s.taxable
from seed_catalog s
join public.categories c on c.name = s.category
join public.units u on u.code = s.unit
order by s.product_key, s.seq;

insert into public.product_variants (id, product_id, name, sku, barcode, price, cost, sort_order)
select md5('cashiera:variant:' || s.sku)::uuid,
       md5('cashiera:product:' || s.product_key)::uuid,
       s.variant_name, s.sku,
       case when s.has_barcode then pg_temp.ean13('2000000' || lpad(s.seq::text, 5, '0')) end,
       s.price, s.cost,
       row_number() over (partition by s.product_key order by s.seq)
from seed_catalog s;

-- Gift wrap modifiers for snacks that make good presents.
insert into public.modifier_groups (id, name, min_select, max_select, sort_order)
values (md5('cashiera:modifier_group:gift-wrap')::uuid, 'Bungkus Kado', 0, 1, 10);

insert into public.modifiers (id, group_id, name, price_delta, sort_order) values
  (md5('cashiera:modifier:gift-paper')::uuid, md5('cashiera:modifier_group:gift-wrap')::uuid, 'Kertas Kado',  5000, 10),
  (md5('cashiera:modifier:gift-box')::uuid,   md5('cashiera:modifier_group:gift-wrap')::uuid, 'Kotak Kado',  10000, 20);

insert into public.product_modifier_groups (product_id, group_id)
select md5('cashiera:product:' || k)::uuid, md5('cashiera:modifier_group:gift-wrap')::uuid
from unnest(array['cokelat-batang', 'permen-mint', 'biskuit-cokelat']) as k;

-- Per-store settings: reorder points everywhere, two Tangerang price overrides.
insert into public.store_variant_settings (store_id, variant_id, reorder_point, reorder_qty)
select st.id, v.id,
       case when u.allow_decimal then 5 else 10 end,
       case when u.allow_decimal then 20 else 24 end
from public.stores st
cross join public.product_variants v
join public.products p on p.id = v.product_id
join public.units u on u.id = p.unit_id;

update public.store_variant_settings svs
   set price_override = x.price
  from (values ('MNM-AIR-600', 4500::bigint), ('MNM-TEH-350', 6000::bigint)) as x(sku, price),
       public.product_variants v
 where v.sku = x.sku and svs.variant_id = v.id
   and svs.store_id = 'a0000000-0000-4000-8000-000000000003';

insert into public.store_favorites (store_id, product_id, sort_order)
select f.store_id::uuid, md5('cashiera:product:' || f.product_key)::uuid, f.sort_order
from (values
  ('a0000000-0000-4000-8000-000000000001', 'air-mineral', 1), ('a0000000-0000-4000-8000-000000000001', 'mie-goreng', 2),
  ('a0000000-0000-4000-8000-000000000001', 'kopi-susu', 3),   ('a0000000-0000-4000-8000-000000000001', 'telur-ayam', 4),
  ('a0000000-0000-4000-8000-000000000002', 'air-mineral', 1), ('a0000000-0000-4000-8000-000000000002', 'beras-premium', 2),
  ('a0000000-0000-4000-8000-000000000002', 'minyak-goreng', 3),
  ('a0000000-0000-4000-8000-000000000003', 'air-mineral', 1), ('a0000000-0000-4000-8000-000000000003', 'es-krim-cone', 2),
  ('a0000000-0000-4000-8000-000000000003', 'nugget-ayam', 3)
) as f(store_id, product_key, sort_order);

-- Opening stock, posted as 'initial' adjustments so movement history starts clean.
-- A few items start below their reorder point to show LOW_STOCK alerts.
insert into public.stock_adjustments (id, store_id, adjustment_number, reason, note, employee_id, occurred_at)
select md5('cashiera:adjustment:init:' || st.code)::uuid, st.id, 'INIT-' || st.code, 'initial', 'Stok awal (demo)',
       case st.code
         when 'PST' then 'e0000000-0000-4000-8000-000000000011'::uuid
         when 'BKS' then 'e0000000-0000-4000-8000-000000000012'::uuid
         else 'e0000000-0000-4000-8000-000000000013'::uuid
       end,
       now() - interval '7 days'
from public.stores st;

insert into public.stock_adjustment_items (id, adjustment_id, store_id, variant_id, quantity_delta, unit_cost)
select md5('cashiera:adjustment_item:' || st.code || ':' || s.sku)::uuid,
       md5('cashiera:adjustment:init:' || st.code)::uuid,
       st.id,
       md5('cashiera:variant:' || s.sku)::uuid,
       case
         when (st.code, s.sku) in (('BKS', 'MNM-KOPI-240'), ('TGR', 'SMB-TLR-30'), ('PST', 'FRZ-NGT-500')) then 4
         when s.unit = 'kg' then 12.5 + st.ord * 2.25
         else 20 + (s.seq * 7 + st.ord * 11) % 37
       end,
       s.cost
from seed_catalog s
cross join (select id, code, row_number() over (order by code) as ord from public.stores) st;

-- Customers with opening loyalty balances.
insert into public.customers (id, name, phone, email, created_store_id, kasbon_limit) values
  (md5('cashiera:customer:1')::uuid, 'Sari Wulandari',    '081200000001', 'sari@contoh.test',  'a0000000-0000-4000-8000-000000000001', null),
  (md5('cashiera:customer:2')::uuid, 'Rudi Hartono',      '081200000002', null,                'a0000000-0000-4000-8000-000000000001', null),
  (md5('cashiera:customer:3')::uuid, 'Maya Kusuma',       '081200000003', 'maya@contoh.test',  'a0000000-0000-4000-8000-000000000002', null),
  (md5('cashiera:customer:4')::uuid, 'Toko Berkah Jaya',  '081200000004', null,                'a0000000-0000-4000-8000-000000000001', 2000000),
  (md5('cashiera:customer:5')::uuid, 'Agus Salim',        '081200000005', null,                'a0000000-0000-4000-8000-000000000003', null),
  (md5('cashiera:customer:6')::uuid, 'Lina Marlina',      '081200000006', null,                'a0000000-0000-4000-8000-000000000003', 500000);

insert into public.loyalty_ledger (customer_id, store_id, entry_type, points, note) values
  (md5('cashiera:customer:1')::uuid, 'a0000000-0000-4000-8000-000000000001', 'adjust', 120, 'saldo awal (demo)'),
  (md5('cashiera:customer:2')::uuid, 'a0000000-0000-4000-8000-000000000001', 'adjust',  45, 'saldo awal (demo)'),
  (md5('cashiera:customer:3')::uuid, 'a0000000-0000-4000-8000-000000000002', 'adjust', 300, 'saldo awal (demo)'),
  (md5('cashiera:customer:5')::uuid, 'a0000000-0000-4000-8000-000000000003', 'adjust',  10, 'saldo awal (demo)');

-- Promotions (evaluated by the Dart promo engine; validated by the database).
insert into public.promotions (id, name, description, promo_type, rules, priority, is_stackable, days_of_week, start_time, end_time) values
  (md5('cashiera:promo:happy-hour')::uuid, 'Happy Hour Minuman', 'Semua minuman diskon 10% pukul 14.00-16.00 hari kerja',
   'happy_hour',
   jsonb_build_object('scope', jsonb_build_object('category_ids', jsonb_build_array((select id from public.categories where name = 'Minuman'))),
                      'discount', jsonb_build_object('type', 'percent', 'bps', 1000)),
   50, false, array[1, 2, 3, 4, 5]::smallint[], '14:00', '16:00'),
  (md5('cashiera:promo:b2g1-mie')::uuid, 'Beli 2 Gratis 1 Mie Goreng', 'Setiap beli 2 mie goreng, gratis 1',
   'buy_x_get_y',
   jsonb_build_object('buy', jsonb_build_object('scope', jsonb_build_object('product_ids', jsonb_build_array(md5('cashiera:product:mie-goreng')::uuid)), 'quantity', 2),
                      'get', jsonb_build_object('scope', jsonb_build_object('product_ids', jsonb_build_array(md5('cashiera:product:mie-goreng')::uuid)), 'quantity', 1,
                                                'discount', jsonb_build_object('type', 'percent', 'bps', 10000)),
                      'max_applications', null),
   60, false, null, null, null),
  (md5('cashiera:promo:paket-sarapan')::uuid, 'Paket Sarapan', '2 mie goreng + telur 10 butir jadi Rp 34.000',
   'bundle',
   jsonb_build_object('components', jsonb_build_array(
                        jsonb_build_object('scope', jsonb_build_object('product_ids', jsonb_build_array(md5('cashiera:product:mie-goreng')::uuid)), 'quantity', 2),
                        jsonb_build_object('scope', jsonb_build_object('variant_ids', jsonb_build_array(md5('cashiera:variant:SMB-TLR-10')::uuid)), 'quantity', 1)),
                      'bundle_price', 34000),
   70, false, null, null, null),
  (md5('cashiera:promo:grosir-air')::uuid, 'Grosir Air Mineral 600 ml', '12+ botol diskon 5%, 24+ botol diskon 10%',
   'tiered_qty',
   jsonb_build_object('scope', jsonb_build_object('variant_ids', jsonb_build_array(md5('cashiera:variant:MNM-AIR-600')::uuid)),
                      'tiers', jsonb_build_array(
                        jsonb_build_object('min_quantity', 12, 'discount', jsonb_build_object('type', 'percent', 'bps', 500)),
                        jsonb_build_object('min_quantity', 24, 'discount', jsonb_build_object('type', 'percent', 'bps', 1000)))),
   80, false, null, null, null),
  (md5('cashiera:promo:min-150k')::uuid, 'Belanja Rp 150.000 Hemat Rp 10.000', 'Potongan Rp 10.000 untuk belanja minimal Rp 150.000',
   'min_purchase',
   jsonb_build_object('min_subtotal', 150000, 'discount', jsonb_build_object('type', 'fixed', 'amount', 10000)),
   200, true, null, null, null);

insert into public.vouchers (code, description, discount_type, discount_value, max_discount, min_subtotal, max_uses, per_customer_limit, starts_at, ends_at) values
  ('HEMAT10', 'Diskon 10% maks. Rp 20.000, min. belanja Rp 50.000', 'percent', 1000, 20000, 50000, 100, null, '2026-01-01', '2027-12-31'),
  ('BARU25K', 'Potongan Rp 25.000 untuk pelanggan baru, min. belanja Rp 200.000', 'fixed', 25000, null, 200000, 50, 1, '2026-01-01', '2027-12-31');

-- A few expenses so finance reports have data.
insert into public.expenses (store_id, category_id, amount, expense_date, description, paid_from, employee_id)
select x.store_id::uuid, c.id, x.amount, current_date - x.days_ago, x.description, x.paid_from, x.employee_id::uuid
from (values
  ('a0000000-0000-4000-8000-000000000001', 'Listrik',    1250000::bigint, 5, 'Tagihan listrik bulan lalu',   'bank',       'e0000000-0000-4000-8000-000000000011'),
  ('a0000000-0000-4000-8000-000000000001', 'Kebersihan',  150000::bigint, 2, 'Alat pel dan sabun lantai',    'petty_cash', 'e0000000-0000-4000-8000-000000000011'),
  ('a0000000-0000-4000-8000-000000000002', 'Sewa',       4500000::bigint, 6, 'Sewa ruko bulan ini',          'bank',       'e0000000-0000-4000-8000-000000000012'),
  ('a0000000-0000-4000-8000-000000000003', 'Transportasi', 85000::bigint, 1, 'Ongkos kirim barang ke toko', 'petty_cash', 'e0000000-0000-4000-8000-000000000013')
) as x(store_id, category, amount, days_ago, description, paid_from, employee_id)
join public.expense_categories c on c.name = x.category;

drop table seed_catalog;
