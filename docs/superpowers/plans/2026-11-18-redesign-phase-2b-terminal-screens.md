# Redesign Phase 2b: The Other Terminal Screens Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restyle every remaining terminal screen and dialog (payment, QRIS, receipt, orders, refund, close shift, shift report, opname, sync, tables, kitchen, splash, setup, welcome, pairing, PIN lock and the sell/stock/shift/customer dialogs) with the phase 1 design system, without changing behaviour.

**Architecture:** Two shared pieces carry the rules of spec §3.3 and §4.6: `CenteredGlassPage` (screens without a shell: one centred glass card on the background) and `FlowHeader` (flow screens inside the shell: a Back button plus `PageHeader`, replacing the inner `AppBar` and its `BackButton`). Each screen keeps its route, providers, services and widget keys; only its widget tree changes. Dialogs move from `AlertDialog` to `GlassDialog`.

**Tech Stack:** Flutter 3.47.8 / Dart ^3.13 (`const new(...)` constructors), Riverpod 3, go_router 18, Drift, flutter_test.

**Spec:** `docs/superpowers/specs/2026-11-09-stitch-redesign-design.md` (§2.6, §3.3, §4.1 payment, §4.6, §5, §6, phase 2). Phase 2a plan: `docs/superpowers/plans/2026-11-10-redesign-phase-2a-stitch-screens.md`.

## Global Constraints

- No change to business logic, services, database, sync, permissions or routes.
- Every widget key used by tests is kept (lists per task). Back buttons go to the same route as today's `BackButton`.
- Use the phase 1 widgets: `GlassCard`, `GlassDialog`, `showGlassSheet`, `PrimaryButton`, `SecondaryButton`, `PageHeader`, `StatCard`, `StatusChip`, `MoneyText`, `InitialsAvatar`, `GlassTable`, `SegmentedTabs`, `PinPad`, `EmptyState`. Text-heavy surfaces use `GlassLevel.solid`.
- Flow screens (payment, receipt, refund, close shift) use a split layout on content ≥ 900 px and a single column below.
- Nothing invented: no new numbers, actions or data (spec §1 "Not in scope").
- Touch targets ≥ 48 dp. Money through `MoneyText` / `Money.format()`.
- Every new string in both `app_id.arb` and `app_en.arb`.
- Checks before each push: `dart format --set-exit-if-changed`, `flutter analyze --fatal-infos`, `flutter test`, `flutter build web --release` (app), `dart test` (core).

## Review Focus

1. Back navigation: each flow screen's Back goes where the old `BackButton` went (pay → `/pos/sell`, receipt → `/pos/orders`, refund → its receipt, close shift and shift report → `/pos/shift`, orders → `/pos/sell`). Tests in Tasks 3, 4, 5.
2. Payment on a phone (360×740): split tenders, the QRIS create button and Finish are all reachable without overflow, and Finish stays disabled until the bill is covered. Test in Task 3.
3. PIN lock at 360×640: the staff list and pin pad fit without overflow, and a long store name does not push the Lock actions off screen. Test in Task 2.
4. Dialogs on a short screen with the keyboard up (360×640, `viewInsets.bottom` 300): content scrolls rather than overflows. Test in Task 7.
5. Kitchen tickets and table tiles with 80-character product names or notes do not overflow. Test in Task 6.

---

### Task 1: Shared flow pieces and the segmented-button colour

**Files:**
- Create: `app/lib/core/design_system/widgets/flow.dart`
- Modify: `app/lib/core/design_system/theme.dart` (add `segmentedButtonTheme`)
- Test: `app/test/core/design_system/flow_test.dart`

**Interfaces:**
- Produces: `class CenteredGlassPage extends StatelessWidget { const new({required Widget child, double maxWidth = 480, Key? key}) }`: a transparent `Scaffold` whose body is a `SafeArea` + scrollable centre + `ConstrainedBox(maxWidth)` + `GlassCard(level: solid)` around `child`.
- Produces: `class FlowHeader extends StatelessWidget { const new({required String title, required VoidCallback onBack, String? subtitle, Widget? status, List<Widget> actions = const [], Key backKey = const Key('flow-back'), Key? key}) }`: a `SecondaryButton(key: backKey, icon: Icons.arrow_back, label: l10n.commonBack)` above a `PageHeader(title, subtitle, status, actions)`.
- Theme: `SegmentedButtonThemeData` whose selected state is `AppColors.primarySoft` background and `AppColors.primary` foreground (spec §2.1 "Selected chips"); unselected stays as today.

- [ ] **Step 1: Write the failing tests**: `FlowHeader` shows the title and calls `onBack` when `flow-back` is tapped; `CenteredGlassPage` at 360×640 with a 40-line column scrolls without an exception; a `SegmentedButton<int>` under `AppTheme.light()` paints its selected segment with `AppColors.primarySoft` (resolve `Theme.of(context).segmentedButtonTheme.style!.backgroundColor!.resolve({WidgetState.selected})`).
- [ ] **Step 2: Run** `flutter test test/core/design_system/flow_test.dart`. Expected: FAIL (`flow.dart` missing).
- [ ] **Step 3: Implement** as in Interfaces.
- [ ] **Step 4: Run** the new tests and `flutter test`. Expected: PASS.
- [ ] **Step 5: Commit**: `Redesign: flow page and header, rose selected segments`

---

### Task 2: Splash, setup, welcome, pairing and PIN lock

**Files:**
- Modify: `app/lib/features/startup/presentation/{splash,setup,welcome}_screen.dart`, `app/lib/features/pairing/presentation/pairing_screen.dart`, `app/lib/features/pin_login/presentation/pin_lock_screen.dart`
- Test: `app/test/features/startup/flow_screens_layout_test.dart`

**Interfaces:**
- Consumes: `CenteredGlassPage`.
- Each screen: no `AppBar`; content inside `CenteredGlassPage`. Splash: logo tile + spinner. Setup: the existing message with the settings icon. Welcome: title, subtitle and the two choices as `GlassCard(onTap:)` rows (keys `welcome-pair`, `welcome-back-office`). Pairing: title, hint, `pairing-code` field, `PrimaryButton(key: pairing-submit, expand: true)`, back to welcome as `SecondaryButton`. PIN lock: `maxWidth: 720`; header row "store · Terminal T1" with the existing actions as `GlassPill`s; on ≥ 600 px the staff list (`staff-<id>` keys, `InitialsAvatar` rows) beside the `PinPad`, below it on phones.

- [ ] **Step 1: Failing tests**: each of the five screens pumped through the router (`AppRoutes.splash`, `setup`, `welcome`, `pair`, `lock`) shows no `AppBar` and one `GlassCard` ancestor of its main control (`welcome-pair`, `pairing-code`, a `staff-` key); welcome and PIN lock at 360×640 with an 80-character store name raise no exception; existing pairing and PIN tests pass unchanged.
- [ ] **Step 2–4** as in Task 1.
- [ ] **Step 5: Commit**: `Redesign: startup, pairing and PIN lock on centred glass`

---

### Task 3: Payment and the QRIS dialog

**Files:**
- Modify: `app/lib/features/sell/presentation/payment_screen.dart`, `app/lib/features/sell/presentation/qris_dialog.dart`
- Test: `app/test/features/sell/payment_layout_test.dart`

**Interfaces:**
- Keys kept: `pay-add pay-amount pay-change pay-due pay-finish pay-method-<id> pay-qris-create pay-quick-<n> pay-reference pay-remaining tender-<n>`.
- Layout: `FlowHeader(title: payTitle(...), onBack: → AppRoutes.sell, backKey: Key('pay-back'))`. Left card (`solid`): amount due (`pay-due`, numeric-xl in primary), tenders added (`tender-<n>` rows with remove), remaining (`pay-remaining`) and change (`pay-change`) lines. Right card (`solid`): method tiles (existing methods, selected tile in `primarySoft`), reference field, amount field, quick-cash chips, `pay-add` as `SecondaryButton`, `pay-finish` as `PrimaryButton(expand: true)`. Empty cart: `CenteredGlassPage`-style `EmptyState` with the same Back.
- QRIS dialog: `GlassDialog` around the existing QR, amount, status and cancel content; keys unchanged.

- [ ] **Step 1: Failing tests**: at 1280×800 after adding one item and opening `/pos/pay`, `pay-due` and `pay-method-cash` are side by side (their `getCenter` x differ by > 300) and there is no `AppBar`; `pay-back` returns to `/pos/sell`; at 360×740 a split cash payment (add Rp 2.000, then quick cash) reaches an enabled `pay-finish` after scrolling, with no exception, and `pay-finish` is disabled before the bill is covered.
- [ ] **Step 2–4.** Existing `sell_flow_test`, QRIS and kasbon tests must pass unchanged.
- [ ] **Step 5: Commit**: `Redesign: payment split layout and QRIS glass dialog`

---

### Task 4: Receipt, orders and refund

**Files:**
- Modify: `app/lib/features/sell/presentation/{receipt,orders,refund}_screen.dart`
- Test: `app/test/features/sell/after_sale_layout_test.dart`

**Interfaces:**
- Keys kept: receipt `receipt-change receipt-new-sale receipt-print receipt-refund receipt-share receipt-status receipt-void refund-<id>`; orders `order-<id> order-cancel-<id> orders-total`; refund `refund-all refund-line-<n> refund-method-<m> refund-minus refund-plus refund-qty refund-reason refund-restock refund-submit refund-total`.
- Receipt: `FlowHeader(title: receiptTitle, onBack: → AppRoutes.orders, backKey: Key('receipt-back'), status: StatusChip for the order status)`; split: left the receipt itself in a `solid` card (lines, totals, payments, change in primary), right the actions (new sale `PrimaryButton`; print, share, refund, void `SecondaryButton`s, same visibility rules).
- Orders: `FlowHeader(title: ordersTitle, onBack: → AppRoutes.sell, backKey: Key('orders-back'))`, the day total as a `StatCard`, and the orders in a `GlassTable` (number, time, items, status `StatusChip` (paid success, held warning, void error, refunded neutral), total numeric); row key `order-<id>` on the first cell; cancel action kept in the row.
- Refund: `FlowHeader(title: refundTitle(...), onBack: → that order's receipt, backKey: Key('refund-back'))`; split: lines card (steppers ≥ 48 dp), summary card (reason, method, restock, total, `refund-submit` `PrimaryButton`).

- [ ] **Step 1: Failing tests**: after one cash sale, receipt shows no `AppBar`, `receipt-back` goes to `/pos/orders`; orders lists the sale in a `GlassTable` with an upper-case header and `orders-back` goes to `/pos/sell`; refund (as `manager`) shows no `AppBar` and `refund-back` returns to `/pos/receipt/<id>`; receipt and refund at 360×740 raise no exception.
- [ ] **Step 2–4.** Existing receipt, void and refund flow tests pass unchanged.
- [ ] **Step 5: Commit**: `Redesign: receipt, orders and refund`

---

### Task 5: Close shift, shift report and sync

**Files:**
- Modify: `app/lib/features/shift/presentation/{close_shift,shift_report}_screen.dart`, `app/lib/features/sync_status/presentation/sync_screen.dart`
- Test: `app/test/features/shift/close_layout_test.dart`

**Interfaces:**
- Keys kept: close `close-confirm close-counted close-difference close-note close-submit close-total denomination-<n> denomination-count denomination-minus denomination-plus`; report `report-print report-share`; sync `sync-now`.
- Close shift: `FlowHeader(title: closeTitle, onBack: → AppRoutes.shift, backKey: Key('close-back'))`; split: denomination counter card (steppers ≥ 48 dp) and summary card (expected, counted, `close-difference` with `StatusChip` tone success when 0, warning when short or over, note, `close-submit` `PrimaryButton`).
- Shift report: `FlowHeader(title: <today's title>, onBack: → AppRoutes.shift, backKey: Key('report-back'), actions: print and share as SecondaryButton with the existing keys)`; the report body in a `solid` `GlassCard`, max width 720.
- Sync: `PageHeader(title: syncTitle, status: online/offline + pending, actions: [PrimaryButton(key: sync-now)])`; the outbox list in a `GlassTable` (entity, action, attempts, status chip, last error), `EmptyState` in a card when empty.

- [ ] **Step 1: Failing tests**: close shift and the report show no `AppBar`, `close-back` and `report-back` go to `/pos/shift`; a short count shows `close-difference` inside a `StatusChip`; sync shows `sync-now` and no `AppBar`; close shift at 360×740 raises no exception.
- [ ] **Step 2–4.** Existing shift and sync tests pass unchanged.
- [ ] **Step 5: Commit**: `Redesign: close shift, shift report and sync`

---

### Task 6: Opname, tables and kitchen

**Files:**
- Modify: `app/lib/features/catalog/presentation/opname_screen.dart`, `app/lib/features/fnb/{tables,kitchen}_screen.dart`
- Test: `app/test/features/fnb/fnb_layout_test.dart`; `app/test/features/catalog/opname_layout_test.dart`

**Interfaces:**
- Keys kept: opname `opname-<sku> opname-count-<sku> opname-submit`; tables `pos-table-<id> pos-table-clear-<id> pos-table-status-<id> table-guests table-guests-ok tables-sell`; kitchen `kitchen-refresh kitchen-station-<s> ticket-<id> ticket-next-<id>`.
- Opname: `FlowHeader(title: opnameTitle, onBack: → AppRoutes.catalog, backKey: Key('opname-back'), actions: [PrimaryButton(key: opname-submit)])`; rows in a `GlassTable` (product, system stock, counted field, difference numeric coloured by sign).
- Tables: `PageHeader` with the Quick sale action (`tables-sell`); a responsive grid of `GlassCard(solid)` tiles: table name, `StatusChip` (free success, occupied primary, bill warning), guests and open total, actions kept.
- Kitchen: `PageHeader` with station `SegmentedTabs` (`kitchen-station-<s>` on each segment) and refresh; tickets as `GlassCard(solid)` columns: order number, table, age `StatusChip` (warning after 10 min, error after 20 min, as the existing thresholds), item lines with notes, `ticket-next-<id>` `PrimaryButton`.

- [ ] **Step 1: Failing tests**: in F&B mode (seed `fnbMode: true` and one table), tables show no `AppBar` and the tile has a `StatusChip`; a kitchen ticket with an 80-character item name and note at 360×740 raises no exception; opname shows no `AppBar` and `opname-back` goes to `/pos/catalog`.
- [ ] **Step 2–4.** Existing F&B and opname tests pass unchanged.
- [ ] **Step 5: Commit**: `Redesign: opname, tables and kitchen`

---

### Task 7: Terminal dialogs on glass

**Files:**
- Modify: every `AlertDialog(` under `app/lib/features/{sell,shift,catalog,customers,fnb}/` (today: `sell_dialogs.dart` ×4, `cart_panel.dart`, `orders_screen.dart`, `shift_screen.dart`, `close_shift_screen.dart`, `opname_screen.dart`, `stock_adjust_dialog.dart`, `points_dialog.dart`, `customers_screen.dart` ×2, `tables_screen.dart`)
- Test: `app/test/features/sell/glass_dialogs_test.dart`

**Interfaces:**
- `AlertDialog(title:, content:, actions:)` becomes `GlassDialog(title:, content:, actions:)`; confirm buttons `PrimaryButton`, cancel `SecondaryButton` or `TextButton`; every key kept. Content that can grow is wrapped in `SingleChildScrollView`.
- `showModalBottomSheet(` in the same folders (e.g. the catalog item sheet) becomes `showGlassSheet(`; sheet content keeps its keys.
- Rule test: no `AlertDialog(` or `showModalBottomSheet(` remains in those folders (a test that reads the source files with `dart:io` and fails naming the file).

- [ ] **Step 1: Failing tests**: the rule test above; opening the manual discount dialog from the cart shows a `GlassDialog` and no `AlertDialog`; the same dialog at 360×640 with `tester.view.viewInsets = FakeViewPadding(bottom: 300)` raises no exception.
- [ ] **Step 2–4.** All existing dialog flows (discount, void, cash in/out, stock adjust, points, kasbon repay, guests) pass unchanged.
- [ ] **Step 5: Commit**: `Redesign: terminal dialogs on frosted glass`

---

### Task 8: Screenshots, checks, push

- [ ] **Step 1:** Add `app/test/screenshots/terminal_flows_screenshot_test.dart` (reuse `loadFonts`, `shot`, `tablet`, `phone` and `sampleData` from the existing screenshot tests): welcome, PIN lock, payment with one tender, receipt, orders, close shift, tables and kitchen (F&B seed), and the discount dialog, at 1280×800 and 390×844.
- [ ] **Step 2:** `flutter test --run-skipped --tags screenshots --update-goldens test/screenshots`. Expected: PNGs written to `test/screenshots/out/`; look at every one.
- [ ] **Step 3:** All Global Constraints checks green.
- [ ] **Step 4:** Commit `Redesign: phase 2b screenshots`, push the working branch, send the screenshots with the list of changed existing tests.
