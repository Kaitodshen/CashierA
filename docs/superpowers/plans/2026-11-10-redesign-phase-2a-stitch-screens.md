# Redesign Phase 2a: The Five Stitch Screens Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild Register & Checkout, Overview, Catalog, Members and Settings on the terminal to match the Stitch screens, using the phase 1 design system, without changing behaviour.

**Architecture:** Each screen keeps its route, providers and services; only its widget tree changes. Inner `AppBar`s go (the shell top bar replaces them). The top-bar search becomes the one search-and-scan field for Register and Catalog, through `terminalSearchProvider`. Payment tiles in the cart open the existing payment screen with the method (and quick-cash amount) pre-filled through query parameters.

**Tech Stack:** Flutter 3.47.8 / Dart ^3.13 (`const new(...)` constructors), Riverpod 3, go_router 18, Drift, flutter_test.

**Spec:** `docs/superpowers/specs/2026-11-09-stitch-redesign-design.md` (§4.1–4.5, §5, §6, phase 2). Phase 1 plan: `docs/superpowers/plans/2026-11-09-redesign-phase-1-foundation-shells.md`. Phase 2b (the other terminal screens) gets its own plan.

## Global Constraints

- No change to business logic, services, database, sync, permissions or routes (new optional query parameters on `/pos/pay` only).
- Widget keys used by tests are kept; where a control moves into the shell it keeps its key there (`sell-search`, `catalog-search`).
- Use the phase 1 widgets: `GlassCard`, `GlassPill`, `PrimaryButton`, `SecondaryButton`, `SearchScanField`, `ChipTabs`, `PageHeader`, `StatCard`, `StatusChip`, `StockBar`, `MoneyText`, `InitialsAvatar`, `ProductThumb`, `GlassTable`, `GlassDialog`. Text-heavy surfaces (cart, tables, forms) use `GlassLevel.solid`.
- Mockup elements without CashierA data are dropped, never invented: hourly chart and sales target, membership tiers, scanner / customer-display / firmware cards, product photos (no `imagePath` reaches `CatalogItem`; tiles show the initials thumb), catalog sort control.
- Members "Use in current sale" (spec §4.4) is not added: the terminal has no such action today, and the cart's existing Assign customer button does it; adding it would be new behaviour.
- Touch targets ≥ 48 dp (cart steppers included). Money uses `MoneyText` / `Money.format()`.
- Every new string in both `app_id.arb` and `app_en.arb`.
- Checks before each push: `dart format --set-exit-if-changed`, `flutter analyze --fatal-infos`, `flutter test`, `flutter build web --release` (app), `dart test` (core).

## Review Focus

1. Scanner flow: a code typed into the top-bar field plus Enter on Register adds the item (or shows "not found") and clears the field, and focus stays in it for the next scan. Tests in Task 1.
2. Payment pre-fill: a method id or amount in the URL that does not exist (or a stale amount larger than the bill) must not crash or pay too much; unknown ids are ignored, amounts are only a starting value in the field. Test in Task 3.
3. Overview with no open shift and with a shift that has no sales: no `null`/`…` crash, cards show `Rp 0`. Test in Task 4.
4. Long product, customer and store names never overflow tiles, rows or cards at 360 px and 1280 px. Tests in Tasks 2, 6.
5. Settings: switching Visual effects off immediately removes blur (top bar) and survives an app restart (stored). Test in Task 7.

---

### Task 1: One search-and-scan field in the top bar

**Files:**
- Modify: `app/lib/app/shell/terminal_search.dart`
- Modify: `app/lib/app/shell/terminal_shell.dart` (show the field again on `/pos/sell` and `/pos/catalog`)
- Modify: `app/lib/features/sell/presentation/sell_screen.dart` (remove its `TextField`; listen to the provider)
- Modify: `app/lib/features/catalog/presentation/catalog_browser_screen.dart` (same)
- Test: `app/test/app/terminal_search_test.dart`; update `app/test/app/review_fixes_test.dart` ("no dead search field" becomes "search shows only on Register and Catalog")

**Interfaces:**
- Produces: `class TerminalSearch extends Notifier<TerminalSearchState>`; `typedef TerminalSearchState = ({String query, int submissions, String lastSubmitted})`; methods `void type(String text)`, `void submit(String text)` (sets `lastSubmitted`, increments `submissions`), `void clear()` (query `''`); provider `terminalSearchProvider`. Replaces `terminalSearchQueryProvider`.
- The shell field: `SearchScanField` keyed `sell-search` on `/pos/sell` and `catalog-search` on `/pos/catalog`; its controller follows `query` (cleared when the state's query becomes `''`); `autofocus` on Register; hint `shellSearchHint`.
- Register: `ref.listen(terminalSearchProvider)` → `sellQueryProvider.setSearch(query)`; on a new submission runs the existing `_submit(code)` then `terminalSearchProvider.clear()`. Catalog: the query drives its existing filter. On leaving a screen the query is cleared (`ref.onDispose` / route change) so Catalog's filter never leaks into Register.

- [ ] **Step 1: Write the failing tests**

```dart
testWidgets('scanning a known code in the top bar adds it and clears', (t) async {
  await openTill(t, const Size(1280, 800));
  await t.enterText(find.byKey(const Key('sell-search')), 'MIE-001'); // seeded SKU
  await t.testTextInput.receiveAction(TextInputAction.search);
  await t.pumpAndSettle();
  expect(find.byKey(const Key('sell-total')), findsOneWidget);
  expect(find.text('Rp 3.500'), findsWidgets); // line + total
  final field = t.widget<TextField>(find.descendant(
      of: find.byKey(const Key('sell-search')), matching: find.byType(TextField)));
  expect(field.controller!.text, isEmpty);
});
testWidgets('unknown code shows not found', (t) async { ... sellNotFound text ... });
testWidgets('typing filters the product grid', (t) async { ... 'zzz' → catalogNoMatch ... });
testWidgets('catalog query does not leak into Register', (t) async {
  // type in catalog-search on /pos/catalog, go to /pos/sell → field empty, grid unfiltered
});
```

Use the seeded SKU/barcode from `seed()` in `till_harness.dart`.

- [ ] **Step 2: Run** `flutter test test/app/terminal_search_test.dart` — Expected: FAIL.
- [ ] **Step 3: Implement** as in Interfaces. Update `sell_flow_test.dart` only if a finder needs the `TextField` descendant of the keyed field.
- [ ] **Step 4: Run** the new tests and `flutter test` — Expected: PASS.
- [ ] **Step 5: Commit** — `Redesign: one search-and-scan field in the terminal top bar`

---

### Task 2: Register product pane

**Files:**
- Modify: `app/lib/features/sell/presentation/sell_screen.dart` (`_ProductPane`, `_ProductTile`, `SellScreen` frame, `_OpenShiftPanel`, `_CartBar`)
- Modify: `app/test/features/sell/sell_flow_test.dart:80` (`sell-orders` → `terminal-held-orders`); `review_fixes_test.dart` padding test (find the inner element by `Key('sell-pay')`, not `AppBar`)
- Test: `app/test/features/sell/register_layout_test.dart`

**Interfaces:**
- Consumes: Task 1; `ChipTabs`, `ProductThumb`, `StatusChip`, `GlassCard`, `MoneyText`.
- `SellScreen` has no `AppBar` (the held-orders button lives in the shell). Section header row: title `navRegister`-style "Merchandise" text `sellItemsTitle` + item count chip (`sellItemsCount(n)`).
- `_ProductTile` (keeps `Key('sell-item-<sku>')` on the tap target): `GlassCard(level: regular, radius: AppRadius.tile, padding: 12)` with `ProductThumb(name, size: full width, aspect 4:3)`, stock badge `StatusChip` top-left (`sellStockBadge(qty)`, warning tone when `isLow`, `sellUnavailable` neutral when unavailable), category name upper-case in primary (`label-sm`), name 2 lines ellipsis, "Price" label + `MoneyText` bold, and a 40 dp rose square `+` icon button (inside a 48 dp hit area) doing the same `addToCart`.
- Grid: `maxCrossAxisExtent: 220`, `mainAxisExtent: 268`, spacing 16.
- `_OpenShiftPanel`: centred `GlassCard(solid)` max width 440, keys `shift-opening-cash` / `shift-open` kept, `PrimaryButton` for open.
- `_CartBar` (phone): glass bar, keys `sell-open-cart` / `sell-pay-bar` kept.
- New l10n: `sellItemsTitle` ("Merchandise items" / "Barang dagangan"), `sellItemsCount` ("{count} items" / "{count} barang"), `sellStockBadge` ("{qty} in stock" / "Stok {qty}"), `sellPriceLabel` ("Price" / "Harga").

- [ ] **Step 1: Failing tests**: at 1280×800 the tile for the seeded item shows its category name upper-case, `Rp 3.500`, a stock badge, and tapping its `+` adds one line; at 360×740 and 1280×800 a product named 80 characters long causes no exception; no `AppBar` is found inside the shell on `/pos/sell`.
- [ ] **Step 2: Run** — Expected: FAIL.
- [ ] **Step 3: Implement.** Category names come from the existing `_categoriesProvider` list (`id → name` map).
- [ ] **Step 4: Run** the new file and `flutter test` — PASS.
- [ ] **Step 5: Commit** — `Redesign: Register product grid and tiles`

---

### Task 3: Cart "Active Ticket", payment tiles and quick cash

**Files:**
- Modify: `app/lib/features/sell/presentation/cart_panel.dart`
- Modify: `app/lib/features/sell/presentation/payment_screen.dart` (constructor parameters + initial pick only)
- Modify: `app/lib/app/app_mode.dart` (`AppRoutes.payWith`), `app/lib/app/router.dart` (pass query parameters)
- Create: `app/lib/features/sell/presentation/quick_cash.dart`
- Test: `app/test/features/sell/quick_cash_test.dart`, `app/test/features/sell/cart_layout_test.dart`

**Interfaces:**
- `List<int> quickCashAmounts(int due)` — ascending, distinct: `due` (exact), then `due` rounded up to the next 10 000, 50 000 and 100 000; empty for `due <= 0`. Example: `quickCashAmounts(500888)` → `[500888, 510000, 550000, 600000]`; `quickCashAmounts(50000)` → `[50000, 100000]`.
- `static String AppRoutes.payWith({String? methodId, int? amount})` → `/pos/pay`, plus `?method=<id>` and/or `&amount=<n>` when given.
- `PaymentScreen({String? initialMethodId, int? initialAmount, super.key})`: after the first frame, if `initialMethodId` matches a `paymentOptions` id it runs the existing pick (kasbon still asks for a customer), then, if `initialAmount` is given, writes it into `pay-amount`. Unknown ids are ignored. Router: `PaymentScreen(initialMethodId: q['method'], initialAmount: int.tryParse(q['amount'] ?? ''))`.
- Cart layout (`GlassCard(solid)` panel, keys kept: `sell-clear`, `sell-customer`, `sell-voucher`, `sell-bill-discount`, `sell-hold`, `sell-points`, `sell-send-kitchen`, `sell-table`, `sell-total`, `sell-pay`, `line-*`):
  - header: receipt icon tile, `cartTitle` ("Active ticket" / "Tiket aktif"), order number line when the cart has one, `StatusChip(primary)` with `sellItemsCount(n)`, Clear.
  - customer row (glass, avatar or person icon, name or `cartWalkIn` "Walk-in customer"/"Pelanggan umum", Assign → existing customer action).
  - lines: name (1 line), unit price `@ Rp x` small, 48 dp `−`/`+` steppers, line total right; tap opens the existing line menu.
  - discount/voucher/points/hold row as `SecondaryButton`s; totals rows; total card (`cartTotalDue` "Total due"/"Total tagihan", big `MoneyText`, `sell-total` key on the amount).
  - payment tiles: the first three `config.paymentOptions` as 3 equal glass tiles (icon by `TenderKind`, name), key `cart-tender-<id>`, tap → `context.go(AppRoutes.payWith(methodId: id))`.
  - quick cash: `cartQuickCash` label + chips `quickCashAmounts(due)` (first one labelled `cartExact` "Exact"/"Uang pas"), key `cart-cash-<amount>`, tap → pay with the cash option id and the amount; hidden when the store has no cash option.
  - `PrimaryButton(label: payLabel, shortcut: 'F12', expand: true, key: sell-pay)`; F12 triggers the same action via `CallbackShortcuts` on `SellScreen`.
- New l10n: `cartTitle`, `cartWalkIn`, `cartTotalDue`, `cartQuickCash`, `cartExact`, `cartPaymentMethod` ("Payment method"/"Metode pembayaran").

- [ ] **Step 1: Failing tests**: `quick_cash_test.dart` with the two examples above plus `quickCashAmounts(0)` → `[]` and `quickCashAmounts(100000)` → `[100000]`; `cart_layout_test.dart`: after adding the seeded item, tapping `cart-tender-<cash id>` lands on `/pos/pay` with the cash method selected (`pay-amount` shows `3500`); tapping `cart-cash-10000` lands with `10000` in `pay-amount`; `/pos/pay?method=nope&amount=999999999` shows the payment screen with nothing selected and no exception; F12 opens `/pos/pay`.
- [ ] **Step 2: Run** — FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** the new files and `flutter test` — PASS (sell, QRIS, kasbon, fnb flow tests must stay green unchanged).
- [ ] **Step 5: Commit** — `Redesign: cart ticket, payment tiles and quick cash`

---

### Task 4: Overview (shift dashboard)

**Files:**
- Modify: `app/lib/features/shift/presentation/shift_screen.dart`
- Create: `app/lib/features/shift/presentation/overview_widgets.dart` (`OverviewStats`, `RecentOrdersCard`, `PaymentBreakdownCard`)
- Test: `app/test/features/shift/overview_test.dart`

**Interfaces:**
- `({Money gross, int orders, Money averageBasket, Money expectedCash, Money openingCash, Money nonCash}) overviewNumbers(ShiftReport r)` — `gross = r.sales.grand`, `orders = r.sales.orders`, `averageBasket = r.sales.averageBasket`, `expectedCash = r.cash.expected`, `openingCash = r.cash.openingCash`, `nonCash` = sum of `r.payments` whose `methodType != 'cash'`.
- Layout (no `AppBar`, max width 1100, `ListView` padding 16): `PageHeader(title: shiftTitle, status: green dot + shiftOpenedBy(...), actions: the existing buttons with their keys — cash in/out and drawer as `SecondaryButton`, print X as `SecondaryButton`, close as `PrimaryButton`)`; a 4-up responsive grid (2-up < 900 px, 1-up < 600 px) of `StatCard`s: gross sales (`footnote: orders`), transactions (`footnote: average basket`), cash in drawer (`value` keeps `Key('shift-expected')`, footnote opening float), non-cash total; then a row (stacked < 900 px) of `RecentOrdersCard` (this shift's orders from `todaysOrdersProvider` where `shiftId == open.id`, newest 6, number, items, cashier, `StatusChip` status, total; tap → receipt route) and `PaymentBreakdownCard` (from `r.payments`); then the existing `ShiftReportView` in a `GlassCard(solid)`, movements and history as glass cards.
- No open shift: a centred `GlassCard` with the existing `EmptyState` and `shift-go-sell`.
- New l10n: `overviewGross`, `overviewTransactions`, `overviewCashInDrawer`, `overviewNonCash`, `overviewFloat` ("Float {amount}"/"Modal {amount}"), `overviewAverage` ("Avg. basket {amount}"/"Rata-rata {amount}"), `overviewRecent` ("Recent orders"/"Pesanan terakhir"), `overviewPayments` ("Payment breakdown"/"Rincian pembayaran").

- [ ] **Step 1: Failing tests**: `overviewNumbers` on a report built with `ShiftReport.fromJson` from the shift fixture in `packages/cashiera_core/test` (or a minimal JSON) gives the expected sums, with QRIS + card summed into `nonCash`; widget: open shift with no sales shows four stat cards and `Rp 0` values, `shift-expected` shows `Rp 200.000`; after one cash sale the recent-orders card lists its order number; no open shift shows `shift-go-sell`.
- [ ] **Step 2: Run** — FAIL. **Step 3: Implement.** **Step 4: Run** new + `flutter test` (shift flow tests unchanged) — PASS.
- [ ] **Step 5: Commit** — `Redesign: Overview shift dashboard`

---

### Task 5: Catalog table

**Files:**
- Modify: `app/lib/features/catalog/presentation/catalog_browser_screen.dart`
- Test: `app/test/features/catalog/catalog_layout_test.dart`

**Interfaces:**
- `enum StockFilter { all, low, out }`; `bool matchesStockFilter(CatalogItem i, StockFilter f)` — `low`: `trackStock && isLow`; `out`: `trackStock && stock <= Qty.zero` (use the existing `Qty` comparison); `all`: true.
- Layout (no `AppBar`): `PageHeader(title: catalogTitle, status: "<n> SKU • <m> low stock" (`catalogHeaderCount`), actions: opname (existing permission and route) as `SecondaryButton`)`; filter card: `ChipTabs` categories (existing ids) and `SegmentedTabs<StockFilter>`; `GlassTable<CatalogItem>` columns: product (`ProductThumb` 40 + name + variant), SKU / barcode, category `StatusChip`, stock (`"<qty> <unit>"`, `StockBar` vs `reorderPoint` × 3 capped, tone success/warning/error; "—" when not tracked), price (numeric). Row tap opens the existing item sheet (stock in/out keys kept); row key `catalog-item-<sku>` on the row.
- New l10n: `catalogHeaderCount` ("{count} SKUs • {low} low stock" / "{count} SKU • {low} stok menipis"), `stockFilterAll`, `stockFilterLow`, `stockFilterOut`, `catalogColProduct`, `catalogColSku`, `catalogColCategory`, `catalogColStock`, `catalogColPrice`.

- [ ] **Step 1: Failing tests**: `matchesStockFilter` truth table (tracked low, tracked out, untracked); widget at 1280×800 shows upper-case column headers and the seeded item row; tapping `catalog-item-<sku>` opens the sheet with `item-stock-in`; at 360×740 rows render as cards, no exception, 80-character product name.
- [ ] **Step 2–4** as above. **Step 5: Commit** — `Redesign: Catalog table with stock filters`

---

### Task 6: Members

**Files:**
- Modify: `app/lib/features/customers/presentation/customers_screen.dart` (list and detail)
- Test: `app/test/features/customers/members_layout_test.dart`

**Interfaces:**
- `({int members, int points, Money owed}) memberTotals(List<LocalCustomerRow> customers, Map<String, Money> owed)`; uses the list and the owed map the screen already loads.
- List (no `AppBar`): `PageHeader(title: membersTitle, subtitle: membersSubtitle, actions: [PrimaryButton add (key customer-add)])`; 3 `StatCard`s (members, points outstanding, kasbon owed); search field (`customer-search` kept) in a glass card; member cards `GlassCard` per customer (key `customer-<id>`): `InitialsAvatar`, name, phone, points (`customersPoints`) in primary, kasbon owed `StatusChip(warning)` when > 0, chevron.
- Detail (`CustomerDetailScreen`, no `AppBar`, back via a `SecondaryButton` to `/pos/customers` keyed `member-back`): profile card (avatar 64, name, phone, edit `customer-edit`), points card (balance big in primary, existing points actions `customer-points`), kasbon card (owed, `customer-pay` → existing repay dialog), recent purchases card (existing data). All existing keys kept.
- Wide (≥ 900 px content): detail cards in two columns.
- New l10n: `membersTitle` ("Members"/"Member"), `membersSubtitle` ("Points, kasbon and purchase history"/"Poin, kasbon dan riwayat belanja"), `membersCount`, `membersPoints`, `membersOwed`, `commonBack` (if absent).

- [ ] **Step 1: Failing tests**: `memberTotals` sums; list shows three stat cards and an avatar with initials for a seeded customer (create one through the existing add flow or `CustomerService`); detail opens with `member-back` returning to the list; existing customer flow tests unchanged; 80-character name no exception at 360 px.
- [ ] **Step 2–4.** **Step 5: Commit** — `Redesign: Members list and detail`

---

### Task 7: Settings

**Files:**
- Modify: `app/lib/features/printing/printer_screen.dart`
- Create: `app/lib/features/printing/settings_cards.dart` (`StoreProfileCard`, `VisualEffectsCard`, `TerminalSyncCard`)
- Test: `app/test/features/printing/settings_layout_test.dart`

**Interfaces:**
- Consumes: `visualEffectsProvider`, `visualEffectsRepositoryProvider.set(enabled:)`, `posConfigProvider` (store name, address, phone, tax name, `taxEnabled`, `paperMm`), session device code, `syncOutstandingProvider`, `onlineProvider`.
- Layout (no `AppBar`): `PageHeader(title: settingsTitle, status: green/red dot + "<device> • online/offline")`; two-column on ≥ 900 px: left `StoreProfileCard` (read-only rows) and `TerminalSyncCard` (pending count, "Open sync" `SecondaryButton` to `/sync`, key `settings-open-sync`); right the existing printer form inside `GlassCard(solid)` titled `printerTitle` (all `printer-*` keys and behaviour unchanged) and `VisualEffectsCard` (`SwitchListTile` key `settings-visual-effects`, title `settingsVisualEffects` "Visual effects"/"Efek visual", subtitle `settingsVisualEffectsHint` "Frosted blur on the top bar and dialogs. Turn off on slow tablets."/"Blur kaca di bar atas dan dialog. Matikan di tablet yang lambat.").
- New l10n: `settingsTitle`, `settingsStoreProfile`, `settingsTerminal`, `settingsOpenSync`, `settingsVisualEffects`, `settingsVisualEffectsHint`, `settingsTax` ("Tax"/"Pajak"), `settingsPaper` ("Receipt paper {mm} mm"/"Kertas struk {mm} mm").

- [ ] **Step 1: Failing tests**: switching `settings-visual-effects` off stores 0 (`VisualEffectsRepository.watch().first` is false) and removes every `BackdropFilter`; the store card shows the seeded store name and tax name; `settings-open-sync` goes to `/sync`; printer flow tests unchanged.
- [ ] **Step 2–4.** **Step 5: Commit** — `Redesign: Settings with store, printer, visual effects and sync`

---

### Task 8: Screenshots, checks, push

- [ ] **Step 1:** Extend `app/test/screenshots/` with `terminal_screens_screenshot_test.dart`: Register with two cart lines, Overview after one sale, Catalog, Members with two customers, Settings — at 1280×800 and 390×844, using the existing `shot(...)` helper and `loadFonts`.
- [ ] **Step 2:** `flutter test --run-skipped --tags screenshots --update-goldens test/screenshots` — PNGs written.
- [ ] **Step 3:** All Global Constraints checks green.
- [ ] **Step 4:** Commit `Redesign: phase 2a screenshots`, push `new-design`, send the screenshots with the list of changed existing tests.
