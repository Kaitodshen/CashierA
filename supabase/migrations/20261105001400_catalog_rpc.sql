-- =============================================================================
-- CashierA · 1400 · Catalog RPCs (Phase 3)
--   save_product(p)        product + variants + per-store settings, atomically
--   import_catalog(rows)   CSV/XLSX import, all-or-nothing; stock via opname
--   stock_overview(store)  stock per variant with low-stock flag (RLS applies)
--   catalog_export()       the catalog in the import template's columns
-- =============================================================================

-- ---------------------------------------------------------------------------
-- save_product
-- p = {id?, name, description?, category_id?, unit_id, product_type?, track_stock?,
--      is_taxable?, kitchen_station?, image_path?, is_active?,
--      variants: [{id, name, sku, barcode?, price, cost, sort_order?, is_active?}],
--      store_settings?: [{store_id, variant_id, price_override?, reorder_point?, is_available?}]}
-- Variants missing from the payload are deactivated (they may have sales history).
-- ---------------------------------------------------------------------------
create or replace function public.save_product(p jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid := coalesce((p ->> 'id')::uuid, gen_random_uuid());
  v_variant jsonb;
  v_variant_id uuid;
  v_keep uuid[] := '{}';
  v_setting jsonb;
begin
  if not app.has_permission('catalog.manage') then
    perform app.fail('permission_denied', 'catalog.manage is required');
  end if;
  if coalesce(length(trim(p ->> 'name')), 0) = 0 then
    perform app.fail('invalid_input', 'product name is required');
  end if;
  if jsonb_typeof(p -> 'variants') is distinct from 'array' or jsonb_array_length(p -> 'variants') = 0 then
    perform app.fail('invalid_input', 'a product needs at least one variant');
  end if;
  insert into public.products (id, category_id, unit_id, name, description, product_type, track_stock,
                               is_taxable, kitchen_station, image_path, is_active)
  values (v_id, (p ->> 'category_id')::uuid, (p ->> 'unit_id')::uuid, trim(p ->> 'name'), p ->> 'description',
          coalesce(p ->> 'product_type', 'standard'), coalesce((p ->> 'track_stock')::boolean, true),
          coalesce((p ->> 'is_taxable')::boolean, true), p ->> 'kitchen_station', p ->> 'image_path',
          coalesce((p ->> 'is_active')::boolean, true))
  on conflict (id) do update set
    category_id = excluded.category_id,
    unit_id = excluded.unit_id,
    name = excluded.name,
    description = excluded.description,
    product_type = excluded.product_type,
    track_stock = excluded.track_stock,
    is_taxable = excluded.is_taxable,
    kitchen_station = excluded.kitchen_station,
    image_path = excluded.image_path,
    is_active = excluded.is_active;

  for v_variant in select value from jsonb_array_elements(p -> 'variants') loop
    v_variant_id := coalesce((v_variant ->> 'id')::uuid, gen_random_uuid());
    if exists (select 1 from public.product_variants x
               where upper(x.sku) = upper(trim(v_variant ->> 'sku')) and x.id <> v_variant_id) then
      perform app.fail('duplicate_sku', trim(v_variant ->> 'sku'));
    end if;
    if nullif(trim(v_variant ->> 'barcode'), '') is not null and exists (
         select 1 from public.product_variants x
         where x.barcode = trim(v_variant ->> 'barcode') and x.id <> v_variant_id) then
      perform app.fail('duplicate_barcode', trim(v_variant ->> 'barcode'));
    end if;
    if exists (select 1 from public.product_variants x where x.id = v_variant_id and x.product_id <> v_id) then
      perform app.fail('invalid_input', 'variant belongs to another product');
    end if;

    insert into public.product_variants (id, product_id, name, sku, barcode, price, cost, sort_order, is_active)
    values (v_variant_id, v_id, coalesce(nullif(trim(v_variant ->> 'name'), ''), 'Default'), trim(v_variant ->> 'sku'),
            nullif(trim(v_variant ->> 'barcode'), ''), (v_variant ->> 'price')::bigint,
            coalesce((v_variant ->> 'cost')::bigint, 0), coalesce((v_variant ->> 'sort_order')::integer, 0),
            coalesce((v_variant ->> 'is_active')::boolean, true))
    on conflict (id) do update set
      name = excluded.name,
      sku = excluded.sku,
      barcode = excluded.barcode,
      price = excluded.price,
      cost = excluded.cost,
      sort_order = excluded.sort_order,
      is_active = excluded.is_active;
    v_keep := v_keep || v_variant_id;
  end loop;

  update public.product_variants
     set is_active = false
   where product_id = v_id and not (id = any (v_keep)) and is_active;

  for v_setting in select value from jsonb_array_elements(coalesce(p -> 'store_settings', '[]'::jsonb)) loop
    if not ((v_setting ->> 'variant_id')::uuid = any (v_keep)) then
      perform app.fail('invalid_input', 'store setting for a variant not in this product');
    end if;
    insert into public.store_variant_settings (store_id, variant_id, price_override, reorder_point, is_available)
    values ((v_setting ->> 'store_id')::uuid, (v_setting ->> 'variant_id')::uuid,
            (v_setting ->> 'price_override')::bigint, (v_setting ->> 'reorder_point')::numeric,
            coalesce((v_setting ->> 'is_available')::boolean, true))
    on conflict (store_id, variant_id) do update set
      price_override = excluded.price_override,
      reorder_point = excluded.reorder_point,
      is_available = excluded.is_available;
  end loop;

  return jsonb_build_object('product_id', v_id, 'variants', cardinality(v_keep));
end;
$$;

-- ---------------------------------------------------------------------------
-- import_catalog
-- p_rows = [{row, product_name, variant_name, sku, barcode?, category, unit, price, cost,
--            taxable, track_stock, reorder_point?, stock: {"PST": "12.5", ...}}]
-- Rows were validated by the app (cashiera_core); the database re-checks what
-- it can and rolls everything back on the first problem.
-- ---------------------------------------------------------------------------
create or replace function public.import_catalog(p_rows jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_employee uuid := app.current_employee_id();
  r jsonb;
  v_row text;
  v_unit uuid;
  v_category uuid;
  v_product uuid;
  v_variant uuid;
  v_created_products uuid[] := '{}';
  v_updated_products uuid[] := '{}';
  v_categories_created integer := 0;
  v_variants_created integer := 0;
  v_variants_updated integer := 0;
  v_stock jsonb := '{}'::jsonb;
  v_code text;
  v_lines jsonb;
  v_store uuid;
  v_opname uuid;
  v_stock_lines integer := 0;
  v_stamp text := to_char(now() at time zone 'Asia/Jakarta', 'YYMMDDHH24MISS');
begin
  if v_employee is null or not app.has_permission('catalog.manage') then
    perform app.fail('permission_denied', 'catalog.manage is required to import');
  end if;
  if jsonb_typeof(p_rows) is distinct from 'array' or jsonb_array_length(p_rows) = 0 then
    perform app.fail('invalid_input', 'nothing to import');
  end if;
  if jsonb_array_length(p_rows) > 5000 then
    perform app.fail('invalid_input', 'at most 5000 rows per import');
  end if;

  for r in select value from jsonb_array_elements(p_rows) loop
    v_row := coalesce(r ->> 'row', '?');

    select u.id into v_unit from public.units u where u.code = lower(trim(r ->> 'unit'));
    if v_unit is null then
      perform app.fail('import_invalid', format('row %s: unknown unit "%s"', v_row, r ->> 'unit'));
    end if;

    select c.id into v_category
    from public.categories c
    where c.parent_id is null and lower(c.name) = lower(trim(r ->> 'category'));
    if v_category is null then
      insert into public.categories (name, sort_order)
      values (trim(r ->> 'category'), coalesce((select max(sort_order) from public.categories), 0) + 10)
      returning id into v_category;
      v_categories_created := v_categories_created + 1;
    end if;

    v_variant := null;
    v_product := null;
    select pv.id, pv.product_id into v_variant, v_product
    from public.product_variants pv where upper(pv.sku) = upper(trim(r ->> 'sku'));

    if v_product is null then
      select x.id into v_product
      from public.products x
      where lower(x.name) = lower(trim(r ->> 'product_name'))
      order by x.is_active desc, x.created_at
      limit 1;
    end if;

    if v_product is null then
      insert into public.products (category_id, unit_id, name, track_stock, is_taxable)
      values (v_category, v_unit, trim(r ->> 'product_name'), (r ->> 'track_stock')::boolean,
              (r ->> 'taxable')::boolean)
      returning id into v_product;
      v_created_products := v_created_products || v_product;
    else
      update public.products
         set name = trim(r ->> 'product_name'), category_id = v_category, unit_id = v_unit,
             track_stock = (r ->> 'track_stock')::boolean, is_taxable = (r ->> 'taxable')::boolean,
             is_active = true
       where id = v_product;
      if not (v_product = any (v_created_products)) and not (v_product = any (v_updated_products)) then
        v_updated_products := v_updated_products || v_product;
      end if;
    end if;

    if nullif(trim(r ->> 'barcode'), '') is not null and exists (
         select 1 from public.product_variants x
         where x.barcode = trim(r ->> 'barcode') and x.id is distinct from v_variant) then
      perform app.fail('import_invalid', format('row %s: barcode %s is already used by SKU %s', v_row,
        trim(r ->> 'barcode'),
        (select x.sku from public.product_variants x where x.barcode = trim(r ->> 'barcode'))));
    end if;

    if v_variant is null then
      insert into public.product_variants (product_id, name, sku, barcode, price, cost, sort_order)
      values (v_product, coalesce(nullif(trim(r ->> 'variant_name'), ''), 'Default'), trim(r ->> 'sku'),
              nullif(trim(r ->> 'barcode'), ''), (r ->> 'price')::bigint, (r ->> 'cost')::bigint,
              (select count(*) from public.product_variants x where x.product_id = v_product))
      returning id into v_variant;
      v_variants_created := v_variants_created + 1;
    else
      update public.product_variants
         set product_id = v_product, name = coalesce(nullif(trim(r ->> 'variant_name'), ''), 'Default'),
             barcode = nullif(trim(r ->> 'barcode'), ''), price = (r ->> 'price')::bigint,
             cost = (r ->> 'cost')::bigint, is_active = true
       where id = v_variant;
      v_variants_updated := v_variants_updated + 1;
    end if;

    if nullif(r ->> 'reorder_point', '') is not null then
      insert into public.store_variant_settings (store_id, variant_id, reorder_point)
      select s.id, v_variant, (r ->> 'reorder_point')::numeric from public.stores s where s.is_active
      on conflict (store_id, variant_id) do update set reorder_point = excluded.reorder_point;
    end if;

    if (r ->> 'track_stock')::boolean and jsonb_typeof(r -> 'stock') = 'object' then
      for v_code in select jsonb_object_keys(r -> 'stock') loop
        if nullif(r -> 'stock' ->> v_code, '') is not null then
          v_stock := jsonb_set(v_stock, array[v_code],
            coalesce(v_stock -> v_code, '[]'::jsonb)
              || jsonb_build_array(jsonb_build_object('variant_id', v_variant, 'qty', r -> 'stock' ->> v_code)));
        end if;
      end loop;
    end if;
  end loop;

  -- Opening / counted stock: one opname per store, so history says why it changed.
  for v_code, v_lines in select key, value from jsonb_each(v_stock) loop
    select s.id into v_store from public.stores s where s.code = upper(v_code);
    if v_store is null then
      perform app.fail('import_invalid', format('unknown store code %s in a stock column', v_code));
    end if;
    if not app.employee_can(v_employee, v_store, 'inventory.opname') then
      perform app.fail('permission_denied', format('inventory.opname is required at %s', upper(v_code)));
    end if;
    insert into public.stock_opnames (store_id, opname_number, note, created_by)
    -- The random suffix keeps two imports in the same second apart.
    values (v_store,
            'IMPORT-' || v_stamp || '-' || upper(v_code) || '-' || substr(md5(gen_random_uuid()::text), 1, 4),
            'Impor katalog', v_employee)
    returning id into v_opname;
    insert into public.stock_opname_items (opname_id, store_id, variant_id, counted_qty)
    select v_opname, v_store, (l ->> 'variant_id')::uuid, (l ->> 'qty')::numeric
    from jsonb_array_elements(v_lines) as l;
    perform app.complete_opname(v_opname, v_employee);
    v_stock_lines := v_stock_lines + jsonb_array_length(v_lines);
  end loop;

  insert into public.audit_log (actor_employee_id, action, entity_type, details)
  values (v_employee, 'catalog.imported', 'catalog', jsonb_build_object(
    'rows', jsonb_array_length(p_rows), 'variants_created', v_variants_created,
    'variants_updated', v_variants_updated, 'stock_lines', v_stock_lines));

  return jsonb_build_object(
    'categories_created', v_categories_created,
    'products_created', cardinality(v_created_products),
    'products_updated', cardinality(v_updated_products),
    'variants_created', v_variants_created,
    'variants_updated', v_variants_updated,
    'stock_lines', v_stock_lines);
end;
$$;

-- ---------------------------------------------------------------------------
-- stock_overview: what the Stock page and terminals show. Security invoker, so
-- RLS decides which stores the caller can see.
-- ---------------------------------------------------------------------------
create or replace function public.stock_overview(p_store_id uuid)
returns table (
  variant_id uuid,
  product_id uuid,
  sku text,
  barcode text,
  product_name text,
  variant_name text,
  category_name text,
  unit_code text,
  quantity numeric,
  reorder_point numeric,
  is_low boolean
)
language sql
stable
security invoker
set search_path = ''
as $$
  select v.id, p.id, v.sku, v.barcode, p.name, v.name, c.name, u.code,
         coalesce(sl.quantity, 0),
         svs.reorder_point,
         svs.reorder_point is not null and coalesce(sl.quantity, 0) <= svs.reorder_point
  from public.product_variants v
  join public.products p on p.id = v.product_id
  join public.units u on u.id = p.unit_id
  left join public.categories c on c.id = p.category_id
  left join public.stock_levels sl on sl.variant_id = v.id and sl.store_id = p_store_id
  left join public.store_variant_settings svs on svs.variant_id = v.id and svs.store_id = p_store_id
  where v.is_active and p.is_active and p.track_stock
    and p_store_id in (select unnest(app.store_ids_with(array['inventory.view', 'reports.view', 'pos.sell'])))
  order by p.name, v.sort_order
$$;

-- ---------------------------------------------------------------------------
-- catalog_export: one row per active variant, columns of the import template.
-- stock = {"PST": 12.5, ...} for the stores the caller can see.
-- ---------------------------------------------------------------------------
create or replace function public.catalog_export()
returns table (
  product_name text,
  variant_name text,
  sku text,
  barcode text,
  category text,
  unit text,
  price bigint,
  cost bigint,
  taxable boolean,
  track_stock boolean,
  reorder_point numeric,
  stock jsonb
)
language sql
stable
security invoker
set search_path = ''
as $$
  select p.name, v.name, v.sku, v.barcode, c.name, u.code, v.price, v.cost, p.is_taxable, p.track_stock,
         (select max(svs.reorder_point) from public.store_variant_settings svs where svs.variant_id = v.id),
         (select coalesce(jsonb_object_agg(s.code, sl.quantity order by s.code), '{}'::jsonb)
            from public.stock_levels sl join public.stores s on s.id = sl.store_id
           where sl.variant_id = v.id)
  from public.product_variants v
  join public.products p on p.id = v.product_id
  join public.units u on u.id = p.unit_id
  left join public.categories c on c.id = p.category_id
  where v.is_active and p.is_active
  order by c.sort_order nulls last, p.name, v.sort_order
$$;

revoke execute on function public.save_product(jsonb), public.import_catalog(jsonb),
  public.stock_overview(uuid), public.catalog_export() from public, anon;
grant execute on function public.save_product(jsonb), public.import_catalog(jsonb),
  public.stock_overview(uuid), public.catalog_export() to authenticated, service_role;
