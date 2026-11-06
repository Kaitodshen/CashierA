# Deploying CashierA

How to put CashierA into production: the Supabase project, the Midtrans gateway, the Android and Windows terminals, and the web back office. Work through [checklist.md](checklist.md) as you go.

## 1. Supabase project

1. Create a project on the **Pro plan** (the Free plan pauses idle projects and has no backups; risk R7 in the architecture). Pick the Singapore region (`ap-southeast-1`), the closest to Indonesia.
2. Turn on **Authentication → Sign In / Providers → Allow anonymous sign-ins**, which terminals need to pair. Turn on CAPTCHA (Cloudflare Turnstile) as well.
3. Link the project and push the schema from the repository root. CLI 3.0 targets the local database unless you pass `--remote`:

   ```bash
   npx supabase@3.0.0 login
   npx supabase@3.0.0 link --project-ref <project-ref>
   npx supabase@3.0.0 db push --remote
   ```

   This applies `supabase/migrations/*` in order. Never add `--include-seed` in production: the seed holds demo stores, staff and PINs.
4. Create the owner account and the real stores. See `supabase/README.md`, section 2.
5. Under **Authentication → URL configuration**, set the site URL to the back-office address (section 5).

## 2. Midtrans (dynamic QRIS)

1. In the Midtrans dashboard (**Sandbox** first, then **Production**), copy the **Server Key** from **Settings → Access Keys**.
2. Store it as a function secret. It must never go into the app or the repository:

   ```bash
   npx supabase@3.0.0 secrets set MIDTRANS_SERVER_KEY=<server key> MIDTRANS_IS_PRODUCTION=false QRIS_EXPIRY_MINUTES=15
   ```

3. Deploy the functions:

   ```bash
   npx supabase@3.0.0 functions deploy qris-create
   npx supabase@3.0.0 functions deploy qris-cancel
   npx supabase@3.0.0 functions deploy midtrans-webhook --no-verify-jwt
   ```

   `config.toml` already turns off the JWT check for the webhook only. Midtrans can't send a Supabase JWT; its requests are trusted by their `signature_key`.
4. In the Midtrans dashboard, under **Settings → Payment → Notification URL**, set `https://<project-ref>.supabase.co/functions/v1/midtrans-webhook`.
5. Test in sandbox:
   - Make a QRIS sale on a terminal, and pay it with the Midtrans QRIS simulator.
   - The terminal should mark it paid within seconds.
   - **Back office → Pembayaran QRIS** should show it as paid and booked.
6. Go live: set `MIDTRANS_IS_PRODUCTION=true` and the production server key, then redeploy all three functions.

How it works:

- The terminal asks `qris-create` for a QR.
- The function opens a row in `gateway_charges`, using the terminal's own token, so the store is checked. It then calls Midtrans and stores the QR.
- Midtrans calls the webhook when the customer pays. The function checks the signature, asks Midtrans for the status, and settles the charge.
- When the sale syncs, the database accepts the QRIS payment only if that charge is paid for the same amount.

A paid QR whose bill was never finished shows as **Dibayar, tanpa penjualan** in Pembayaran QRIS. Finish the bill on the terminal, or refund the payment from the Midtrans dashboard.

## 3. Build configuration

Copy `app/config/prod.example.json` to `app/config/prod.json` (git-ignored) and fill it in:

- the project URL
- the **publishable (anon) key** (never the service role key)
- `PAYMENT_GATEWAY`: `midtrans`, or leave it empty to hide dynamic QRIS

Every build below reads this file.

Bump `version:` in `app/pubspec.yaml` for each release. The part after `+` is the Android version code and must always go up.

## 4. Terminals

### Android (tablets)

1. Create the upload keystore once:

   ```bash
   keytool -genkey -v -keystore C:\keys\cashiera-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

   Keep the file and its passwords in the company password manager. If you lose them, you can't update the Play Store app any more.
2. Copy `app/android/key.properties.example` to `app/android/key.properties` and fill it in. Without that file, the release is signed with the debug key and must not be shipped.
3. Build:

   ```bash
   cd app
   flutter build appbundle --release --dart-define-from-file=config/prod.json
   flutter build apk --release --dart-define-from-file=config/prod.json
   ```

   - For Google Play (internal testing track first), upload `build/app/outputs/bundle/release/app-release.aab`.
   - For direct installs (sideloading), use `build/app/outputs/flutter-apk/app-release.apk`. Turn off "install unknown apps" again afterwards.

### Windows (PC cashiers)

1. Install [Inno Setup 6](https://jrsoftware.org/isinfo.php) on the build machine.
2. Build and package from the repository root:

   ```bash
   cd app && flutter build windows --release --dart-define-from-file=config/prod.json && cd ..
   iscc /DAppVersion=0.2.0 app\windows\installer\cashiera.iss
   ```

   The installer is `app/build/installer/CashierA-Setup-<version>.exe`. Upgrading keeps the local database, the pairing and the printers, because they live in the user's AppData folder.
3. Sign the installer with the company code-signing certificate if you have one. Otherwise SmartScreen warns on the first install.

## 5. Web back office

```bash
cd app
flutter build web --release --dart-define-from-file=config/prod.json
```

Upload `app/build/web/` to any static host, such as Cloudflare Pages, Netlify, Firebase Hosting or Vercel:

- The app uses hash URLs (`/#/admin/...`), so the host needs no rewrite rules.
- Serve over HTTPS only.
- Cache `main.dart.js` and `flutter_bootstrap.js` for a short time, or not at all, so a release reaches browsers straight away.

Add the host's address to the Supabase site URL and redirect URLs (section 1, step 5).

## 6. After each release

- Check the version on one Android and one Windows terminal: `devices.app_version` in the database, which is recorded when a terminal pairs.
- Do a cash sale and a QRIS sale, and check they sync.
- Check that last night's backup exists ([backups.md](backups.md)).
