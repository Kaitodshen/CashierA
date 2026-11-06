# Progress

Read-only audit of the repository at commit `a7ab472` (the only commit). Uncommitted: this file, `supabase/tests/database/150_cross_store_isolation.test.sql`, and a stray `app/android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant - Copy.java`. No `CLAUDE.md` exists in the repository.

## 1. Status by phase

| Phase | Status | Evidence |
|---|---|---|
| 0 · Architecture | Done | `docs/phase-0-architecture.md` |
| 1 · Database (schema, RLS, sync RPCs, tests) | Done (local only) | `supabase/migrations/…0100` to `…1300`; pgTAP `000`–`110` pass on PGlite. Not run on a real Supabase stack |
| 2 · Flutter core (theme, routing, Drift, pairing, PIN, sync) | Done | `app/lib/core/sync/sync_engine.dart`, `features/pairing`, `features/pin_login`; plan `2026-11-05-phase-2-flutter-core.md` |
| 3 · Catalog, inventory, import/export | Done | `…1400_catalog_rpc.sql`, `features/back_office/presentation/import_screen.dart`, `features/catalog` |
| 4 · Cashier, pricing, payments, receipts | Done | `packages/cashiera_core/lib/src/pricing/`, `…1500_pos.sql`, `features/sell` |
| 5 · Shifts, X/Z, PIN approvals, audit log, printing | Done (local only) | `…1600_shift_audit.sql`, `…1800_review_fixes.sql`, `features/shift`, `core/printing`. Review findings fixed (pgTAP `170`). Never run on a real printer or device |
| 6 · Customers, loyalty, kasbon ledger | Done (local only) | `…1700_loyalty_kasbon.sql` (pgTAP `160`), `core/pos/kasbon_service.dart`, `features/customers`, back office customers / kasbon / loyalty; plan `2026-11-07-phase-6-customers-loyalty-kasbon.md`. Not run on devices or live Supabase |
| 7 · Dashboard and reports | Not started (next) | No report RPCs besides `shift_summary`, `shift_overview`, `kasbon_overview`; no dashboard screen |
| 8 · F&B, KDS, transfers, purchase orders | Partial | Server only: `dining_tables`, `order_status`, `stock_transfers`, `purchase_orders`, `goods_receipts`, `request_stock_transfer`, `transition_stock_transfer` (pgTAP `070`, `100`). No app screens |
| 9 · Payment gateway, deploy, backups | Not started | No `supabase/functions`, no `PaymentGateway` in the app, no release setup |

## 2. Done

- **Database:**
  - 64 tables and 189 triggers.
  - Stock changes through one function, `app.apply_stock_delta`.
  - Order totals are re-checked on the server (`app.validate_order_totals`).
  - The audit log is append-only.
  - Sync goes through `sync_push`, with an inbox keyed on the client UUID.
  - 17 pgTAP files, 326 assertions, all passing (last run 2026-11-06).
- **Pricing core (`packages/cashiera_core`):**
  - Money is integer rupiah; quantities are integer thousandths.
  - Promo engine, bill calculation, settlement, shift report, refund allocation, ESC/POS encoder.
  - 111 tests pass.
- **Terminal app:**
  - Pairing, offline PIN login with lockout, and an outbox with FIFO order and retry/backoff.
  - Catalog mirror, offline stock in/out and stock count (opname).
  - Cashier screen: promos, discounts with approval, vouchers, hold/resume, split payments, kasbon, receipts.
- **Phase 5 on the terminal:**
  - Open and close the shift, with the cash count and the difference.
  - Live X report and Z report.
  - Cash in/out, with a cash out capped at the expected drawer cash.
  - Void (approval after printing), refund (always approved), drawer open without a sale (approved and audited).
  - Printer setup: BLE, USB or network (TCP 9100).
  - Auto-print and drawer kick.
  - Reprints marked as copies and audited.
- **Back office (web):**
  - Products, categories, suppliers, stock, import/export.
  - Promotions, vouchers, store settings, payment methods.
  - Shift list with X/Z report and PDF, and an audit log with filters and paging.
- **Checks today:**
  - `flutter analyze`: no issues.
  - `flutter test`: 137 passed, 0 failed (2026-11-07, after Phase 6 and the review fixes).
  - `flutter build web --release` succeeded earlier on 2026-11-06.

## 3. In progress (half-built), Phase 5

No `TODO`, `FIXME` or `UnimplementedError` found in `app/lib`, `packages/cashiera_core/lib` or `supabase/migrations`. The four review findings (approvals, expected cash, drawer on cash in/out, PDF sharing) were fixed on 2026-11-07 (migration 1800, pgTAP `170`). Remaining limits:

| Area | File | What is missing |
|---|---|---|
| Printing | `app/lib/core/printing/transport_io.dart` | Bluetooth Classic (SPP) is not supported, only BLE. No logo printing. Never tested on real printers |
| Refunds | `app/lib/core/pos/refund_service.dart` | Only for orders sold on the same terminal |
| Printers table | `public.printers` (`20261105000600_sales.sql`) | Unused; printer setup is local to the terminal (`local_printers`) |
| Tests | `supabase/tests/database/150`–`170` | Written and passing, not committed |

## 4. Known problems

- Analyzer errors: none. Failing tests: none (app 137, core 122, database 19 files / 356 assertions, 2026-11-07).
- TODO/FIXME comments: none found.
- Stray `GeneratedPluginRegistrant - Copy.java` in `app/android/app/src/main/java/io/flutter/plugins/`. A second public class with the same name would likely break the Android build. It is not committed.
- Never run against a live Supabase project. Local tests run on PostgreSQL 18 (PGlite); hosted Supabase runs 17.
- Never built or run on Android, Windows or iOS hardware. This PC has no Android SDK or Visual Studio.
- `app/lib/core/sync/sync_engine.dart`: a `not_a_member` reply marks each queued item as failed instead of pausing the outbox. If the terminal loses its pairing, every queued sale fails and has to be retried by hand.
- PIN hashes (bcrypt cost 10, 4–6 digits) are sent to the store's terminals (`device_staff`). Short PINs can be brute-forced from a stolen terminal.
- Missing tests:
  - No automated test of the real transports (`transport_io.dart`: TCP and the plugin); widget tests use a fake printer.
  - No integration test on a device.
  - No test runs the migrations on PostgreSQL 17.

## 5. Risk checklist (observations only)

- **RLS on every table?** Yes, all 64 public tables have it switched on (loop in `20261105001200_rls.sql`, line 23).
  - Tables with no policy: `device_pairing_codes`, `employee_pins` and `sync_inbox`. That means no client access at all; they are used only by `SECURITY DEFINER` functions.
  - Money tables (orders, payments, shifts, refunds, cash movements, kasbon) have read policies only. Writes go through RPCs.
  - Store isolation is checked by `010_rls_store_isolation.test.sql` and `150_cross_store_isolation.test.sql`.
- **Money stored or calculated as a float?** No.
  - Every money column is `bigint`. The `numeric` columns are quantities (`numeric(14,3)`).
  - Dart uses the integer types `Money` and `Qty` (`packages/cashiera_core/lib/src/money.dart`, `qty.dart`); no `double` in money code.
- **Stock deduction in a transaction with locking?** Yes.
  - `app.lock_stock_rows` locks rows in variant-id order (`20261105001000_business_logic.sql`, line 93). `app.deduct_order_stock` runs inside the order-completion trigger. Refunds, adjustments and voids lock before changing stock.
  - Stock may go negative by design: this raises a `STOCK_DISCREPANCY` alert and flags the order for review (`030_stock_conflict.test.sql`).
- **Client-generated UUIDs for sync?** Yes.
  - The sync request itself carries a client UUID (`sync_push`), stored in the `sync_inbox` primary key.
  - The synced tables (orders, items, payments, discounts, shifts, cash movements, refunds, refund items, kasbon payments, stock adjustments) have no server default for `id`. Terminals send UUIDv7 ids.
  - Customers and audit entries accept a client id but also have a server default.
- **Can a sensitive action skip the manager PIN?**

  | Action | Answer | Reference |
  |---|---|---|
  | Refund, void after print, drawer without a sale, or a discount above the limit, by a staff member signed in by email | No (fixed 2026-11-07) | `app.assert_approver` in `20261107001800_review_fixes.sql`: another employee can be named only from a paired terminal (`170_review_fixes.test.sql`) |
  | The same from a terminal (forged id from a rooted or stolen device) | Yes, by design (trust boundary R2) | `docs/phase-0-architecture.md` R2 |
  | Opening the drawer through a Rp 1 cash in/out | No (fixed 2026-11-07) | `core/pos/shift_service.dart` (`cashMovement` needs `pos.open_drawer` or an approver); `shift_screen.dart` |
  | Void after the receipt was shared as PDF | No (fixed 2026-11-07) | `core/printing/receipt_printing.dart` (`shared`), `receipt_screen.dart` |
  | Void after a thermal or system-dialog print | No | `core/pos/pos_services.dart` (`voidOrder`); `sync_order_void` |
  | Cancel a held bill without `pos.void` | No | `orders_screen.dart`; `sync_order_upsert` cancel branch |
  | Cash out or closing with a large difference | No approval exists (not required by the spec) | `shift_service.dart`; `sync_shift_close` |

## 6. Needs Claude Code

1. Outbox behaviour on `not_a_member` (`sync_engine.dart`).
2. PIN policy: length and hash cost (`set_employee_pin`, `PinVerifier`).
3. Phase 7 report RPCs (sales, products, payments, staff, stock valuation) with PDF/Excel export.
4. Phase 8 stock flows (transfers, purchase orders and receiving) and Phase 9 payments (gateway, webhooks).
5. Running the migrations and pgTAP on a real Supabase stack (PostgreSQL 17).

## 7. Safe for Antigravity (UI only)

- Visual polish of existing screens: the POS home cards, the shift screen layout, the receipt and refund screen styling, and the back-office tables.
- The back-office home/overview page (`back_office_home_screen.dart`) as a layout, using existing providers only.
- Empty, loading and error states, and the phone layouts of the back-office pages.
- App icons, splash screen and the text of the l10n strings (ARB files), keeping keys and placeholders.
- Phase 7 dashboard layout mock-ups, as long as the numbers come from RPCs that Claude Code adds.

## 8. Next steps

1. Delete the stray `GeneratedPluginRegistrant - Copy.java` and commit Phase 6 with the review fixes.
2. Run the migrations and pgTAP on a staging Supabase project (PostgreSQL 17).
3. Test printing, the drawer, points and kasbon on the real printers and terminals.
4. Pause the outbox on `not_a_member` instead of failing each item, and require 6-digit PINs for approvers.
5. Start Phase 7 (dashboard and reports).

## 9. Last updated

2026-11-06 · Claude Code audit; updated 2026-11-07 after Phase 6 and the review fixes
