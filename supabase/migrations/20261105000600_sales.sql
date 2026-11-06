-- =============================================================================
-- CashierA · 0600 · Sales: tables & printers, shifts, petty cash, orders,
-- items, discounts, payments, refunds, kasbon, loyalty, vouchers, KDS status.
-- Transactional ids are generated on the terminal (offline-first), so most
-- primary keys here have no default.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Store floor plan (F&B) and printers
-- ---------------------------------------------------------------------------
create table public.dining_tables (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores (id) on delete cascade,
  name text not null check (length(trim(name)) > 0),
  area text,
  capacity smallint not null default 4 check (capacity between 1 and 50),
  shape text not null default 'square' check (shape in ('square', 'round', 'rect')),
  pos_x integer not null default 0 check (pos_x >= 0),
  pos_y integer not null default 0 check (pos_y >= 0),
  width integer not null default 1 check (width between 1 and 10),
  height integer not null default 1 check (height between 1 and 10),
  status text not null default 'available' check (status in ('available', 'occupied', 'reserved', 'cleaning')),
  current_order_id uuid,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (store_id, name)
);

create table public.printers (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores (id) on delete cascade,
  device_id uuid references public.devices (id) on delete set null,
  name text not null check (length(trim(name)) > 0),
  connection text not null check (connection in ('bluetooth', 'ble', 'usb', 'network')),
  address text not null,
  paper_mm smallint not null default 58 check (paper_mm in (58, 80)),
  purpose text not null default 'receipt' check (purpose in ('receipt', 'kitchen', 'bar')),
  opens_cash_drawer boolean not null default false,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index printers_store_idx on public.printers (store_id);
comment on column public.printers.address is 'MAC (bluetooth), BLE id, USB id / Windows printer name, or host:port (network).';

-- ---------------------------------------------------------------------------
-- Shifts and petty cash
-- ---------------------------------------------------------------------------
create table public.shifts (
  id uuid primary key,
  store_id uuid not null references public.stores (id),
  device_id uuid not null references public.devices (id),
  opened_by uuid not null references public.employees (id),
  opened_at timestamptz not null,
  opening_cash bigint not null check (opening_cash >= 0),
  status text not null default 'open' check (status in ('open', 'closed')),
  closed_by uuid references public.employees (id),
  closed_at timestamptz,
  counted_cash bigint check (counted_cash >= 0),
  expected_cash bigint,
  client_expected_cash bigint,
  cash_difference bigint,
  close_note text,
  business_date date not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint shifts_state_chk check (
    (status = 'open' and closed_at is null and closed_by is null and counted_cash is null)
    or (status = 'closed' and closed_at is not null and closed_by is not null and counted_cash is not null
        and expected_cash is not null and cash_difference = counted_cash - expected_cash)
  ),
  constraint shifts_close_after_open_chk check (closed_at is null or closed_at >= opened_at)
);
create unique index shifts_one_open_per_device on public.shifts (device_id) where status = 'open';
create index shifts_store_opened_idx on public.shifts (store_id, opened_at desc);
comment on column public.shifts.opening_cash is 'Kas awal.';
comment on column public.shifts.cash_difference is 'Selisih = counted_cash - expected_cash.';
comment on column public.shifts.client_expected_cash is 'What the terminal computed; a mismatch with expected_cash raises CASH_DISCREPANCY.';

create table public.cash_movements (
  id uuid primary key,
  store_id uuid not null references public.stores (id),
  shift_id uuid not null references public.shifts (id),
  movement_type text not null check (movement_type in ('in', 'out')),
  amount bigint not null check (amount > 0),
  reason text not null check (length(trim(reason)) >= 3),
  employee_id uuid not null references public.employees (id),
  approved_by uuid references public.employees (id),
  occurred_at timestamptz not null,
  created_at timestamptz not null default now()
);
create index cash_movements_shift_idx on public.cash_movements (shift_id);
create index cash_movements_store_created_idx on public.cash_movements (store_id, created_at desc);

-- ---------------------------------------------------------------------------
-- Orders
-- Money identities (all integer rupiah):
--   net_total   = gross_total - item_discount_total - bill_discount_total - points_discount
--   grand_total = net_total + service_charge_total + (tax_inclusive ? 0 : tax_total) + rounding_amount
--   paid_total  = sum of non-kasbon payments; kasbon part = grand_total - paid_total
-- ---------------------------------------------------------------------------
create table public.orders (
  id uuid primary key,
  store_id uuid not null references public.stores (id),
  device_id uuid references public.devices (id),
  shift_id uuid references public.shifts (id),
  order_number text not null check (length(order_number) between 3 and 40),
  order_type text not null default 'takeaway' check (order_type in ('dine_in', 'takeaway', 'delivery')),
  status text not null default 'open' check (status in ('open', 'held', 'completed', 'cancelled', 'voided')),
  table_id uuid references public.dining_tables (id),
  customer_id uuid references public.customers (id),
  cashier_id uuid not null references public.employees (id),
  guest_count smallint check (guest_count between 1 and 500),
  note text,
  gross_total bigint not null default 0 check (gross_total >= 0),
  item_discount_total bigint not null default 0 check (item_discount_total >= 0),
  bill_discount_total bigint not null default 0 check (bill_discount_total >= 0),
  points_redeemed integer not null default 0 check (points_redeemed >= 0),
  points_discount bigint not null default 0 check (points_discount >= 0),
  net_total bigint not null default 0 check (net_total >= 0),
  service_charge_total bigint not null default 0 check (service_charge_total >= 0),
  tax_total bigint not null default 0 check (tax_total >= 0),
  tax_inclusive boolean not null default true,
  tax_rate_bps integer not null default 0 check (tax_rate_bps between 0 and 10000),
  service_charge_bps integer not null default 0 check (service_charge_bps between 0 and 10000),
  service_charge_taxable boolean not null default true,
  rounding_amount bigint not null default 0 check (abs(rounding_amount) < 1000),
  grand_total bigint not null default 0 check (grand_total >= 0),
  paid_total bigint not null default 0 check (paid_total >= 0),
  change_total bigint not null default 0 check (change_total >= 0),
  points_earned integer not null default 0 check (points_earned >= 0),
  refunded_total bigint not null default 0 check (refunded_total >= 0),
  kasbon_due_date date,
  version integer not null default 1 check (version >= 1),
  ordered_at timestamptz not null,
  business_date date not null,
  completed_at timestamptz,
  receipt_printed_at timestamptz,
  cancelled_at timestamptz,
  cancelled_by uuid references public.employees (id),
  cancel_reason text,
  voided_at timestamptz,
  voided_by uuid references public.employees (id),
  void_approved_by uuid references public.employees (id),
  void_reason text,
  voided_shift_id uuid references public.shifts (id),
  merged_into_order_id uuid references public.orders (id),
  split_from_order_id uuid references public.orders (id),
  needs_review boolean not null default false,
  review_reason text,
  received_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (store_id, order_number),
  constraint orders_net_total_chk
    check (net_total = gross_total - item_discount_total - bill_discount_total - points_discount),
  constraint orders_grand_total_chk
    check (grand_total = net_total + service_charge_total
                         + case when tax_inclusive then 0 else tax_total end + rounding_amount),
  constraint orders_inclusive_tax_chk
    check (not tax_inclusive or tax_total <= net_total + service_charge_total),
  constraint orders_paid_chk check (paid_total <= grand_total),
  constraint orders_points_chk check ((points_redeemed = 0) = (points_discount = 0)),
  constraint orders_refund_chk check (refunded_total <= grand_total),
  constraint orders_completed_chk
    check (status not in ('completed', 'voided') or (completed_at is not null and shift_id is not null)),
  constraint orders_cancelled_chk
    check (status <> 'cancelled' or (cancelled_at is not null and cancelled_by is not null)),
  constraint orders_voided_chk
    check (status <> 'voided' or (voided_at is not null and voided_by is not null and void_reason is not null))
);
create index orders_store_business_date_idx on public.orders (store_id, business_date);
create index orders_store_created_idx on public.orders (store_id, created_at desc);
create index orders_store_active_idx on public.orders (store_id, status) where status in ('open', 'held');
create index orders_shift_idx on public.orders (shift_id);
create index orders_customer_idx on public.orders (customer_id) where customer_id is not null;
create index orders_review_idx on public.orders (store_id) where needs_review;
comment on column public.orders.version is 'Incremented by the terminal on every edit; stale snapshots are ignored.';
comment on column public.orders.needs_review is 'Set when stock went negative, a shift was already closed, a kasbon limit was exceeded, etc.';

alter table public.dining_tables
  add constraint dining_tables_current_order_fk
  foreign key (current_order_id) references public.orders (id) on delete set null;

create table public.order_items (
  id uuid primary key,
  order_id uuid not null references public.orders (id) on delete cascade,
  store_id uuid not null references public.stores (id),
  product_id uuid not null references public.products (id),
  variant_id uuid not null references public.product_variants (id),
  product_name text not null,
  variant_name text,
  sku text not null,
  quantity numeric(14,3) not null check (quantity > 0),
  unit_price bigint not null check (unit_price >= 0),
  modifiers_unit_total bigint not null default 0 check (modifiers_unit_total >= 0),
  gross_amount bigint not null check (gross_amount >= 0),
  item_discount_amount bigint not null default 0 check (item_discount_amount >= 0),
  bill_discount_amount bigint not null default 0 check (bill_discount_amount >= 0),
  net_amount bigint not null check (net_amount >= 0),
  tax_amount bigint not null default 0 check (tax_amount >= 0),
  is_taxable boolean not null default true,
  unit_cost bigint not null default 0 check (unit_cost >= 0),
  cost_amount bigint not null default 0 check (cost_amount >= 0),
  note text,
  discount_note text,
  kitchen_station text check (kitchen_station in ('kitchen', 'bar')),
  refunded_quantity numeric(14,3) not null default 0 check (refunded_quantity >= 0),
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint order_items_gross_chk check (gross_amount = round((unit_price + modifiers_unit_total) * quantity)),
  constraint order_items_net_chk check (net_amount = gross_amount - item_discount_amount - bill_discount_amount),
  constraint order_items_cost_chk check (cost_amount = round(unit_cost * quantity)),
  constraint order_items_refund_chk check (refunded_quantity <= quantity),
  constraint order_items_tax_chk check (is_taxable or tax_amount = 0)
);
create index order_items_order_idx on public.order_items (order_id);
create index order_items_store_created_idx on public.order_items (store_id, created_at desc);
create index order_items_store_sku_idx on public.order_items (store_id, sku);
create index order_items_variant_idx on public.order_items (variant_id);
comment on column public.order_items.bill_discount_amount is 'This line''s share of bill discounts and points (largest-remainder allocation).';

create table public.order_item_modifiers (
  id uuid primary key,
  order_item_id uuid not null references public.order_items (id) on delete cascade,
  store_id uuid not null references public.stores (id),
  modifier_id uuid references public.modifiers (id) on delete set null,
  group_name text not null,
  modifier_name text not null,
  price_delta bigint not null default 0 check (price_delta >= 0),
  created_at timestamptz not null default now()
);
create index order_item_modifiers_item_idx on public.order_item_modifiers (order_item_id);

create table public.order_discounts (
  id uuid primary key,
  order_id uuid not null references public.orders (id) on delete cascade,
  store_id uuid not null references public.stores (id),
  order_item_id uuid references public.order_items (id) on delete cascade,
  source text not null check (source in ('manual', 'promotion', 'voucher', 'points')),
  promotion_id uuid references public.promotions (id),
  voucher_id uuid references public.vouchers (id),
  description text not null,
  amount bigint not null check (amount > 0),
  discount_bps integer check (discount_bps between 1 and 10000),
  approved_by uuid references public.employees (id),
  created_at timestamptz not null default now(),
  check (source <> 'promotion' or promotion_id is not null),
  check (source <> 'voucher' or voucher_id is not null),
  check (source <> 'points' or order_item_id is null)
);
create index order_discounts_order_idx on public.order_discounts (order_id);
create index order_discounts_promotion_idx on public.order_discounts (promotion_id) where promotion_id is not null;
comment on table public.order_discounts is 'Why each discount was given. item rows (order_item_id set) sum to item_discount_total.';

create table public.payments (
  id uuid primary key,
  order_id uuid not null references public.orders (id) on delete cascade,
  store_id uuid not null references public.stores (id),
  shift_id uuid references public.shifts (id),
  payment_method_id uuid not null references public.payment_methods (id),
  method_type text not null check (method_type in ('cash', 'qris', 'card', 'transfer', 'ewallet', 'kasbon')),
  amount bigint not null check (amount > 0),
  tendered_amount bigint,
  change_amount bigint not null default 0 check (change_amount >= 0),
  reference text,
  provider text,
  provider_ref text,
  status text not null default 'paid' check (status in ('pending', 'paid', 'failed', 'expired', 'cancelled')),
  paid_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint payments_cash_chk check (
    (method_type = 'cash' and tendered_amount is not null and tendered_amount >= amount
       and change_amount = tendered_amount - amount)
    or (method_type <> 'cash' and change_amount = 0)
  ),
  constraint payments_paid_chk check (status <> 'paid' or paid_at is not null)
);
create index payments_order_idx on public.payments (order_id);
create index payments_shift_idx on public.payments (shift_id);
create index payments_store_created_idx on public.payments (store_id, created_at desc);
create unique index payments_provider_ref_key on public.payments (provider, provider_ref) where provider_ref is not null;
comment on column public.payments.amount is 'Amount applied to the bill. For cash: tendered_amount - change_amount.';

-- ---------------------------------------------------------------------------
-- Refunds
-- ---------------------------------------------------------------------------
create table public.refunds (
  id uuid primary key,
  order_id uuid not null references public.orders (id),
  store_id uuid not null references public.stores (id),
  shift_id uuid references public.shifts (id),
  device_id uuid references public.devices (id),
  refund_number text not null,
  reason text not null check (length(trim(reason)) >= 3),
  amount bigint not null check (amount > 0),
  method_type text not null check (method_type in ('cash', 'qris', 'card', 'transfer', 'ewallet')),
  restock boolean not null default true,
  points_reversed integer not null default 0 check (points_reversed >= 0),
  employee_id uuid not null references public.employees (id),
  approved_by uuid not null references public.employees (id),
  refunded_at timestamptz not null,
  business_date date not null,
  created_at timestamptz not null default now(),
  unique (store_id, refund_number),
  check (method_type <> 'cash' or shift_id is not null)
);
create index refunds_order_idx on public.refunds (order_id);
create index refunds_store_business_date_idx on public.refunds (store_id, business_date);
create index refunds_shift_idx on public.refunds (shift_id);

create table public.refund_items (
  id uuid primary key,
  refund_id uuid not null references public.refunds (id) on delete cascade,
  store_id uuid not null references public.stores (id),
  order_item_id uuid not null references public.order_items (id),
  quantity numeric(14,3) not null check (quantity > 0),
  amount bigint not null check (amount >= 0),
  created_at timestamptz not null default now(),
  unique (refund_id, order_item_id)
);
create index refund_items_order_item_idx on public.refund_items (order_item_id);

-- ---------------------------------------------------------------------------
-- Kasbon (receivables) and repayments
-- ---------------------------------------------------------------------------
create table public.receivables (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores (id),
  customer_id uuid not null references public.customers (id),
  order_id uuid not null unique references public.orders (id),
  amount bigint not null check (amount > 0),
  paid_amount bigint not null default 0 check (paid_amount >= 0),
  due_date date not null,
  status text not null default 'open' check (status in ('open', 'partial', 'paid', 'void')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index receivables_customer_idx on public.receivables (customer_id);
create index receivables_store_status_idx on public.receivables (store_id, status, due_date);

create table public.receivable_payments (
  id uuid primary key,
  receivable_id uuid not null references public.receivables (id),
  store_id uuid not null references public.stores (id),
  shift_id uuid references public.shifts (id),
  amount bigint not null check (amount > 0),
  method_type text not null check (method_type in ('cash', 'qris', 'card', 'transfer', 'ewallet')),
  reference text,
  employee_id uuid not null references public.employees (id),
  note text,
  paid_at timestamptz not null,
  created_at timestamptz not null default now(),
  check (method_type <> 'cash' or shift_id is not null)
);
create index receivable_payments_receivable_idx on public.receivable_payments (receivable_id);
create index receivable_payments_shift_idx on public.receivable_payments (shift_id);
create index receivable_payments_store_created_idx on public.receivable_payments (store_id, created_at desc);

-- ---------------------------------------------------------------------------
-- Loyalty ledger (balance = sum of points; customers.points_balance caches it)
-- ---------------------------------------------------------------------------
create table public.loyalty_ledger (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.customers (id),
  store_id uuid references public.stores (id),
  order_id uuid references public.orders (id),
  refund_id uuid references public.refunds (id),
  entry_type text not null check (entry_type in ('earn', 'redeem', 'reverse_earn', 'reverse_redeem', 'adjust')),
  points integer not null check (points <> 0),
  note text,
  employee_id uuid references public.employees (id),
  created_at timestamptz not null default now(),
  check (entry_type not in ('earn', 'reverse_redeem') or points > 0),
  check (entry_type not in ('redeem', 'reverse_earn') or points < 0)
);
create index loyalty_ledger_customer_idx on public.loyalty_ledger (customer_id, created_at desc);
create unique index loyalty_ledger_order_entry_key
  on public.loyalty_ledger (order_id, entry_type) where order_id is not null and refund_id is null;
create unique index loyalty_ledger_refund_entry_key
  on public.loyalty_ledger (refund_id, entry_type) where refund_id is not null;

-- ---------------------------------------------------------------------------
-- Voucher redemptions
-- ---------------------------------------------------------------------------
create table public.voucher_redemptions (
  id uuid primary key default gen_random_uuid(),
  voucher_id uuid not null references public.vouchers (id),
  order_id uuid not null references public.orders (id),
  store_id uuid not null references public.stores (id),
  customer_id uuid references public.customers (id),
  amount bigint not null check (amount > 0),
  is_reversed boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (voucher_id, order_id)
);
create index voucher_redemptions_store_idx on public.voucher_redemptions (store_id, created_at desc);

-- ---------------------------------------------------------------------------
-- Kitchen / bar fulfilment status (KDS tickets), one row per order per station
-- ---------------------------------------------------------------------------
create table public.order_status (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  store_id uuid not null references public.stores (id),
  station text not null check (station in ('kitchen', 'bar')),
  status text not null default 'new' check (status in ('new', 'preparing', 'ready', 'served', 'cancelled')),
  updated_by uuid references public.employees (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (order_id, station)
);
create index order_status_store_active_idx
  on public.order_status (store_id, status) where status in ('new', 'preparing', 'ready');
