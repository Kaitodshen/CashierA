-- Phase 3 catalog RPCs: import (all-or-nothing, idempotent, stock via opname),
-- save_product, stock_overview scoping, catalog_export.
begin;
create extension if not exists pgtap with schema extensions;
select plan(19);

create or replace function pg_temp.rows(p_variant_price bigint default 4100, p_sku text default 'KPB-100')
returns jsonb language sql as $$
  select jsonb_build_array(
    jsonb_build_object('row', 2, 'product_name', 'Kopi Bubuk Uji', 'variant_name', '100 g', 'sku', p_sku,
      'barcode', '2009999000017', 'category', 'Kategori Uji', 'unit', 'pcs', 'price', 15000, 'cost', 11000,
      'taxable', true, 'track_stock', true, 'reorder_point', '3', 'stock', jsonb_build_object('PST', '10')),
    jsonb_build_object('row', 3, 'product_name', 'Kopi Bubuk Uji', 'variant_name', '200 g', 'sku', 'KPB-200',
      'barcode', null, 'category', 'Kategori Uji', 'unit', 'pcs', 'price', 28000, 'cost', 21000,
      'taxable', true, 'track_stock', true, 'reorder_point', '3', 'stock', jsonb_build_object('PST', '5')),
    jsonb_build_object('row', 4, 'product_name', 'Air Mineral', 'variant_name', '600 ml', 'sku', 'MNM-AIR-600',
      'barcode', '2000000000015', 'category', 'Minuman', 'unit', 'pcs', 'price', p_variant_price, 'cost', 2600,
      'taxable', true, 'track_stock', true, 'reorder_point', '10', 'stock', jsonb_build_object('BKS', '20')))
$$;

create temporary table t_result (name text primary key, result jsonb);
grant select, insert on t_result to authenticated;

-- Import as the owner ---------------------------------------------------------------------
select tests.act_as(tests.id('user.owner'));
insert into t_result values ('first', public.import_catalog(pg_temp.rows()));
select is(
  (select array[(result ->> 'categories_created')::int, (result ->> 'products_created')::int,
                (result ->> 'variants_created')::int, (result ->> 'variants_updated')::int,
                (result ->> 'stock_lines')::int] from t_result where name = 'first'),
  array[1, 1, 2, 1, 3], 'first import: 1 category, 1 product, 2 new + 1 updated variant, 3 stock lines');

select tests.act_as_postgres();
select is(
  (select sl.quantity from public.stock_levels sl join public.product_variants v on v.id = sl.variant_id
   where v.sku = 'KPB-100' and sl.store_id = tests.id('store.pst')),
  10.000::numeric, 'stock columns set on-hand stock');
select is(
  (select count(*)::int from public.stock_movements m join public.product_variants v on v.id = m.variant_id
   where v.sku = 'KPB-100' and m.movement_type = 'opname' and m.reference_type = 'stock_opname'),
  1, 'imported stock is booked as an opname, so history explains it');
select is(
  (select sl.quantity from public.stock_levels sl
   where sl.variant_id = tests.variant('MNM-AIR-600') and sl.store_id = tests.id('store.bks')),
  20.000::numeric, 'counted stock replaces the old quantity in that store');
select is((select price from public.product_variants where sku = 'MNM-AIR-600'), 4100::bigint,
  'existing SKUs are updated');
select is(
  (select count(*)::int from public.store_variant_settings svs join public.product_variants v on v.id = svs.variant_id
   where v.sku = 'KPB-100' and svs.reorder_point = 3),
  3, 'the reorder point is set for every store');

-- Re-import -----------------------------------------------------------------------------------
select tests.act_as(tests.id('user.owner'));
insert into t_result values ('second', public.import_catalog(pg_temp.rows(4200, 'kpb-100')));
select is(
  (select array[(result ->> 'products_created')::int, (result ->> 'variants_created')::int,
                (result ->> 'variants_updated')::int] from t_result where name = 'second'),
  array[0, 0, 3], 're-importing (SKU in lower case) updates instead of duplicating');
select tests.act_as_postgres();
select is((select count(*)::int from public.products where name = 'Kopi Bubuk Uji'), 1,
  'still one product');

-- Bad rows roll everything back ------------------------------------------------------------------
select tests.act_as(tests.id('user.owner'));
select throws_like(
  $$select public.import_catalog(jsonb_build_array(
      jsonb_build_object('row', 2, 'product_name', 'Produk Gagal', 'variant_name', 'Default', 'sku', 'GAGAL-1',
        'category', 'Minuman', 'unit', 'pcs', 'price', 1000, 'cost', 500, 'taxable', true, 'track_stock', true),
      jsonb_build_object('row', 3, 'product_name', 'Produk Gagal 2', 'variant_name', 'Default', 'sku', 'GAGAL-2',
        'category', 'Minuman', 'unit', 'karung', 'price', 1000, 'cost', 500, 'taxable', true, 'track_stock', true)))$$,
  'import_invalid: row 3: unknown unit%', 'an unknown unit names the row');
select tests.act_as_postgres();
select is((select count(*)::int from public.product_variants where sku = 'GAGAL-1'), 0,
  'a failed import changes nothing (row 2 was rolled back too)');
select tests.act_as(tests.id('user.owner'));
select throws_like(
  $$select public.import_catalog(jsonb_build_array(
      jsonb_build_object('row', 2, 'product_name', 'Barcode Bentrok', 'variant_name', 'Default', 'sku', 'BENTROK-1',
        'barcode', (select barcode from public.product_variants where sku = 'MNM-AIR-1500'),
        'category', 'Minuman', 'unit', 'pcs', 'price', 1000, 'cost', 500, 'taxable', true, 'track_stock', false)))$$,
  'import_invalid: row 2: barcode % is already used by SKU MNM-AIR-1500', 'a barcode already in use is refused');

select tests.act_as(tests.id('user.manager_pst'));
select throws_like($$select public.import_catalog(pg_temp.rows())$$,
  'permission_denied%', 'managers cannot import the company catalog');

-- save_product -----------------------------------------------------------------------------------
select tests.act_as(tests.id('user.owner'));
create or replace function pg_temp.product(p_variants jsonb)
returns jsonb language sql as $$
  select jsonb_build_object('id', tests.uuid('120:product'), 'name', 'Teh Celup Uji',
    'unit_id', (select id from public.units where code = 'box'), 'category_id', (select id from public.categories where name = 'Minuman'),
    'variants', p_variants,
    'store_settings', jsonb_build_array(jsonb_build_object('store_id', tests.id('store.tgr'),
      'variant_id', tests.uuid('120:v1'), 'price_override', 9500, 'reorder_point', 4)))
$$;
select is(
  public.save_product(pg_temp.product(jsonb_build_array(
    jsonb_build_object('id', tests.uuid('120:v1'), 'name', 'Isi 25', 'sku', 'TCU-25', 'price', 9000, 'cost', 6000),
    jsonb_build_object('id', tests.uuid('120:v2'), 'name', 'Isi 50', 'sku', 'TCU-50', 'price', 17000, 'cost', 11500))))
    ->> 'variants',
  '2', 'save_product creates a product with two variants');
select lives_ok(
  $$select public.save_product(pg_temp.product(jsonb_build_array(
    jsonb_build_object('id', tests.uuid('120:v1'), 'name', 'Isi 25', 'sku', 'TCU-25', 'price', 9200, 'cost', 6000))))$$,
  'saving again with one variant');
select tests.act_as_postgres();
select ok(
  (select not is_active from public.product_variants where id = tests.uuid('120:v2'))
  and (select price = 9200 from public.product_variants where id = tests.uuid('120:v1'))
  and (select price_override = 9500 from public.store_variant_settings
       where variant_id = tests.uuid('120:v1') and store_id = tests.id('store.tgr')),
  'the removed variant is deactivated (not deleted); price and store override saved');
select tests.act_as(tests.id('user.owner'));
select throws_like(
  $$select public.save_product(pg_temp.product(jsonb_build_array(
    jsonb_build_object('id', tests.uuid('120:v1'), 'name', 'Isi 25', 'sku', 'MNM-AIR-600', 'price', 9000, 'cost', 6000))))$$,
  'duplicate_sku: MNM-AIR-600', 'a SKU used by another product is refused');

-- stock_overview and export ---------------------------------------------------------------------
select tests.act_as(tests.id('user.manager_pst'));
select ok(
  (select is_low from public.stock_overview(tests.id('store.pst')) where sku = 'FRZ-NGT-500'),
  'stock_overview flags low stock (nugget: 4 at PST, reorder point 10)');
select is((select count(*)::int from public.stock_overview(tests.id('store.bks'))), 0,
  'a PST manager sees no stock overview for BKS');
select tests.act_as(tests.id('user.owner'));
select is(
  (select array(select jsonb_object_keys(stock) order by 1) from public.catalog_export() where sku = 'MNM-AIR-600'),
  array['BKS', 'PST', 'TGR'], 'the export has stock per store for the owner');

select * from finish();
rollback;
