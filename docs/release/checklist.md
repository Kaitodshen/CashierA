# Release checklist

Phase 9 is done when this list is green. Tick each item for every release, and keep a dated copy with the release notes.

✅ = verified for this version on 2026-11-07 on the development PC. ⬜ = needs the production accounts, devices or people, so it can't be ticked from the repository.

## 1. Code is green (CI: `.github/workflows/ci.yml`)

- ✅ `dart format` makes no changes (core and app).
- ✅ `dart analyze` / `flutter analyze`: no issues.
- ✅ Core tests: 122 pass.
- ✅ App tests: 160 pass.
- ✅ Database: 22 pgTAP files, 434 assertions, all pass on PGlite.
- ✅ Edge Function logic: 15 Node tests pass (signature, status mapping, create, cancel race, webhook).
- ✅ `flutter build web --release` succeeds.
- ⬜ The CI workflow is green on GitHub for the release commit.
- ⬜ The pgTAP suite also passes on a **staging** Supabase project (PostgreSQL 17): `npx supabase@3.0.0 test db --remote`. Never run it on production.
- ⬜ The Edge Functions type-check under Deno: `deno check supabase/functions/*/index.ts`. Deno isn't installed on the development PC.

## 2. Production project ([deploy.md](deploy.md) §1–2)

- ⬜ Pro plan, Singapore region; daily backups visible under **Database → Backups**.
- ⬜ Migrations pushed, with no seed. Anonymous sign-ins on, with CAPTCHA.
- ⬜ Owner account, stores, staff and PINs created. The demo PINs from `seed.sql` don't exist in production.
- ⬜ The Midtrans **production** server key is set as a function secret, and `MIDTRANS_IS_PRODUCTION=true`.
- ⬜ All three functions are deployed; the webhook URL is set in the Midtrans dashboard.
- ⬜ Sandbox run done: QRIS paid, a QR left to expire, a QR cancelled, a duplicate webhook resent from the dashboard. Each matches Pembayaran QRIS.
- ⬜ No secret in the repository: `git grep -n "Mid-server-"` shows only the fake test key `SB-Mid-server-TEST`.

## 3. Builds ([deploy.md](deploy.md) §3–5)

- ⬜ `pubspec.yaml` version bumped (the build number always goes up).
- ⬜ `config/prod.json` points at production and has the anon key only.
- ⬜ Android: signed with the upload key, not the debug key (`keytool -printcert -jarfile app-release.apk` shows the company certificate). The AAB is uploaded to the internal testing track.
- ⬜ Windows: the installer installs, upgrades over the previous version keeping the pairing, and uninstalls cleanly.
- ⬜ Web: back office served over HTTPS, and sign-in works.

## 4. On real devices

- ⬜ Pair one Android tablet and one Windows PC to a store.
- ⬜ Cash sale: receipt printed, drawer opens, the sale reaches the server.
- ⬜ Dynamic QRIS sale with a real e-wallet (a small amount): paid within seconds, receipt shows QRIS, payment booked.
- ⬜ Offline: pull the network, sell cash and static QRIS, reconnect. The outbox empties and nothing is duplicated.
- ⬜ Shift close with a Z report; the X/Z on the terminal matches the back office.
- ⬜ F&B store (if any): kitchen and bar tickets print; the kitchen display updates.

## 5. Safety net ([backups.md](backups.md))

- ⬜ `tools/backup/backup.sh` is scheduled. Last night's dump exists in two places.
- ⬜ A restore drill was done this month; row counts were compared and the date written down.
- ⬜ Rollback plan: the previous APK/installer is kept. Migrations are additive, so an older app keeps working on the newer schema.

## 6. People

- ⬜ Store managers know the new screens (Pembayaran QRIS and its "Dibayar, tanpa penjualan" flag).
- ⬜ Who to call when the gateway is down: cashiers switch to the QRIS sticker (static) or cash.
