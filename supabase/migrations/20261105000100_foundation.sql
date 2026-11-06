-- =============================================================================
-- CashierA · 0100 · Foundation
-- Extensions, the private `app` schema and shared helpers.
--
-- Conventions used by every migration:
--   * money      -> bigint rupiah (never float / numeric)
--   * rates      -> integer basis points (1100 = 11.00%)
--   * quantities -> numeric(14,3)  (Dart/Drift keep integer thousandths)
--   * ids        -> uuid; transactional rows use client-generated ids (UUIDv7)
--   * times      -> timestamptz; per-store business_date in the store timezone
-- =============================================================================

create extension if not exists pgcrypto with schema extensions;

create schema if not exists app;
comment on schema app is
  'CashierA private helpers. Not exposed through the Data API; used by RLS policies, triggers and RPCs.';
revoke all on schema app from public;
grant usage on schema app to authenticated, service_role;

-- Maintains updated_at on every table that has one (attached in 0900).
create or replace function app.touch_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- Raise a business-rule error. Clients treat SQLSTATE P0001 as permanent
-- (no automatic retry). Message format: '<code>: <detail>'.
create or replace function app.fail(p_code text, p_detail text default null)
returns void
language plpgsql
set search_path = ''
as $$
begin
  raise exception using
    errcode = 'P0001',
    message = p_code || coalesce(': ' || p_detail, ''),
    hint = p_code;
end;
$$;

-- jsonb number that is a positive integer (used by rule validators).
create or replace function app.is_positive_int(p jsonb)
returns boolean
language sql
immutable
set search_path = ''
as $$
  select coalesce(
    jsonb_typeof(p) = 'number'
      and (p #>> '{}') ~ '^[0-9]+$'
      and (p #>> '{}')::numeric > 0,
    false)
$$;
