-- =============================================================================
-- CashierA · 0800 · Expenses (cash-flow reports combine these with sales,
-- kasbon repayments, refunds and petty cash).
-- =============================================================================

create table public.expense_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(trim(name)) > 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index expense_categories_name_key on public.expense_categories (lower(name));

insert into public.expense_categories (name) values
  ('Listrik'), ('Air'), ('Sewa'), ('Gaji'), ('Transportasi'),
  ('ATK'), ('Kebersihan'), ('Perawatan'), ('Lain-lain');

create table public.expenses (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores (id),
  category_id uuid not null references public.expense_categories (id),
  amount bigint not null check (amount > 0),
  expense_date date not null,
  description text not null check (length(trim(description)) >= 3),
  paid_from text not null check (paid_from in ('cash_drawer', 'petty_cash', 'bank', 'other')),
  cash_movement_id uuid references public.cash_movements (id),
  attachment_path text,
  employee_id uuid not null references public.employees (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index expenses_store_date_idx on public.expenses (store_id, expense_date desc);
comment on column public.expenses.cash_movement_id is
  'Links an expense to the petty-cash-out that paid it, so cash-flow reports do not count it twice.';
comment on column public.expenses.attachment_path is 'Storage path in bucket expense-attachments: <store_id>/<expense_id>/<file>.';
