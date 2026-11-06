-- Structural guarantees: RLS everywhere, integer money, exact quantities,
-- the Realtime allow-list, no anon access, safe security-definer functions.
begin;
create extension if not exists pgtap with schema extensions;
select plan(9);

select ok(
  not exists (select 1 from pg_tables where schemaname = 'public' and not rowsecurity),
  'every public table has row level security enabled');

select is(
  (select count(*)::int from information_schema.columns
   where table_schema = 'public' and data_type in ('real', 'double precision', 'money')),
  0,
  'no floating point or money-type columns');

select is(
  (select coalesce(string_agg(table_name || '.' || column_name, ', ' order by table_name, column_name), '')
   from information_schema.columns
   where table_schema = 'public'
     and column_name ~ '(amount|total|price|cost|cash|discount|change)'
     and column_name !~ '(bps|_id$|quantity|qty|count|redeemed|points|_at$|reason|note|type|drawer)'
     and data_type <> 'bigint'),
  '',
  'every money column is bigint rupiah');

select is(
  (select coalesce(string_agg(table_name || '.' || column_name, ', ' order by table_name, column_name), '')
   from information_schema.columns
   where table_schema = 'public'
     and (column_name ~ 'quantity' or column_name ~ '_qty$' or column_name = 'reorder_point')
     and not (data_type = 'numeric' and numeric_precision = 14 and numeric_scale = 3)),
  '',
  'every quantity is numeric(14,3)');

select is(
  (select array_agg(tablename::text order by tablename)
   from pg_publication_tables
   where pubname = 'supabase_realtime' and schemaname = 'public'),
  array['dining_tables', 'order_status', 'orders', 'shifts', 'stock_levels'],
  'Realtime publishes only the five live tables');

select is(
  (select count(*)::int from information_schema.role_table_grants
   where grantee = 'anon' and table_schema = 'public'),
  0,
  'the anon role has no privileges on public tables');

select is(
  (select count(*)::int from public.store_payment_methods),
  (select (count(*) * 7)::int from public.stores),
  'every store accepts the seven default payment methods');

select ok(
  exists (select 1 from pg_indexes where schemaname = 'public' and indexname = 'orders_store_created_idx')
  and exists (select 1 from pg_indexes where schemaname = 'public' and indexname = 'order_items_store_sku_idx'),
  'composite (store_id, created_at) and (store_id, sku) indexes exist');

select is(
  (select count(*)::int
   from pg_proc p
   join pg_namespace n on n.oid = p.pronamespace
   where n.nspname in ('public', 'app') and p.prosecdef
     and not exists (select 1 from unnest(coalesce(p.proconfig, '{}'::text[])) c where c like 'search_path=%')),
  0,
  'every security definer function pins its search_path');

select * from finish();
rollback;
