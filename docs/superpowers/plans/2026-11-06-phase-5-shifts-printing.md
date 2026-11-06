# Phase 5: Shifts, Approvals, Audit and Thermal Printing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** a cashier closes the shift and sees the cash difference (selisih) with an X or Z report. Voids, refunds, cash in/out and a no-sale drawer open work offline and ask for a manager PIN where the rules say so. Receipts and reports print on ESC/POS thermal printers, which also kick the drawer. The back office lists shifts with their reports and the audit log.

**Architecture:**
- **`cashiera_core` (pure Dart, TDD):**
  - `ShiftReport`: one model for the X/Z report. It is read from the server's `shift_summary` JSON or built from the terminal's own rows, with the same expected-cash formula as `app.shift_expected_cash`.
  - Refund amount allocation.
  - `ReceiptDocument` plus `EscPosEncoder`, which turns a layout into printer bytes.
- **Terminal:**
  - Drift v4 adds cash movements, refunds, void fields on orders, close fields on shifts, and the printer setting.
  - Services write the local row and the outbox item in one transaction, as in Phase 4.
  - A `PrinterService` sends bytes over `flutter_thermal_printer` (Bluetooth, BLE, USB) or raw TCP 9100 (network). The web build uses a stub.
- **Server:** the cashier actions already exist (`shift.close`, `cash_movement.create`, `order.void`, `refund.create`, `audit.log`, `shift_summary`). Migration `1600` adds two back-office reads, `shift_overview` and `audit_entries`, and puts names into `shift_summary`.

**Tech stack:** existing stack plus `flutter_thermal_printer ^2.3.0` (Phase 0 dependency list).

**Spec:** [phase-0 §4.7 printing, A10, A12, §8 Phase 5](../../phase-0-architecture.md), [supabase/README §4 approvals, §5 payloads, §6 shift_summary](../../../supabase/README.md).

## Global Constraints

- Expected cash = kas awal + cash payments of the shift − cash of orders voided in this shift − cash refunds + cash kasbon repayments + cash in − cash out. Selisih = counted − expected.
- Approvals (a second employee, or the same one if they hold the permission, by PIN offline):
  - void after print: `pos.void_after_print`
  - any refund: `pos.refund`
  - drawer open without a sale: `pos.open_drawer`
  - void before print: `pos.void` (yours, or an approver's)
- Void: completed orders only, and never after a refund. Refund: at most what was paid in non-kasbon money minus earlier refunds. Per line, at most its net amount minus earlier refunds. A cash refund needs an open shift.
- Reasons are at least 3 characters (void, refund, cash movement).
- Paper: 58 mm = 32 columns, 80 mm = 48 columns. Drawer pulse `ESC p 0 25 250`.
- Shift close, refunds and voids are queued FIFO after the sales they depend on, so the server computes expected cash over the same rows.

## Review Focus

1. **Void of an order sold in an earlier (closed) shift:** its cash comes off the *current* shift's expected cash, because the money leaves the drawer now. Pinned by a `ShiftReport` test and pgTAP.
2. **Partial refunds that add up:** refunding 1 of 3, then 2 of 3, gives exactly the line's net amount in total. The last part takes the remainder. Pinned by a core test.
3. **Printer missing or switched off:** the sale is never blocked. The cashier gets a message and can share the PDF. The receipt is only marked printed after the bytes were sent. Pinned by a printer service test with a failing transport.
4. **Cash out larger than the drawer:** refused on the terminal ("only Rp X in the drawer"). Pinned by a shift service test.
5. **Closing with held bills or a full outbox:** held bills stay held and are listed as a warning. The close goes into the outbox after the queued sales, so the server's expected cash matches the terminal's. Pinned by a shift service test that checks queue order and `client_expected_cash`.

---

### Task 1: Core shift report and refunds (`packages/cashiera_core/lib/src/shift/`)

**Files:** `shift_report.dart`, `refund.dart`, `cash_count.dart`; tests `test/shift/*_test.dart`.

**Produces:**
- `ShiftCash{openingCash, cashSales, voidedCash, cashRefunds, kasbonCash, cashIn, cashOut, countedCash?}`, with `expected` and `difference`.
- `ShiftReport{kind (x|z), shiftId, deviceCode?, openedByName?, closedByName?, openedAt, closedAt?, sales: SalesTotals, voids: (orders, total), cancelledOrders, payments: List<PaymentTotal{name, methodType, count, amount}>, refunds: (count, amount, cash), kasbon: (issued, repaid, repaidCash), cash: ShiftCash, topItems: List<TopItem{name, quantity: Qty, net}>}`.
  - `ShiftReport.fromJson(Map)` reads the `shift_summary` shape.
  - `ShiftReport.build(...)` builds it from terminal rows: orders with payloads, refunds, cash movements.
- `CashCount`: Indonesian denominations 100000 … 100 → total.
- `allocateRefund({lineNet, lineQty, refundedQty, refundedAmount, qty}) → Money`. It rounds half up, `round(net × q / Q)`, and the remainder is taken when the refund reaches the full quantity.
- `RefundProblem` check covering nothing selected, over-quantity and over-paid.

Tests pin:
- the expected-cash identity
- a void from an earlier shift
- payments grouped by method
- cancelled orders counted separately
- the partial-refund sums
- a shared fixture equal to pgTAP `140`

### Task 2: Server (`1600_shift_audit.sql`, pgTAP `140_shift_audit.test.sql`)

- `shift_overview(p_store_id uuid, p_from date, p_to date)`, needs `shift.manage` or `reports.view`. Returns rows with device code, opener and closer names, opened and closed times, opening, expected and counted cash, difference, status, order count and grand total.
- `audit_entries(p_store_id uuid, p_from timestamptz, p_to timestamptz, p_only_approvals bool, p_action_prefix text, p_limit int, p_before timestamptz)`, needs `audit.view`. Returns rows with actor and approver names and the device code, newest first, at most 200.
- `shift_summary` also returns `device_code`, `opened_by_name` and `closed_by_name`.
- pgTAP:
  - The fixture shift is opened, then sells cash and card, takes cash in and out, voids a printed order (it fails without an approver, then passes with one), refunds partly in cash, and closes. Expected cash and the difference equal the core fixture.
  - Both RPCs honour store scope and permissions.

### Task 3: Terminal data and services (Drift v4)

- Shifts gain `closedBy`, `closedByName`, `countedCash`, `expectedCash` and `note`.
- Orders gain `voidedAt`, `voidReason` and `voidedShiftId`. The status may be `voided`.
- New tables:
  - `LocalCashMovements` (id, shiftId, type, amount, reason, employeeName, occurredAt)
  - `LocalRefunds` (id, orderId, shiftId, number, amount, methodType, restock, reason, itemsJson, employeeName, approvedByName, refundedAt)
  - `LocalPrinters` (id, name, connection, address, paperMm, opensDrawer, autoPrint)
- `ShiftService`:
  - `cashMovement(...)` sends `cash_movement.create`. It needs `shift.cash_movement` and refuses a cash out above the drawer.
  - `report(shift)` returns a `ShiftReport` X.
  - `close(shift, staff, counted, note)` sends `shift.close` with `client_expected_cash` and returns a Z `ShiftReport`.
- `OrderService.voidOrder(order, ctx, reason, approvedBy)` sends `order.void` and puts tracked stock back.
- `RefundService.refund(order, lines, method, restock, reason, approver, ctx)` sends `refund.create`, numbered `R-PST-T1-261106-0001`, and puts stock back when restock is on.
- `AuditService.log(action, ...)` sends `audit.log`. It is used for `pos.drawer_open_no_sale` (with approver) and `receipt.reprinted`.

### Task 4: Printing

- Core `ReceiptDocument` blocks:
  - `text` (align, bold, double size)
  - `row(left, right)`, with word wrap
  - `rule`
  - `feed`
  - `qr`
  - `cut`
  - `drawer`
- `EscPosEncoder(columns).encode(doc) → Uint8List`. Text is folded to ASCII.
- App:
  - `receiptDocument(ReceiptData, labels)` and `shiftReportDocument(ShiftReport, labels)`.
  - `PrinterTransport { Future<void> send(PrinterSetting, Uint8List) }` with `NetworkTransport` (Socket, 5 s timeout) and `PluginTransport` (`flutter_thermal_printer`), plus `discover()`.
  - `PrinterService.printReceipt`, `printReport`, `kickDrawer` and `testPage`.
- Printer screen `/pos/printer`:
  - search for Bluetooth and USB printers, or type a network address
  - paper width
  - "opens drawer"
  - auto-print
  - test print

### Task 5: Terminal screens

- `/pos/shift`: the live X report, **Kas masuk / Kas keluar**, **Buka laci** (approval), **Cetak X** and **Tutup shift**. Closing counts cash by denomination or as a total, shows expected, counted and selisih, takes a note and confirms, then shows the Z report with print and share.
- Receipt screen:
  - **Cetak** uses the thermal printer when one is set and falls back to the system dialog
  - a reprint is audited
  - **Void** and **Refund** buttons for completed orders
  - a status for voided orders and refunds
- `/pos/refund/:id`: quantity per line, restock, method (cash or the original non-cash method), reason and approval. Then a refund slip is printed.
- After a sale: auto-print when set, and the drawer opens on cash payments when the printer opens the drawer.
- POS home: Shift and Printer cards.

### Task 6: Back office

- **Shift** page: store and date filters, a list with the selisih in colour, and a tap opens the X/Z report (`shift_summary`) with a PDF.
- **Audit** page: store, dates, "approvals only" and an action filter. Each entry shows who, the approver, the terminal, the time and the details. It pages backwards.

### Task 7: Verify

- `flutter analyze` and `dart analyze` are clean.
- Core, app and database tests all pass.
- `flutter build web` passes, which proves the printer plugin stays out of web.
- READMEs and the "As built" notes are updated.

## As built (deviations)

- **Discount approvals are audited (migration 1600).** The README promised an audit entry for every approval, but approved manual discounts were only stored on the discount row. An `order.discount_approved` entry is now written when the sale completes (held snapshots don't count).
- **Bluetooth means BLE.** `flutter_thermal_printer` 2.3.0 prints over BLE, USB (Android, Windows by printer name, macOS) and system queues. A printer that only speaks Bluetooth Classic (SPP) is not reachable; use its BLE mode, USB or the network. Network printers use raw TCP 9100 in our own transport.
- **Printer setup lives on the terminal**, in `local_printers`, one receipt printer per terminal. It survives unpairing because it belongs to the hardware. The server's `printers` table is left for the kitchen and bar routing of Phase 8.
- **No logo on slips.** Receipts and reports are text plus a QR code with the order number. Raster logos are not printed.
- **Text is folded to ASCII for the printer** (accents dropped, `·` and dashes become `-`, anything else `?`), because code pages differ between printer models.
- **Refunds and voids cover this terminal's sales.** Other terminals' orders are not mirrored locally. Kasbon repayments arrive in Phase 6, so the kasbon part of a sale can't be refunded yet and the cash report shows 0 kasbon cash.
- **Closing needs a note when the count is not even.** The spec left this open.
- **Android manifest:** INTERNET was missing from the main manifest, which would have broken release builds. It is added, along with the Bluetooth permissions. iOS has its Bluetooth usage text.
- **Bugs found by the new tests and fixed:**
  - The receipt screen read the open shift before it had loaded, so Void said "open a shift first".
  - `·` printed as `?` on slips.
- **Verified on 2026-11-06:**
  - `dart format`, `flutter analyze` and `dart analyze` are clean.
  - Tests pass: core 111, app 117, database 16 files / 290 assertions.
  - `flutter build web` succeeds, so the printer plugin stays out of the web build.
  - The app tests include end-to-end runs on a fake printer: auto-print with the drawer, a printer that is off, cash out and close with a selisih, a void after print with a PIN, a partial refund, and the printer settings screen.
  - They also include a v3 → v4 database upgrade.
  - Not run on real printers, Android or Windows hardware, or a live Supabase project.
