-- =============================================================================
-- CashierA · 0700 · Inventory: stock levels and movements, adjustments,
-- stock opname, purchase orders, goods receipts, transfers, alerts.
-- Stock only changes through app.apply_stock_delta (see 1000).
-- =============================================================================

create table public.stock_levels (
  store_id uuid not null references public.stores (id) on delete cascade,
  variant_id uuid not null references public.product_variants (id) on delete cascade,
  quantity numeric(14,3) not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (store_id, variant_id)
);
create index stock_levels_variant_idx on public.stock_levels (variant_id);
comment on table public.stock_levels is 'On-hand stock per store and variant. May go negative (offline sales); see alerts.';

create table public.stock_movements (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores (id),
  variant_id uuid not null references public.product_variants (id),
  movement_type text not null check (movement_type in (
    'initial', 'sale', 'sale_void', 'refund', 'purchase_receive', 'adjustment',
    'waste', 'opname', 'transfer_out', 'transfer_in')),
  quantity_delta numeric(14,3) not null check (quantity_delta <> 0),
  balance_after numeric(14,3) not null,
  unit_cost bigint not null default 0 check (unit_cost >= 0),
  reference_type text check (reference_type in (
    'order', 'refund', 'stock_adjustment', 'stock_opname', 'goods_receipt', 'stock_transfer')),
  reference_id uuid,
  employee_id uuid references public.employees (id),
  note text,
  created_at timestamptz not null default now()
);
create index stock_movements_store_created_idx on public.stock_movements (store_id, created_at desc);
create index stock_movements_store_variant_idx on public.stock_movements (store_id, variant_id, created_at desc);
create index stock_movements_reference_idx on public.stock_movements (reference_type, reference_id);

-- ---------------------------------------------------------------------------
-- Manual stock in / out / adjustments (works offline through sync_push)
-- ---------------------------------------------------------------------------
create table public.stock_adjustments (
  id uuid primary key,
  store_id uuid not null references public.stores (id),
  adjustment_number text not null,
  reason text not null check (reason in ('initial', 'stock_in', 'stock_out', 'damaged', 'expired', 'lost', 'correction')),
  note text,
  employee_id uuid not null references public.employees (id),
  approved_by uuid references public.employees (id),
  occurred_at timestamptz not null,
  created_at timestamptz not null default now(),
  unique (store_id, adjustment_number)
);
create index stock_adjustments_store_created_idx on public.stock_adjustments (store_id, created_at desc);

create table public.stock_adjustment_items (
  id uuid primary key,
  adjustment_id uuid not null references public.stock_adjustments (id) on delete cascade,
  store_id uuid not null references public.stores (id),
  variant_id uuid not null references public.product_variants (id),
  quantity_delta numeric(14,3) not null check (quantity_delta <> 0),
  unit_cost bigint check (unit_cost >= 0),
  created_at timestamptz not null default now(),
  unique (adjustment_id, variant_id)
);

-- ---------------------------------------------------------------------------
-- Stock opname (physical count)
-- ---------------------------------------------------------------------------
create table public.stock_opnames (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores (id),
  opname_number text not null,
  status text not null default 'draft' check (status in ('draft', 'completed', 'cancelled')),
  note text,
  created_by uuid not null references public.employees (id),
  completed_by uuid references public.employees (id),
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (store_id, opname_number),
  check (status <> 'completed' or (completed_at is not null and completed_by is not null))
);

create table public.stock_opname_items (
  id uuid primary key default gen_random_uuid(),
  opname_id uuid not null references public.stock_opnames (id) on delete cascade,
  store_id uuid not null references public.stores (id),
  variant_id uuid not null references public.product_variants (id),
  counted_qty numeric(14,3) not null check (counted_qty >= 0),
  system_qty numeric(14,3),
  difference numeric(14,3),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (opname_id, variant_id)
);
comment on column public.stock_opname_items.system_qty is 'Stock on hand at the moment the opname was completed.';

-- ---------------------------------------------------------------------------
-- Purchasing
-- ---------------------------------------------------------------------------
create sequence public.purchase_order_seq;

create table public.purchase_orders (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores (id),
  supplier_id uuid not null references public.suppliers (id),
  po_number text not null unique default ('PO-' || to_char(now() at time zone 'Asia/Jakarta', 'YYMMDD') || '-' || lpad(nextval('public.purchase_order_seq')::text, 5, '0')),
  status text not null default 'draft' check (status in ('draft', 'ordered', 'partially_received', 'received', 'cancelled')),
  order_date date not null default current_date,
  expected_date date,
  note text,
  total_amount bigint not null default 0 check (total_amount >= 0),
  created_by uuid not null references public.employees (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index purchase_orders_store_status_idx on public.purchase_orders (store_id, status, created_at desc);

create table public.purchase_order_items (
  id uuid primary key default gen_random_uuid(),
  purchase_order_id uuid not null references public.purchase_orders (id) on delete cascade,
  variant_id uuid not null references public.product_variants (id),
  quantity_ordered numeric(14,3) not null check (quantity_ordered > 0),
  unit_cost bigint not null check (unit_cost >= 0),
  quantity_received numeric(14,3) not null default 0 check (quantity_received >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (purchase_order_id, variant_id)
);

create table public.goods_receipts (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores (id),
  purchase_order_id uuid references public.purchase_orders (id),
  supplier_id uuid references public.suppliers (id),
  receipt_number text not null,
  received_at timestamptz not null default now(),
  received_by uuid not null references public.employees (id),
  note text,
  created_at timestamptz not null default now(),
  unique (store_id, receipt_number)
);
create index goods_receipts_store_received_idx on public.goods_receipts (store_id, received_at desc);

create table public.goods_receipt_items (
  id uuid primary key default gen_random_uuid(),
  goods_receipt_id uuid not null references public.goods_receipts (id) on delete cascade,
  store_id uuid not null references public.stores (id),
  variant_id uuid not null references public.product_variants (id),
  purchase_order_item_id uuid references public.purchase_order_items (id),
  quantity numeric(14,3) not null check (quantity > 0),
  unit_cost bigint not null check (unit_cost >= 0),
  created_at timestamptz not null default now()
);
create index goods_receipt_items_receipt_idx on public.goods_receipt_items (goods_receipt_id);

-- ---------------------------------------------------------------------------
-- Transfers between stores: requested -> approved -> in_transit -> received
-- ---------------------------------------------------------------------------
create sequence public.stock_transfer_seq;

create table public.stock_transfers (
  id uuid primary key default gen_random_uuid(),
  transfer_number text not null unique default ('TRF-' || to_char(now() at time zone 'Asia/Jakarta', 'YYMMDD') || '-' || lpad(nextval('public.stock_transfer_seq')::text, 5, '0')),
  from_store_id uuid not null references public.stores (id),
  to_store_id uuid not null references public.stores (id),
  status text not null default 'requested' check (status in ('requested', 'approved', 'in_transit', 'received', 'rejected', 'cancelled')),
  note text,
  requested_by uuid not null references public.employees (id),
  requested_at timestamptz not null default now(),
  approved_by uuid references public.employees (id),
  approved_at timestamptz,
  shipped_by uuid references public.employees (id),
  shipped_at timestamptz,
  received_by uuid references public.employees (id),
  received_at timestamptz,
  rejected_by uuid references public.employees (id),
  rejected_at timestamptz,
  reject_reason text,
  cancelled_by uuid references public.employees (id),
  cancelled_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (from_store_id <> to_store_id)
);
create index stock_transfers_from_idx on public.stock_transfers (from_store_id, status);
create index stock_transfers_to_idx on public.stock_transfers (to_store_id, status);

create table public.stock_transfer_items (
  id uuid primary key default gen_random_uuid(),
  transfer_id uuid not null references public.stock_transfers (id) on delete cascade,
  variant_id uuid not null references public.product_variants (id),
  quantity_requested numeric(14,3) not null check (quantity_requested > 0),
  quantity_shipped numeric(14,3) check (quantity_shipped >= 0),
  quantity_received numeric(14,3) check (quantity_received >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (transfer_id, variant_id)
);

-- ---------------------------------------------------------------------------
-- Alerts for managers (stock discrepancies, cash mismatches, ...)
-- ---------------------------------------------------------------------------
create table public.alerts (
  id uuid primary key default gen_random_uuid(),
  store_id uuid references public.stores (id),
  alert_type text not null check (alert_type in (
    'LOW_STOCK', 'STOCK_DISCREPANCY', 'TRANSFER_DISCREPANCY', 'CASH_DISCREPANCY',
    'LOYALTY_NEGATIVE', 'KASBON_OVERPAID', 'KASBON_LIMIT', 'VOUCHER_OVERUSED',
    'CUSTOMER_DUPLICATE', 'LATE_SYNC')),
  severity text not null default 'warning' check (severity in ('info', 'warning', 'critical')),
  variant_id uuid references public.product_variants (id),
  reference_type text,
  reference_id uuid,
  message text not null,
  details jsonb not null default '{}'::jsonb,
  status text not null default 'open' check (status in ('open', 'acknowledged', 'resolved')),
  resolved_by uuid references public.employees (id),
  resolved_at timestamptz,
  resolution_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index alerts_store_open_idx on public.alerts (store_id, created_at desc) where status <> 'resolved';
create index alerts_reference_idx on public.alerts (reference_type, reference_id);
create unique index alerts_low_stock_open_key
  on public.alerts (store_id, variant_id) where alert_type = 'LOW_STOCK' and status <> 'resolved';
