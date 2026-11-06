#!/usr/bin/env bash
# Nightly logical backup of the CashierA database (docs/release/backups.md).
#
#   SUPABASE_DB_URL='postgresql://postgres.<ref>:<password>@aws-0-<region>.pooler.supabase.com:5432/postgres' \
#   BACKUP_DIR=/srv/cashiera-backups KEEP_DAYS=30 tools/backup/backup.sh
#
# Writes <BACKUP_DIR>/cashiera-YYYYmmdd-HHMMSS.dump (pg_dump custom format,
# public + app schemas and auth.users, i.e. everything CashierA owns) and a
# .sha256 next to it, then deletes dumps older than KEEP_DAYS. Use the session
# pooler or direct connection (port 5432), not the transaction pooler.
# pg_dump must be the same major version as the server (17) or newer.
set -euo pipefail

: "${SUPABASE_DB_URL:?set SUPABASE_DB_URL (keep it out of shell history)}"
BACKUP_DIR="${BACKUP_DIR:-./backups}"
KEEP_DAYS="${KEEP_DAYS:-30}"

mkdir -p "$BACKUP_DIR"
stamp="$(date -u +%Y%m%d-%H%M%S)"
file="$BACKUP_DIR/cashiera-$stamp.dump"

pg_dump "$SUPABASE_DB_URL" \
  --format=custom --compress=9 --no-owner --no-privileges \
  --schema=public --schema=app --table=auth.users --table=auth.identities \
  --file="$file.partial"
mv "$file.partial" "$file"

if command -v sha256sum >/dev/null; then
  (cd "$BACKUP_DIR" && sha256sum "$(basename "$file")" > "$(basename "$file").sha256")
fi

# Quick self-check: the archive lists the tables CashierA cannot live without.
for t in orders payments stock_levels audit_log gateway_charges; do
  pg_restore --list "$file" | grep -q " TABLE DATA public $t " \
    || { echo "backup check failed: no data for $t" >&2; exit 1; }
done

find "$BACKUP_DIR" -name 'cashiera-*.dump*' -type f -mtime +"$KEEP_DAYS" -delete
echo "backup ok: $file ($(du -h "$file" | cut -f1))"
