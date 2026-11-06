-- =============================================================================
-- CashierA · 0400 · Company catalog and per-store catalog settings
-- Global: units, categories, suppliers, products, variants, modifiers, recipes.
-- Per store: price overrides, reorder points, availability, favorites.
-- =============================================================================

create table public.units (
  id uuid primary key default gen_random_uuid(),
  code text not null unique check (code ~ '^[a-z][a-z0-9_]*$'),
  name text not null check (length(trim(name)) > 0),
  allow_decimal boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

insert into public.units (code, name, allow_decimal) values
  ('pcs',     'Pcs',     false),
  ('kg',      'Kg',      true),
  ('g',       'Gram',    true),
  ('l',       'Liter',   true),
  ('ml',      'Ml',      true),
  ('pack',    'Pak',     false),
  ('box',     'Kotak',   false),
  ('dus',     'Dus',     false),
  ('renceng', 'Renceng', false),
  ('lusin',   'Lusin',   false);

create table public.categories (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid references public.categories (id),
  name text not null check (length(trim(name)) > 0),
  sort_order integer not null default 0,
  color text check (color ~ '^#[0-9A-Fa-f]{6}$'),
  icon text,
  kitchen_station text check (kitchen_station in ('kitchen', 'bar')),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (parent_id is distinct from id)
);
create unique index categories_name_key
  on public.categories (coalesce(parent_id, '00000000-0000-0000-0000-000000000000'::uuid), lower(name));
comment on column public.categories.sort_order is 'Order of category pills on the cashier screen.';

create table public.suppliers (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(trim(name)) > 0),
  contact_name text,
  phone text,
  email text,
  address text,
  notes text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index suppliers_name_key on public.suppliers (lower(name));

create table public.products (
  id uuid primary key default gen_random_uuid(),
  category_id uuid references public.categories (id),
  unit_id uuid not null references public.units (id),
  name text not null check (length(trim(name)) > 0),
  description text,
  product_type text not null default 'standard' check (product_type in ('standard', 'ingredient', 'service')),
  track_stock boolean not null default true,
  is_taxable boolean not null default true,
  kitchen_station text check (kitchen_station in ('kitchen', 'bar')),
  image_path text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (product_type <> 'service' or not track_stock)
);
create index products_category_idx on public.products (category_id);
create index products_name_idx on public.products (lower(name));
comment on column public.products.is_taxable is 'False for PPN-exempt goods (e.g. beras, gula, telur).';
comment on column public.products.product_type is 'ingredient = stocked but not sold directly (used by recipes).';

-- The sellable SKU. Every product has at least one variant ("Default").
create table public.product_variants (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products (id) on delete cascade,
  name text not null default 'Default' check (length(trim(name)) > 0),
  sku text not null check (sku ~ '^[A-Za-z0-9._-]{1,40}$'),
  barcode text check (barcode ~ '^[0-9A-Za-z-]{4,32}$'),
  price bigint not null check (price >= 0),
  cost bigint not null default 0 check (cost >= 0),
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index product_variants_sku_key on public.product_variants (upper(sku));
create unique index product_variants_barcode_key on public.product_variants (barcode) where barcode is not null;
create index product_variants_product_idx on public.product_variants (product_id);
comment on column public.product_variants.price is 'Default selling price in rupiah (tax-inclusive when the store is tax-inclusive).';
comment on column public.product_variants.cost is 'COGS per unit in rupiah; goods receipts update it by weighted average.';

create table public.modifier_groups (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(trim(name)) > 0),
  min_select smallint not null default 0 check (min_select >= 0),
  max_select smallint not null default 1 check (max_select >= 1),
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (min_select <= max_select)
);

create table public.modifiers (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.modifier_groups (id) on delete cascade,
  name text not null check (length(trim(name)) > 0),
  price_delta bigint not null default 0 check (price_delta >= 0),
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index modifiers_group_idx on public.modifiers (group_id);

create table public.product_modifier_groups (
  product_id uuid not null references public.products (id) on delete cascade,
  group_id uuid not null references public.modifier_groups (id) on delete cascade,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (product_id, group_id)
);
create index product_modifier_groups_group_idx on public.product_modifier_groups (group_id);

-- Bill of materials: selling 1 unit of variant_id consumes `quantity` of the ingredient.
create table public.recipe_items (
  id uuid primary key default gen_random_uuid(),
  variant_id uuid not null references public.product_variants (id) on delete cascade,
  ingredient_variant_id uuid not null references public.product_variants (id),
  quantity numeric(14,3) not null check (quantity > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (variant_id, ingredient_variant_id),
  check (variant_id <> ingredient_variant_id)
);
create index recipe_items_ingredient_idx on public.recipe_items (ingredient_variant_id);

create table public.modifier_recipe_items (
  id uuid primary key default gen_random_uuid(),
  modifier_id uuid not null references public.modifiers (id) on delete cascade,
  ingredient_variant_id uuid not null references public.product_variants (id),
  quantity numeric(14,3) not null check (quantity > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (modifier_id, ingredient_variant_id)
);

-- Recipes are one level deep: an ingredient can't have its own recipe,
-- and a variant with a recipe can't be used as an ingredient.
create or replace function app.guard_recipe_depth()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if exists (select 1 from public.recipe_items r where r.variant_id = new.ingredient_variant_id) then
    perform app.fail('recipe_nested', 'an ingredient cannot itself have a recipe');
  end if;
  -- Nested IF: modifier_recipe_items rows have no variant_id field.
  if tg_table_name = 'recipe_items' then
    if exists (select 1 from public.recipe_items r where r.ingredient_variant_id = new.variant_id) then
      perform app.fail('recipe_nested', 'this variant is already used as an ingredient');
    end if;
  end if;
  return new;
end;
$$;

create trigger recipe_items_depth
before insert or update on public.recipe_items
for each row execute function app.guard_recipe_depth();

create trigger modifier_recipe_items_depth
before insert or update on public.modifier_recipe_items
for each row execute function app.guard_recipe_depth();

-- Per-store price override, reorder point and availability.
create table public.store_variant_settings (
  store_id uuid not null references public.stores (id) on delete cascade,
  variant_id uuid not null references public.product_variants (id) on delete cascade,
  price_override bigint check (price_override >= 0),
  reorder_point numeric(14,3) check (reorder_point >= 0),
  reorder_qty numeric(14,3) check (reorder_qty > 0),
  is_available boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (store_id, variant_id)
);
create index store_variant_settings_variant_idx on public.store_variant_settings (variant_id);

-- Favorites row on the cashier screen, per store.
create table public.store_favorites (
  store_id uuid not null references public.stores (id) on delete cascade,
  product_id uuid not null references public.products (id) on delete cascade,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (store_id, product_id)
);
