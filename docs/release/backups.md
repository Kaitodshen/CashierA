# Backups and restore

CashierA keeps two kinds of backup. Neither replaces the other.

| Layer | What | Where | Who |
|---|---|---|---|
| Supabase daily backups (Pro plan) | Whole database, last 7 days. Point-in-time recovery is an optional add-on | Supabase | Automatic. Check them under **Database → Backups** |
| Nightly `pg_dump` | CashierA's schemas (`public`, `app`) and the sign-in users, kept for 30 days | Your own storage, outside Supabase | `tools/backup/backup.sh` on a schedule |

The nightly dump covers the case Supabase backups can't: losing the project or the account itself.

## Nightly dump

Requirements:

- A machine that is always on (office server, VPS or NAS).
- `pg_dump` 17 or newer (`apt install postgresql-client-17`).
- The **session pooler** connection string, from **Project Settings → Database → Connection string → Session pooler**, port 5432.

```bash
export SUPABASE_DB_URL='postgresql://postgres.<ref>:<db password>@aws-0-ap-southeast-1.pooler.supabase.com:5432/postgres'
BACKUP_DIR=/srv/cashiera-backups KEEP_DAYS=30 tools/backup/backup.sh
```

Keep the connection string in a file only the backup user can read, such as `/etc/cashiera-backup.env` with mode 600, never in the crontab line. Example crontab (02:00 WIB, after closing time):

```cron
0 2 * * * . /etc/cashiera-backup.env && cd /opt/cashiera && tools/backup/backup.sh >> /var/log/cashiera-backup.log 2>&1
```

The script does three things:

1. It writes `cashiera-YYYYmmdd-HHMMSS.dump` with a `.sha256` file next to it.
2. It checks that the archive contains orders, payments, stock, the audit log and the QRIS charges, and exits non-zero if it doesn't.
3. It deletes dumps older than `KEEP_DAYS`.

Copy the folder to a second place, for example with `rclone sync` to an encrypted bucket. A backup kept on one machine only is not a backup.

## Restore drill (monthly)

A backup you have never restored is a hope, not a backup.

```bash
npx supabase@3.0.0 start    # empty local stack (needs Docker), used as the scratch target
RESTORE_DB_URL='postgresql://postgres:postgres@localhost:54322/postgres' \
  tools/backup/restore-drill.sh /srv/cashiera-backups/cashiera-<stamp>.dump
```

- The drill refuses to run against a hosted Supabase address.
- It checks the checksum, restores the dump, and prints the row counts and the latest order.
- Compare those with the back office (**Laporan** for yesterday) and write down the date of the drill.

## Real restore (disaster)

1. Stop the terminals' sync by revoking their sessions, or simply wait. Terminals keep selling offline and queue everything in their outbox.
2. Restore:
   - Into the same project: use **Database → Backups → Restore** in the Supabase dashboard.
   - Into a new project: run `supabase db push`, then `pg_restore --data-only` from the nightly dump.
3. Point the apps at the new project if it changed. That means a new build with the new `config/prod.json`.
4. Let the terminals sync. The outbox is idempotent (`sync_push` keys every item on its client UUID), so sales made during the outage arrive once and in order.
5. Check:
   - Pembayaran QRIS, for paid charges without a sale.
   - The audit log.
   - A Z report for each open shift.
