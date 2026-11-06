-- =============================================================================
-- CashierA · 0200 · Company, stores, roles, employees, devices
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Company profile (single row) and company-wide settings
-- ---------------------------------------------------------------------------
create table public.business_profile (
  id smallint primary key default 1 check (id = 1),
  name text not null check (length(trim(name)) > 0),
  legal_name text,
  npwp text,
  address text,
  phone text,
  email text,
  logo_path text,
  default_locale text not null default 'id' check (default_locale in ('id', 'en')),
  currency text not null default 'IDR' check (currency = 'IDR'),
  loyalty_enabled boolean not null default true,
  loyalty_earn_amount bigint not null default 10000 check (loyalty_earn_amount > 0),
  loyalty_point_value bigint not null default 100 check (loyalty_point_value > 0),
  loyalty_min_redeem_points integer not null default 0 check (loyalty_min_redeem_points >= 0),
  kasbon_default_due_days integer not null default 30 check (kasbon_default_due_days between 1 and 365),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
comment on table public.business_profile is 'Single-row company profile plus company-wide loyalty and kasbon settings.';
comment on column public.business_profile.loyalty_earn_amount is 'Rupiah of net spend that earns 1 point (default Rp 10.000).';
comment on column public.business_profile.loyalty_point_value is 'Rupiah of discount per redeemed point (default Rp 100).';

insert into public.business_profile (id, name) values (1, 'CashierA') on conflict (id) do nothing;

-- ---------------------------------------------------------------------------
-- Stores and per-store settings
-- ---------------------------------------------------------------------------
create table public.stores (
  id uuid primary key default gen_random_uuid(),
  code text not null unique check (code ~ '^[A-Z0-9]{2,6}$'),
  name text not null check (length(trim(name)) > 0),
  address text,
  phone text,
  timezone text not null default 'Asia/Jakarta'
    check (timezone in ('Asia/Jakarta', 'Asia/Makassar', 'Asia/Jayapura')),
  fnb_mode boolean not null default false,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
comment on column public.stores.code is 'Short code used in document numbers, e.g. PST-T1-261105-0001.';

create table public.store_settings (
  store_id uuid primary key references public.stores (id) on delete cascade,
  tax_enabled boolean not null default true,
  tax_name text not null default 'PPN',
  tax_rate_bps integer not null default 1100 check (tax_rate_bps between 0 and 10000),
  tax_inclusive boolean not null default true,
  service_charge_enabled boolean not null default false,
  service_charge_bps integer not null default 0 check (service_charge_bps between 0 and 10000),
  service_charge_taxable boolean not null default true,
  rounding_mode text not null default 'none' check (rounding_mode in ('none', 'nearest', 'up', 'down')),
  rounding_unit integer not null default 100 check (rounding_unit in (50, 100, 500, 1000)),
  discount_approval_bps integer not null default 2000 check (discount_approval_bps between 0 and 10000),
  kasbon_enabled boolean not null default true,
  receipt_header text,
  receipt_footer text not null default 'Terima kasih atas kunjungan Anda',
  receipt_show_logo boolean not null default true,
  receipt_paper_mm smallint not null default 58 check (receipt_paper_mm in (58, 80)),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
comment on column public.store_settings.tax_rate_bps is 'Effective PPN rate in basis points. 1100 = 11% (12% x DPP 11/12).';
comment on column public.store_settings.discount_approval_bps is 'Manual discounts above this need a manager PIN (2000 = 20%).';

-- ---------------------------------------------------------------------------
-- Permissions and editable roles
-- ---------------------------------------------------------------------------
create table public.permissions (
  code text primary key check (code ~ '^[a-z]+(_[a-z]+)*\.[a-z]+(_[a-z]+)*$'),
  module text not null,
  description_en text not null,
  description_id text not null
);

insert into public.permissions (code, module, description_en, description_id) values
  ('pos.sell',               'pos',       'Use the cashier screen and take payments',          'Memakai layar kasir dan menerima pembayaran'),
  ('pos.discount',           'pos',       'Give discounts up to the approval threshold',       'Memberi diskon sampai batas persetujuan'),
  ('pos.discount_override',  'pos',       'Approve discounts above the threshold',             'Menyetujui diskon di atas batas'),
  ('pos.void',               'pos',       'Cancel or void orders that were not printed',       'Membatalkan pesanan yang belum dicetak'),
  ('pos.void_after_print',   'pos',       'Approve voids after a receipt or bill was printed', 'Menyetujui pembatalan setelah struk dicetak'),
  ('pos.refund',             'pos',       'Approve refunds',                                   'Menyetujui pengembalian dana'),
  ('pos.open_drawer',        'pos',       'Approve opening the cash drawer without a sale',    'Menyetujui buka laci tanpa transaksi'),
  ('shift.manage',           'shift',     'Open and close shifts',                             'Membuka dan menutup shift'),
  ('shift.cash_movement',    'shift',     'Record petty cash in and out',                      'Mencatat kas masuk dan keluar'),
  ('customer.manage',        'customer',  'Create and edit customers',                         'Membuat dan mengubah pelanggan'),
  ('kasbon.manage',          'customer',  'Sell on credit and receive kasbon repayments',      'Menjual kasbon dan menerima cicilan'),
  ('catalog.manage',         'catalog',   'Manage the company catalog and default prices',     'Mengelola katalog dan harga dasar'),
  ('promo.manage',           'catalog',   'Manage promotions and vouchers',                    'Mengelola promo dan voucher'),
  ('pricing.store_override', 'catalog',   'Set store prices and reorder points',               'Mengatur harga toko dan titik pesan ulang'),
  ('inventory.view',         'inventory', 'View stock, movements and alerts',                  'Melihat stok, mutasi dan peringatan'),
  ('inventory.adjust',       'inventory', 'Record stock in, out and adjustments',              'Mencatat stok masuk, keluar dan penyesuaian'),
  ('inventory.opname',       'inventory', 'Run stock opname',                                  'Melakukan stok opname'),
  ('inventory.receive',      'inventory', 'Receive goods and incoming transfers',              'Menerima barang dan transfer masuk'),
  ('purchase.manage',        'inventory', 'Manage suppliers and purchase orders',              'Mengelola pemasok dan pesanan pembelian'),
  ('transfer.request',       'inventory', 'Request stock from another store',                  'Meminta stok dari toko lain'),
  ('transfer.approve',       'inventory', 'Approve, reject and ship stock transfers',          'Menyetujui, menolak dan mengirim transfer stok'),
  ('reports.view',           'reports',   'View store reports and dashboards',                 'Melihat laporan dan dasbor toko'),
  ('expense.manage',         'finance',   'Record and edit expenses',                          'Mencatat dan mengubah pengeluaran'),
  ('audit.view',             'security',  'View the audit log',                                'Melihat log audit'),
  ('employee.manage',        'security',  'Manage employees, PINs and store assignments',      'Mengelola karyawan, PIN dan penempatan toko'),
  ('device.manage',          'security',  'Pair and revoke terminals',                         'Memasangkan dan mencabut terminal'),
  ('settings.manage',        'settings',  'Manage store settings, printers, tables, payments', 'Mengelola pengaturan toko, printer, meja, pembayaran'),
  ('kitchen.view',           'fnb',       'Use the kitchen display',                           'Memakai layar dapur');

create table public.roles (
  id uuid primary key default gen_random_uuid(),
  code text not null unique check (code ~ '^[a-z][a-z0-9_]*$'),
  name text not null check (length(trim(name)) > 0),
  scope text not null default 'assigned_stores' check (scope in ('all_stores', 'assigned_stores')),
  is_system boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
comment on column public.roles.scope is 'all_stores: sees every store (owner). assigned_stores: only stores in employee_stores.';

create table public.role_permissions (
  role_id uuid not null references public.roles (id) on delete cascade,
  permission_code text not null references public.permissions (code) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (role_id, permission_code)
);

insert into public.roles (code, name, scope, is_system) values
  ('owner',     'Owner',          'all_stores',      true),
  ('manager',   'Branch Manager', 'assigned_stores', true),
  ('cashier',   'Cashier',        'assigned_stores', true),
  ('kitchen',   'Kitchen',        'assigned_stores', true),
  ('inventory', 'Inventory',      'assigned_stores', true);

-- The owner role implicitly holds every permission (see app.employee_has_permission);
-- rows are still inserted so the role editor shows them ticked.
insert into public.role_permissions (role_id, permission_code)
select r.id, p.code from public.roles r cross join public.permissions p where r.code = 'owner';

insert into public.role_permissions (role_id, permission_code)
select r.id, p.code
from public.roles r
join public.permissions p on p.code in (
  'pos.sell', 'pos.discount', 'pos.discount_override', 'pos.void', 'pos.void_after_print',
  'pos.refund', 'pos.open_drawer', 'shift.manage', 'shift.cash_movement', 'customer.manage',
  'kasbon.manage', 'pricing.store_override', 'inventory.view', 'inventory.adjust',
  'inventory.opname', 'inventory.receive', 'purchase.manage', 'transfer.request',
  'transfer.approve', 'reports.view', 'expense.manage', 'audit.view', 'employee.manage',
  'device.manage', 'settings.manage', 'kitchen.view')
where r.code = 'manager';

insert into public.role_permissions (role_id, permission_code)
select r.id, p.code
from public.roles r
join public.permissions p on p.code in (
  'pos.sell', 'pos.discount', 'pos.void', 'shift.manage', 'shift.cash_movement',
  'customer.manage', 'kasbon.manage')
where r.code = 'cashier';

insert into public.role_permissions (role_id, permission_code)
select r.id, p.code from public.roles r join public.permissions p on p.code = 'kitchen.view'
where r.code = 'kitchen';

insert into public.role_permissions (role_id, permission_code)
select r.id, p.code
from public.roles r
join public.permissions p on p.code in (
  'inventory.view', 'inventory.adjust', 'inventory.opname', 'inventory.receive',
  'purchase.manage', 'transfer.request')
where r.code = 'inventory';

-- ---------------------------------------------------------------------------
-- Employees, PINs, store assignments
-- ---------------------------------------------------------------------------
create table public.employees (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid unique references auth.users (id) on delete set null,
  role_id uuid not null references public.roles (id),
  full_name text not null check (length(trim(full_name)) > 0),
  email text check (email is null or email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
  phone text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index employees_email_key on public.employees (lower(email)) where email is not null;
create index employees_role_idx on public.employees (role_id);
comment on column public.employees.auth_user_id is 'Optional email login (back office). Terminal staff may only have a PIN.';

create table public.employee_pins (
  employee_id uuid primary key references public.employees (id) on delete cascade,
  pin_hash text not null,
  failed_attempts smallint not null default 0 check (failed_attempts >= 0),
  locked_until timestamptz,
  updated_at timestamptz not null default now()
);
comment on table public.employee_pins is
  'bcrypt PIN hashes (pgcrypto). No client access; only security-definer RPCs read it.';

create table public.employee_stores (
  employee_id uuid not null references public.employees (id) on delete cascade,
  store_id uuid not null references public.stores (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (employee_id, store_id)
);
create index employee_stores_store_idx on public.employee_stores (store_id);

-- ---------------------------------------------------------------------------
-- Terminals (devices) and one-time pairing codes
-- ---------------------------------------------------------------------------
create table public.devices (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores (id),
  auth_user_id uuid not null unique references auth.users (id) on delete cascade,
  code text not null check (code ~ '^T[0-9]{1,3}$'),
  name text not null check (length(trim(name)) > 0),
  platform text check (platform in ('android', 'ios', 'windows', 'macos', 'linux', 'web')),
  app_version text,
  last_seen_at timestamptz,
  is_active boolean not null default true,
  paired_by uuid references public.employees (id),
  paired_at timestamptz not null default now(),
  revoked_at timestamptz,
  revoked_by uuid references public.employees (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (store_id, code),
  check (is_active or revoked_at is not null)
);
comment on table public.devices is
  'Paired POS terminals. Each is an (anonymous) auth user bound to one store.';

create table public.device_pairing_codes (
  id uuid primary key default gen_random_uuid(),
  code_hash text not null unique,
  store_id uuid not null references public.stores (id) on delete cascade,
  device_name text not null check (length(trim(device_name)) > 0),
  created_by uuid not null references public.employees (id),
  expires_at timestamptz not null,
  used_at timestamptz,
  device_id uuid references public.devices (id),
  created_at timestamptz not null default now()
);
comment on column public.device_pairing_codes.code_hash is 'sha256 of the 8-character code; the code itself is never stored.';
