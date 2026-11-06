# CashierA database (Supabase)

This folder is the complete server side so far: the Phase 1 schema, row level security, triggers, RPC API, demo seed and pgTAP tests, plus the Phase 3 catalog RPCs. The design behind it is in [docs/phase-0-architecture.md](../docs/phase-0-architecture.md).

## Contents

| Path | What it is |
|---|---|
| `config.toml` | Supabase CLI 3.0 project config. Anonymous sign-ins are on (terminal pairing uses them) and the minimum password is 8 characters |
| `migrations/20261105000100_foundation.sql` | pgcrypto, private `app` schema, shared helpers |
| `migrations/…0200_identity.sql` | Business profile, stores and settings, permissions, editable roles, employees, PINs, terminals, pairing codes |
| `migrations/…0300_access_helpers.sql` | Who is calling and which stores and permissions they have, assertion helpers, owner and role guards |
| `migrations/…0400_catalog.sql` | Units, categories, suppliers, products, variants (SKU), modifiers, recipes (BOM), store prices, reorder points, favorites |
| `migrations/…0500_customers_payments_promotions.sql` | Customers, payment methods, promotions (validated JSON rules), vouchers |
| `migrations/…0600_sales.sql` | Tables and printers, shifts, petty cash, orders, items, discounts, payments, refunds, kasbon, loyalty ledger, KDS status |
| `migrations/…0700_inventory.sql` | Stock levels and movements, adjustments, opname, purchase orders, goods receipts, transfers, alerts |
| `migrations/…0800_finance.sql` | Expense categories and expenses |
| `migrations/…0900_audit_sync.sql` | Append-only audit log, sync inbox, rejection log, tombstones, shared triggers |
| `migrations/…1000_business_logic.sql` | Stock engine with row locking, order lifecycle, refunds, kasbon, vouchers, receiving, transfers, opname, shift cash |
| `migrations/…1100_rpc.sql` | RPC API (`sync_push` and the others listed below) |
| `migrations/…1200_rls.sql` | RLS on every table |
| `migrations/…1300_grants_realtime_storage.sql` | Grants, the Realtime allow-list, Storage buckets and policies |
| `migrations/…1400_catalog_rpc.sql` | Phase 3: `save_product`, `import_catalog`, `stock_overview`, `catalog_export` |
| `migrations/…1500_pos.sql` | Phase 4: `save_promotion`, and the line-tax rule for bills whose only taxable part is the service charge |
| `migrations/…1600_shift_audit.sql` | Phase 5: `shift_overview`, `audit_entries`, names in `shift_summary`, and an audit entry for every approved manual discount |
| `migrations/…1900_reports.sql` | Phase 7: `report_sales`, `report_payments`, `report_products`, `report_staff`, `report_tax`, `report_stock_value`, `dashboard_summary` |
| `migrations/…1800_review_fixes.sql` | Review fixes: an approval naming another employee only from a paired terminal; payments only on completed orders; expected cash from completed and voided sales only |
| `migrations/…1700_loyalty_kasbon.sql` | Phase 6: points checked against `business_profile`, the `loyalty.adjust` permission, `adjust_points`, `kasbon_overview`, `customer_statement` |
| `migrations/…2000_purchasing_fnb.sql` | Phase 8: `save_purchase_order`, `set_purchase_order_status`, `receive_purchase_order` (goods receipts `GR-<store>-yyMMdd-NNN`), `purchase_order_list`, `purchase_order_detail`, `transfer_list`, `transfer_detail`, `kitchen_queue` |
| `migrations/…2100_payment_gateway.sql` | Phase 9: `payment_methods.gateway`, the `QRIS Dinamis` method, `gateway_charges` (Realtime), `gateway_charge_open` / `_attach` / `_settle` / `_status` / `_list`, and the trigger that refuses a gateway payment without a paid charge (`gateway_unconfirmed`) |
| `functions/qris-create`, `functions/qris-cancel`, `functions/midtrans-webhook` | Phase 9 Edge Functions. The logic is in `functions/_shared/handlers.ts` and `midtrans.ts` (tested under Node 24: `npm test` in `functions/`); setup is in [docs/release/deploy.md](../docs/release/deploy.md) |
| `seed.sql` | Demo data. The demo sign-ins and PINs are listed in its header |
| `tests/database/*.test.sql` | 22 pgTAP files, 434 assertions |

## 1. Test it on this PC (no Docker)

[`tools/db-test`](../tools/db-test) applies every migration, the seed and all tests to **PGlite** (real PostgreSQL compiled to WebAssembly) with small stand-ins for Supabase's `auth`, `storage` and Realtime objects:

```bash
cd tools/db-test
npm install
npm test
```

Expected output ends with `All 22 test files passed (434 assertions)`. To run a single file, use `node run.mjs --only 030`.

## 2. Use a hosted Supabase project

1. Create a project at supabase.com. Singapore (`ap-southeast-1`) is the closest region to Indonesia.
2. Dashboard → **Authentication → Sign In / Providers** → turn on **Allow anonymous sign-ins**. Terminals need this to pair. For production, also turn on CAPTCHA (Cloudflare Turnstile).
3. Push the schema. In CLI 3.0 commands target your **local** database unless you pass `--remote`:

   ```bash
   npx supabase@3.0.0 login
   ```

   ```bash
   npx supabase@3.0.0 link --project-ref <your-project-ref>
   ```

   ```bash
   npx supabase@3.0.0 db push --remote
   ```

4. Demo data is for development or staging projects only. Never load it into production, because it creates demo logins:

   ```bash
   npx supabase@3.0.0 db push --remote --include-seed
   ```

5. Optionally, run the same pgTAP suite against that staging project. The first test file installs a `tests` helper schema there, so never do this on production:

   ```bash
   npx supabase@3.0.0 test db --remote
   ```

## 3. Full local stack (needs Docker Desktop)

```bash
npx supabase@3.0.0 start
```

```bash
npx supabase@3.0.0 db reset
```

```bash
npx supabase@3.0.0 test db
```

`db reset` applies the migrations and then `seed.sql`. `test db` runs the real pgTAP extension, and the test files are written so they pass both there and on PGlite.

## 4. Security model

- **Principals.** An *employee* signs in with email and password and is linked through `employees.auth_user_id`. A *terminal* signs in anonymously and is bound by `pair_device` to `devices.auth_user_id`. Anyone else is not a member and can read nothing.
- **Store scope.** `app.store_ids_with(permissions)` returns the stores a caller can read:

  | Caller | Stores |
  |---|---|
  | Owner (`all_stores` role) | every store |
  | Other staff | the stores in `employee_stores` |
  | Terminal | its own store |

  Every store table's SELECT policy uses it.
- **Writes.** Orders, shifts, payments, refunds, kasbon and stock have no client write policies. They change only through `SECURITY DEFINER` RPCs that check the store, the acting employee and their permission (`app.assert_write_scope`, `app.assert_actor`, `app.assert_approver`). Master data (catalog, promos, settings, staff, purchasing) is written directly under permission policies.
- **Hidden data.** PIN hashes live in `employee_pins`, which has no client access at all. Loyalty balances and voucher counters have column-level grants and are maintained only by triggers. `anon` has no table privileges.
- **Approvals.** These need an employee who holds the permission (a colleague by PIN on the terminal, or the person on duty if they hold it themselves):

  | Action | Permission |
  |---|---|
  | Manual discount above the store threshold (default 20%) | `pos.discount_override` |
  | Void or cancel after a receipt or bill was printed | `pos.void_after_print` |
  | Any refund | `pos.refund` |
  | Opening the drawer without a sale | `pos.open_drawer` |

  Each approval is written to `audit_log` with the approver (approved manual discounts as `order.discount_approved` when the sale completes, migration 1600). The approver may be the person on duty when they hold the permission. Naming *another* employee as approver is accepted only from a paired terminal, which checked that employee's PIN; staff signed in anywhere else approve as themselves only (`approval_requires_terminal`, migration 1800).
- **Immutability.** The audit log rejects UPDATE, DELETE and TRUNCATE, even from the database owner. Stock movements, refunds, petty cash, kasbon payments and the loyalty ledger are append-only. A completed order's money and lines are frozen: fix it with a void or a refund.

## 5. Sync API: `sync_push(client_uuid, entity, action, payload)`

The only write path for terminals. It is idempotent on `client_uuid`, the id of the sync_queue row.

| Response | Meaning | Terminal does |
|---|---|---|
| `{"status":"applied","result":{…}}` | Applied now | mark `DONE` |
| `{"status":"duplicate","result":{…}}` | Already applied earlier; original result | mark `DONE` |
| `{"status":"rejected","code":"…","message":"…"}` | Business rule failed. Nothing was written, and the rejection is logged in `sync_rejections` | mark `FAILED`, show in the Sync screen, manual retry |
| HTTP error (deadlock, serialization, timeout, network) | Transient | retry with backoff |

| entity.action | Payload (ids are client UUIDs) | Effect |
|---|---|---|
| `shift.open` | `id, store_id, opened_by, opened_at, opening_cash` | Opens a shift. One open shift per terminal |
| `shift.close` | `id, closed_by, closed_at, counted_cash, client_expected_cash, note` | Server computes the expected cash and the selisih, and raises `CASH_DISCREPANCY` if the terminal's figure differs |
| `cash_movement.create` | `id, shift_id, movement_type (in/out), amount, reason (≥3 chars), employee_id` | Petty cash |
| `order.upsert` | Full snapshot: header totals, `items[]` (with `modifiers[]`), `discounts[]`, `payments[]`, `version`, `status` (open, held, completed, cancelled), `cancel{cancelled_by, reason, approved_by}` | Open or held orders accept newer versions. `completed` triggers stock, loyalty, kasbon, vouchers and tables. Closed orders ignore stale or retried versions and reject newer ones |
| `order.void` | `order_id, voided_by, approved_by, reason, shift_id` | Restock, reverse points, void the kasbon, recompute shift cash |
| `order.mark_printed` | `order_id, printed_at` | Marks the receipt as printed, so later voids need approval |
| `refund.create` | `id, order_id, refund_number, reason, amount, method_type, restock, employee_id, approved_by, shift_id, items[{id, order_item_id, quantity, amount}]` | Partial or full refund, restock, proportional points reversal |
| `customer.upsert` | `id, name, phone, email, …, employee_id` | Create or edit. A duplicate phone raises `CUSTOMER_DUPLICATE` |
| `receivable_payment.create` | `id, receivable_id or order_id, amount, method_type, reference, employee_id, shift_id` | Kasbon installment, returns the balance |
| `stock_adjustment.create` | `id, store_id, adjustment_number, reason, employee_id, items[{id, variant_id, quantity_delta}]` | Stock in, out, waste or correction |
| `stock_opname.submit` | `id, store_id, opname_number, employee_id, items[{variant_id, counted_qty}]` | Count and adjust in one step |
| `audit.log` | `id, action, entity_type, entity_id, actor_employee_id, approver_employee_id, details` | Terminal events such as reprints and `pos.drawer_open_no_sale` (approval enforced) |
| `dining_table.status` / `kitchen.status` | `table_id, status, employee_id` / `order_id, station, status, employee_id` | F&B floor and KDS |

Rejection codes the app should translate for cashiers include `tax_mismatch`, `payment_mismatch`, `order_totals_mismatch`, `approval_required`, `approval_denied`, `permission_denied`, `shift_required`, `shift_closed`, `store_mismatch`, `kasbon_requires_customer` and `refund_exceeds_received`.

**Line tax.** The tax is spread over the taxable lines. When no taxable line has anything left to carry it (an exempt basket with a taxable service charge), the header keeps the tax and the lines carry none (migration 1500).

**Points (migration 1700).** A completed sale with a customer must earn exactly ⌊net_total / loyalty_earn_amount⌋ points (`points_earned_mismatch`), value redeemed points at `loyalty_point_value` (`points_value_mismatch`), and reach `loyalty_min_redeem_points` (`points_below_minimum`). With loyalty off, no points at all (`loyalty_disabled`).

**Payments (migration 1800).** Only a completed order carries payments; a held, open or cancelled snapshot with payments is refused (`payments_require_completion`). Expected cash and the X/Z cash sales count the cash of completed and voided sales only.

**Money contract.** The server re-checks the arithmetic in [docs §4.5](../docs/phase-0-architecture.md#45-money-quantities-and-tax). The line sums must equal the header, the payments must equal the grand total, and the tax must be `round(base × r / (10000 + r))` when tax is included in the price, or `round(base × r / 10000)` when it is added on top. Quantities travel as decimal strings (`"1.250"`). Amounts are integer rupiah.

## 6. Other RPCs

| Function | Who | Purpose |
|---|---|---|
| `current_principal()` | Anyone | `{kind: device or employee or none, permissions, store_ids…}`, so the app can pick a shell |
| `create_device_pairing_code(store_id, device_name)` | `device.manage` | 8-character code, valid 15 minutes |
| `pair_device(code, platform, app_version)` | Anonymous terminal | Binds this sign-in to the store as `T<n>` |
| `revoke_device(device_id, reason)` | `device.manage` | Cuts access immediately |
| `device_heartbeat(app_version)` | Terminal | Last seen time and server time (for clock-skew checks) |
| `device_staff()` | Terminal | Staff, permissions and bcrypt PIN hashes for offline PIN login |
| `set_employee_pin(employee_id, pin)` | Self, or `employee.manage` in the same store (owners: anyone) | 4 to 6 digits; repeated digits and simple sequences are refused |
| `verify_employee_pin(employee_id, pin)` | Terminal of that store, or self | Online check with lockout (5 wrong tries locks for 5 minutes) |
| `request_stock_transfer(from, to, items, note, employee_id)` | `transfer.request` at the receiving store | Creates a request |
| `transition_stock_transfer(id, status, items, note, employee_id)` | Approve, reject or ship: `transfer.approve` at the sender. Receive: `inventory.receive` at the receiver | Moves stock and flags differences |
| `transfer_list(store_id, direction, status)` and `transfer_detail(id)` | `inventory.view`, `transfer.request` or `transfer.approve` in one of the two stores | Transfers with store and employee names; `direction` `in` / `out` relative to `store_id`. The detail has every event (who and when), the quantities requested, shipped and received, and the sender's stock |
| `save_purchase_order(p)` | `purchase.manage` at the store | Creates or replaces a `draft` / `ordered` PO and its lines; refused (`po_locked`) once goods arrived |
| `set_purchase_order_status(id, status)` | `purchase.manage` | draft → ordered; draft or ordered → cancelled while nothing was received; audited |
| `receive_purchase_order(p)` | `inventory.receive` at the store | One goods receipt for an ordered or partly received PO. Refuses more than is still open (`receipt_exceeds_order`) and an empty receipt. Stock in and weighted-average cost per delivery; status becomes `partially_received` or `received`; audited |
| `purchase_order_list(store_id, status)` and `purchase_order_detail(id)` | `purchase.manage`, `inventory.receive` or `reports.view` | POs with supplier, totals and the received share; the detail has the lines and every receipt |
| `kitchen_queue(station, store_id)` | Terminal of the store, or `kitchen.view` | Active tickets (new, preparing, ready) oldest first, each with only its station's items, modifiers and notes, the table and the guests. `kitchen.status` and `dining_table.status` (through `sync_push`) move them on |
| `gateway_charge_open(p)` | Paired terminal, write scope of the store | Opens a pending dynamic QRIS charge (id = the payment id) for an active gateway method; the same id again returns the same charge |
| `gateway_charge_attach(id, provider_ref, qr_string, expires_at, raw)` and `gateway_charge_settle(id, status, gross_amount, transaction_id, raw)` | `service_role` only (Edge Functions) | Store Midtrans's answer; settle refuses another amount (`amount_mismatch`, audited), keeps `paid` final, accepts a late payment after expiry; every change is audited as `payment.gateway_<status>` |
| `gateway_charge_status(id)` | `pos.sell` / `reports.view` in the store, or the service role | The charge as the terminal watches it |
| `gateway_charge_list(store_id, from, to)` | `reports.view` | Charges by store-local date with `matched` (a sale booked it); paid and unmatched = money without a sale |
| `complete_stock_opname(opname_id, employee_id)` | `inventory.opname` | Completes a draft opname |
| `shift_summary(shift_id)` | Terminal, `shift.manage` or `reports.view` | X-report (open shift) or Z-report (closed) data, with the terminal code and the opener and closer names |
| `shift_overview(store_id, from, to)` | `shift.manage` or `reports.view` | Shifts by business date (newest first, at most 500) with expected and counted cash, selisih, order count and sales |
| `audit_entries(store_id, from, to, only_approvals, action_prefix, limit, before, before_id)` | `audit.view` | Audit log with actor, approver, store and terminal names, newest first (at most 200 per page). Page with the `occurred_at` and `id` of the last row shown. Company-wide entries are for owners |
| `report_sales(store_id, from, to)` and `report_payments`, `report_products(…, limit)`, `report_staff`, `report_tax` | `reports.view` | One store or (null) every store the caller may report on, inclusive business dates, at most 367 days. Sales = completed orders; voids separate; refunds by refund date; net sales = grand − refunds. `180_reports.test.sql` pins the identities: Σ by day = Σ by store = Σ payments = Σ staff = total, Σ products = Σ categories = net, tax report = tax, DPP + PPN = base |
| `report_stock_value(store_id)` | `reports.view` | On-hand stock × current cost per store and variant; negative stock adds no value |
| `dashboard_summary(store_id, today)` | `reports.view` | Today and yesterday totals, last 7 days, today's top products and payments, open shifts, low stock, open alerts, overdue kasbon |
| `adjust_points(customer_id, points, note)` | `loyalty.adjust` (owner, manager) | Adds or removes points with a note of at least 3 characters; refuses a balance below 0 (`points_insufficient`); audited as `loyalty.adjusted` |
| `kasbon_overview(store_id, as_of)` | `kasbon.manage` or `reports.view` | Outstanding kasbon per customer and store: open count, outstanding, overdue, oldest due date, most overdue first |
| `customer_statement(customer_id)` | Staff | The customer, their kasbon (with installments) in the stores the caller may see, and the last 100 points entries |
| `save_product(p)` | `catalog.manage` | Saves a product, its variants and per-store prices and reorder points in one transaction. Variants left out are deactivated, not deleted. Raises `duplicate_sku` or `duplicate_barcode` |
| `import_catalog(rows)` | `catalog.manage`, plus `inventory.opname` at each store whose stock column is filled | All-or-nothing import of up to 5,000 rows. Creates missing categories (matched case-insensitively), matches products by SKU and then by name, and applies stock as one opname per store. A bad row fails the whole import with `import_invalid: row N: …`. Writes a `catalog.imported` audit entry and returns the counts |
| `stock_overview(store_id)` | `inventory.view`, `reports.view` or `pos.sell` at that store | Every active variant with on-hand stock, reorder point and a low flag |
| `catalog_export()` | Readers of the catalog | One row per variant in import-template shape, with stock per store code |
| `save_promotion(p)` | `promo.manage` | Saves a promotion and its store list in one transaction (an empty `store_ids` means every store). Rules that do not fit the type are refused with `promotion_rules_invalid` |

Terminals pass `employee_id` (the PIN-verified user). Back-office callers always act as themselves.

## 7. Backups and audit

- **Free plan: no automatic backups**, and projects pause when idle. Do not run real stores on it.
- **Pro plan:** daily backups kept for 7 days (Dashboard → Database → Backups). Add **Point-in-Time Recovery** if losing up to a day of sales is unacceptable.
- **Your own copy as well:** a nightly logical dump to private storage. `tools/backup/backup.sh` (scheduled, with a checksum, a content check and 30-day retention) and `tools/backup/restore-drill.sh` are described in [docs/release/backups.md](../docs/release/backups.md). For a one-off copy:

  ```bash
  npx supabase@3.0.0 db dump --remote -f backup.sql
  ```

  ```bash
  npx supabase@3.0.0 db dump --remote --data-only --use-copy -f data.sql
  ```

- **Audit trail.** Data in the database includes:
  - `audit_log`: who, what, when, store and terminal, append-only
  - `data.*` rows for changes to prices, staff, roles, settings, promotions and expenses
  - `stock_movements`: full stock history
  - `sync_inbox` / `sync_rejections`: what every terminal sent

## 8. Adding a migration later

1. Create `migrations/<YYYYMMDDHHMMSS>_<name>.sql`.
2. Every new table needs, in that migration:
   - `alter table … enable row level security` and its policies
   - an `updated_at` trigger (`app.touch_updated_at`) if it has the column
   - a tombstone trigger (`app.record_tombstone('<pk columns>')`) if terminals cache it
   - an audit trigger (`app.audit_row_change`) if it is sensitive

   The existing triggers were attached in 0900, and new tables don't get them automatically.
3. Add or extend a test in `tests/database`, then run `npm test` in `tools/db-test`.

## 9. What has and hasn't been verified

- ✅ All migrations, the seed and the 434 assertions pass on PGlite 0.5.15 (PostgreSQL 18.6), checked on 2026-11-07 after Phase 9. The Edge Function logic (`functions/_shared`) passes 15 Node tests (`cd supabase/functions && npm test`); the Deno entry points have not been type-checked here (no Deno on this PC). `140_shift_audit.test.sql` closes a shift built the same way as `cashiera_core/test/shift/server_fixture_test.dart`, so the terminal's X/Z report and the server's agree on one shared example. `130_pos.test.sql` books a sale priced by the Dart engine (`cashiera_core/test/pricing/server_fixture_test.dart` builds the same numbers), so the server and the terminal are checked against one shared example.
- ⚠️ Hosted Supabase runs PostgreSQL 17. The SQL avoids PostgreSQL 18-only features, but it has **not yet been run on a real Supabase stack** (this PC has no Docker). Run `supabase db push --remote` plus `supabase test db --remote` on a staging project, or the local Docker stack, before going live.
- ⚠️ The Supabase stand-ins in `tools/db-test/supabase-shim.sql` cover only what these migrations touch (auth users, JWT claims, storage tables, the realtime publication). They are not a full Supabase emulation.
