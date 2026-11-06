#!/usr/bin/env bash
# Restore drill: load a dump into an EMPTY scratch database and compare row
# counts with what the dump says. Never point RESTORE_DB_URL at production.
#
#   RESTORE_DB_URL='postgresql://postgres:postgres@localhost:54322/postgres' \
#   tools/backup/restore-drill.sh backups/cashiera-20261107-020000.dump
#
# A fresh `supabase start` (local stack) is a good scratch target: it has the
# auth schema and roles the dump expects.
set -euo pipefail

dump="${1:?usage: restore-drill.sh <file.dump>}"
: "${RESTORE_DB_URL:?set RESTORE_DB_URL to a scratch database}"
case "$RESTORE_DB_URL" in
  *supabase.co*|*pooler.supabase.com*)
    echo "refusing: RESTORE_DB_URL looks like a hosted Supabase project" >&2; exit 2;;
esac

if [ -f "$dump.sha256" ]; then
  (cd "$(dirname "$dump")" && sha256sum -c "$(basename "$dump").sha256")
fi

pg_restore --dbname="$RESTORE_DB_URL" --no-owner --no-privileges --clean --if-exists "$dump"

psql "$RESTORE_DB_URL" -v ON_ERROR_STOP=1 -At <<'SQL'
select 'stores',          count(*) from public.stores
union all select 'orders',          count(*) from public.orders
union all select 'payments',        count(*) from public.payments
union all select 'stock_levels',    count(*) from public.stock_levels
union all select 'audit_log',       count(*) from public.audit_log
union all select 'gateway_charges', count(*) from public.gateway_charges;
select 'latest order', max(created_at) from public.orders;
SQL
echo "restore drill finished: compare the counts with the production dashboard"
