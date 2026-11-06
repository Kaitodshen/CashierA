-- =============================================================================
-- CashierA · 1300 · Grants, Realtime publication, Storage buckets
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Table privileges. RLS decides rows; grants decide what is even possible.
-- The anon role (not signed in) gets nothing.
-- ---------------------------------------------------------------------------
revoke all on all tables in schema public from anon;
revoke all on all sequences in schema public from anon;

grant select, insert, update, delete on all tables in schema public to authenticated;
grant usage, select on all sequences in schema public to authenticated;
grant all on all tables in schema public to service_role;
grant all on all sequences in schema public to service_role;

-- Ledger-maintained columns are not writable by clients.
revoke insert, update on public.customers from authenticated;
grant insert (id, name, phone, email, birth_date, address, notes, kasbon_limit, created_store_id, is_active)
  on public.customers to authenticated;
grant update (name, phone, email, birth_date, address, notes, kasbon_limit, is_active)
  on public.customers to authenticated;

revoke insert, update on public.vouchers from authenticated;
grant insert (id, code, description, discount_type, discount_value, max_discount, min_subtotal,
              max_uses, per_customer_limit, starts_at, ends_at, is_active)
  on public.vouchers to authenticated;
grant update (code, description, discount_type, discount_value, max_discount, min_subtotal,
              max_uses, per_customer_limit, starts_at, ends_at, is_active)
  on public.vouchers to authenticated;

-- Functions: RPCs are for signed-in users only; helpers are internal.
revoke execute on all functions in schema public from public, anon;
grant execute on all functions in schema public to authenticated, service_role;
revoke execute on all functions in schema app from public;
grant execute on all functions in schema app to authenticated, service_role;

-- Future objects created by migrations follow the same rules.
alter default privileges in schema public revoke execute on functions from public;
alter default privileges in schema app revoke execute on functions from public;

-- ---------------------------------------------------------------------------
-- Realtime: only the live store tables. RLS also applies to subscriptions.
-- ---------------------------------------------------------------------------
alter publication supabase_realtime
  add table public.orders, public.order_status, public.stock_levels, public.dining_tables, public.shifts;

-- ---------------------------------------------------------------------------
-- Storage
--   product-images      public read, catalog managers write
--   business-assets     public read (logo), owners write
--   expense-attachments private; path = <store_id>/<expense_id>/<file>
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types) values
  ('product-images',      'product-images',      true,  5242880,  array['image/png', 'image/jpeg', 'image/webp']),
  ('business-assets',     'business-assets',     true,  2097152,  array['image/png', 'image/jpeg', 'image/webp', 'image/svg+xml']),
  ('expense-attachments', 'expense-attachments', false, 10485760, array['image/png', 'image/jpeg', 'image/webp', 'application/pdf'])
on conflict (id) do nothing;

create policy "cashiera members read public images" on storage.objects
  for select to authenticated
  using (bucket_id in ('product-images', 'business-assets') and (select app.is_member()));

create policy "cashiera catalog managers upload product images" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'product-images' and (select app.has_permission('catalog.manage')));
create policy "cashiera catalog managers update product images" on storage.objects
  for update to authenticated
  using (bucket_id = 'product-images' and (select app.has_permission('catalog.manage')))
  with check (bucket_id = 'product-images' and (select app.has_permission('catalog.manage')));
create policy "cashiera catalog managers delete product images" on storage.objects
  for delete to authenticated
  using (bucket_id = 'product-images' and (select app.has_permission('catalog.manage')));

create policy "cashiera owners upload business assets" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'business-assets' and (select app.is_owner()));
create policy "cashiera owners update business assets" on storage.objects
  for update to authenticated
  using (bucket_id = 'business-assets' and (select app.is_owner()))
  with check (bucket_id = 'business-assets' and (select app.is_owner()));
create policy "cashiera owners delete business assets" on storage.objects
  for delete to authenticated
  using (bucket_id = 'business-assets' and (select app.is_owner()));

create policy "cashiera read expense attachments of my stores" on storage.objects
  for select to authenticated
  using (bucket_id = 'expense-attachments'
         and (storage.foldername(name))[1] = any (
           select unnest((select app.store_ids_with(array['expense.manage', 'reports.view'], false)))::text));
create policy "cashiera upload expense attachments to my stores" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'expense-attachments'
              and (storage.foldername(name))[1] = any (
                select unnest((select app.store_ids_with(array['expense.manage'], false)))::text));
create policy "cashiera delete expense attachments of my stores" on storage.objects
  for delete to authenticated
  using (bucket_id = 'expense-attachments'
         and (storage.foldername(name))[1] = any (
           select unnest((select app.store_ids_with(array['expense.manage'], false)))::text));
