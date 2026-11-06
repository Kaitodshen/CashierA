# Phase 9: Dynamic QRIS (Midtrans), Release and Backups Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cashiers take dynamic QRIS through Midtrans with the server key only in Edge Functions, a sale can't claim a gateway payment the gateway never confirmed, and the app has release builds, a backup routine and a release checklist.

**Architecture:**
- **Edge Functions** do the gateway work: `qris-create`, `qris-cancel` and `midtrans-webhook`. Their logic lives in plain TypeScript modules (`supabase/functions/_shared`) with injected dependencies, so Node 24 can test them without Deno.
- **The database** keeps every charge in `gateway_charges`. A trigger on `payments` refuses a gateway payment unless its charge is `paid` for the same amount and store.
- **The terminal** goes through a `PaymentGateway` interface:
  - `SupabaseGateway` calls the functions and watches the charge (polling and Realtime).
  - `MockGateway` is for development and tests.

**Tech Stack:** Supabase Edge Functions (Deno), Midtrans Core API (QRIS), PL/pgSQL + pgTAP on PGlite, Flutter/Riverpod, `barcode` (QR drawing, already in the lock file), Node 24 `node --test`.

**Spec:** `docs/phase-0-architecture.md` (A5, payments section, R7, Phase 9 row: "The release checklist is green").

## Global Constraints

- Money is integer rupiah; Midtrans `gross_amount` is a whole number of rupiah.
- The Midtrans server key exists only as the Edge Function secret `MIDTRANS_SERVER_KEY`, never in the app or the repository.
- `MIDTRANS_IS_PRODUCTION=true` selects `https://api.midtrans.com`; otherwise `https://api.sandbox.midtrans.com`.
- Webhook signature: `sha512(order_id + status_code + gross_amount + server_key)` as lowercase hex.
- Gateway status mapping:
  - `settlement` / `capture` → `paid`
  - `pending` → `pending`
  - `expire` → `expired`
  - `cancel` → `cancelled`
  - `deny` / `failure` → `failed`
- A `paid` charge is final.
- Dynamic QRIS needs the network. Cash, static QRIS, card and transfer still work offline.
- The app picks the gateway with `--dart-define=PAYMENT_GATEWAY=midtrans|mock`. With none set, gateway methods are hidden.
- No secrets in the repository: `key.properties`, keystores and `.env` files are git-ignored.

## Review Focus

- A forged or replayed webhook (bad signature, wrong amount) must not mark a charge paid. Test: webhook handler tests and pgTAP.
- A terminal sends `order.upsert` with a gateway payment whose charge is pending or for another amount → refused with `gateway_unconfirmed`. Test: pgTAP 200.
- Duplicate webhooks, or `paid` followed by a late `expire`, keep the charge paid. Test: pgTAP 200 and the handler test.
- The cashier cancels while the customer has just paid: the cancel answers "already paid", and the payment is used. Test: `qris_flow_test.dart`.
- The QR expires: the payment screen says so and offers a new QR. Nothing is booked. Test: `qris_flow_test.dart`.

---

### Task 1: Database (`2100_payment_gateway.sql`, pgTAP `200_payment_gateway.test.sql`)
- `payment_methods.gateway` (`midtrans` or null), plus a seeded method `qris_dynamic` ("QRIS Dinamis", qris, midtrans, sort 21).
- `gateway_charges`:
  - columns: id = payment id, store, device, order id and number, amount, provider, provider_ref, qr_string, expires_at, status, paid_at, raw
  - RLS: read for the store's `pos.sell` / `reports.view`; no client writes
  - on the Realtime publication
- RPCs:
  - `gateway_charge_open(p)` (terminal, write scope; idempotent on id)
  - `gateway_charge_attach(id, provider_ref, qr, expires_at, raw)` (service_role)
  - `gateway_charge_settle(id, status, gross_amount, transaction_id, raw)` (service_role; refuses an amount mismatch; `paid` is final)
  - `gateway_charge_status(id)` (store members)
  - `gateway_charge_list(store_id, from, to)` (`reports.view`; flags paid charges with no sale as `unmatched`)
- A trigger on `payments` refuses a payment through a gateway method, or with a provider, unless the charge with that id is `paid` with the same amount and store (`gateway_unconfirmed`).

### Task 2: Edge Functions (`supabase/functions`)
- `_shared/midtrans.ts`: `signatureKey`, `verifyNotification`, `mapStatus`, `chargeRequest`, `parseCharge`, `baseUrl`.
- `_shared/handlers.ts`: `createQris(req, deps)`, `cancelQris(req, deps)`, `handleNotification(body, deps)`.
- Thin `index.ts` per function. `config.toml` turns off JWT checks for the webhook only.
- Tests: `supabase/functions/tests/*.test.ts` run with `node --test`, using fake fetch and fake database calls.

### Task 3: Terminal
- `core/payments/payment_gateway.dart`: `PaymentGateway { createQris, watch, cancel }`, `QrisCharge`, `ChargeState`, `MockGateway`, `SupabaseGateway`.
- `PaymentOption.gateway`.
- `Tender` and the payload gain `provider` / `providerRef`.
- Payment screen, for a gateway method:
  - **Buat QR** opens the QR dialog: QR drawn with `barcode`, amount, countdown, status.
  - When paid, the tender is added as paid. Expiry offers a new QR.
  - **Batalkan** cancels; an "already paid" answer is used as paid.
- Back office **Pembayaran QRIS**: charges per store and period, with unmatched ones flagged.

### Task 4: Release, backups, checklist
- Android: release signing from `android/key.properties`, with an example file and git-ignore entries.
- Windows: an Inno Setup script.
- Web: hosting notes with the SPA fallback.
- `tools/backup`: a `pg_dump` script with retention, plus a restore drill.
- `.github/workflows/ci.yml`: format, analyze, all tests, web build.
- `docs/release/checklist.md`.

### Task 5: Verify
- Format and the analyzers are clean.
- Core, app, database and functions tests pass.
- `flutter build web` succeeds.
- Docs are updated, with "As built" notes.

## As built (deviations)

- **Paid gateway tenders live on the cart** (`Cart.gatewayTenders`, saved with held bills), not just on the payment screen. Money that arrived can't vanish when the cashier navigates away. A bill holding one can't be cleared.
- **The webhook trusts Midtrans, not the body.** After the signature check it reads `GET /v2/{id}/status` and settles with that. Unknown charges and amount mismatches answer 200, so Midtrans stops retrying; both are logged.
- **Cancel asks Midtrans what happened.** `qris-cancel` cancels and then reads the status: "paid a second ago" becomes paid. The terminal also cancels a QR that expired only by its own clock before making a new one.
- **The QR is drawn with `barcode`**, which was already in the lock file (through `pdf`). It is now a direct dependency; nothing new was downloaded.
- **A determinate countdown bar replaces an indeterminate spinner**, so the dialog is testable. Two real bugs were fixed while testing:
  - A double close, when a paid update and a cancel answer both arrived.
  - A hang, when cancelling the old status stream before a new QR.
- **The seed enables QRIS Dinamis in every store** (8 methods). Terminals still hide it unless `PAYMENT_GATEWAY` is set. `001_schema` was updated on purpose: the method count, and `gateway_charges` on Realtime.
- **Not verified here:**
  - Deno type-checking of the three `index.ts` files (no Deno installed).
  - A real Midtrans sandbox call.
  - Signed Android and Windows builds (no keystore or Inno Setup on this PC).
  - GitHub CI, which first runs on push.
  The checklist marks these ⬜.
- **Refunds of a dynamic QRIS sale** follow the existing refund rules (refund to a method the customer paid with). The money goes back through the Midtrans dashboard; there is no API refund.
- **Verified on 2026-11-07:**
  - Format and analyzers clean.
  - Tests pass: core 122, app 160 (4 new in `qris_flow_test.dart`), database 22 files / 434 assertions (new `200_payment_gateway`), functions 15.
  - `flutter build web` succeeds.
