# Redesign Phase 3: Back Office Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restyle every back-office page, editor and dialog, and the sign-in screen, with the phase 1 design system, without changing behaviour.

**Architecture:** Pages already live inside `AdminShell` (sidebar, top bar with the page title, section tabs). Three shared pieces carry spec §4.6 for them: `AdminPage` (scrolling, max 1200 px), `AdminToolbar` (a glass card with search and filters on the left and the page's actions on the right; replaces floating action buttons) and `FormSection` (a titled solid glass card laying its fields out in two columns on wide cards). Record lists become `GlassTable`s; dialogs become `GlassDialog`s. Routes, providers, repositories and widget keys stay.

**Tech Stack:** Flutter 3.47.8 / Dart ^3.13, Riverpod 3, go_router 18, flutter_test; Playwright (pre-installed Chromium) for live screenshots.

**Spec:** `docs/superpowers/specs/2026-11-09-stitch-redesign-design.md` (§3.2, §3.3 sign-in, §4.3 back office, §4.4 back-office customers, §4.6, phase 3). Phase 2b plan: `docs/superpowers/plans/2026-11-18-redesign-phase-2b-terminal-screens.md`.

## Global Constraints

- No change to business logic, repositories, RPCs, permissions or routes.
- Every `Key('…')` literal in a file survives its restyle. Check per task: `git diff BASE -- <files> | grep -oE "^-.*Key\('[^']+" | sed "s/.*Key('//" | sort -u` must list nothing that the same command with `^+` does not also list.
- A floating action button's key moves to the toolbar `PrimaryButton` that replaces it.
- No new page titles: the shell's top bar already shows the page title, so pages do not add a `PageHeader` with the same text.
- Use the phase 1 and 2b widgets: `GlassCard`, `GlassTable`, `GlassDialog`, `showGlassSheet`, `PrimaryButton`, `SecondaryButton`, `StatCard`, `StatusChip`, `MoneyText`, `InitialsAvatar`, `ProductThumb`, `EmptyState`, `CenteredGlassPage`. Text-heavy surfaces use `GlassLevel.solid`.
- Nothing invented (spec §1 "Not in scope"); dropped mockup elements stay dropped.
- Every new string in both `app_id.arb` and `app_en.arb`.
- Checks before each push: `dart format --set-exit-if-changed`, `flutter analyze --fatal-infos`, `flutter test`, `flutter build web --release` (app), `dart test` (core).

## Review Focus

1. Phones (390 px): every page's toolbar wraps, tables become cards, editors fall to one column, nothing overflows. Covered by the live screenshots in Task 10 and the phone tests added in Tasks 3, 6, 7, 8.
2. Read-only staff (no `catalog.manage` etc.): actions that were hidden stay hidden after moving from FABs into toolbars. Tests in Tasks 4, 7.
3. Empty, loading and error states keep their messages inside a glass card (not a bare centred text on the background). Rule in Task 1 (`AdminPage` empty/error slots), checked in screenshots.
4. Long editors (promotion, product, store settings) keep their Save button reachable and their validation messages visible after the two-column layout. Tests in Tasks 5, 7, 8.
5. Dialogs on a short screen with the keyboard up scroll rather than overflow. Test in Task 9.

---

### Task 1: Shared back-office pieces

**Files:**
- Create: `app/lib/core/design_system/widgets/admin.dart`
- Test: `app/test/core/design_system/admin_widgets_test.dart`

**Interfaces:**
- `class AdminPage extends StatelessWidget { const new({required List<Widget> children, Widget? toolbar, double maxWidth = 1200, Key? key}) }`: transparent `Scaffold`, top-centred `ConstrainedBox(maxWidth)`, `ListView(padding: AppSpacing.lg)` with the toolbar first, then `AppSpacing.lg`, then `children`.
- `class AdminToolbar extends StatelessWidget { const new({List<Widget> filters = const [], List<Widget> actions = const [], Key? key}) }`: a `GlassCard(padding: AppSpacing.md)`; filters in a `Wrap`, actions in a `Wrap` aligned right; actions go under the filters below 720 px. Renders nothing when both lists are empty.
- `class FormSection extends StatelessWidget { const new({required String title, required List<Widget> children, String? subtitle, Key? key}) }`: `GlassCard(level: solid)` with `titleMedium` title, muted subtitle, then the children; at card width ≥ 720 px children are laid out two per row (each `(width − AppSpacing.lg) / 2`), below that one per row. A child wrapped in `FormSection.full(child)` always takes the whole row.
- `Widget adminMessage({required IconData icon, required String message, Widget? action})`: `GlassCard(child: EmptyState(...))`, for empty and error states.

- [ ] **Step 1: Failing tests**: `AdminToolbar` at 1280 puts an action to the right of a filter (action x > filter x + 300) and at 390 below it (action y > filter y); `FormSection` with four `SizedBox(height: 40)` children shows two per row at 1000 px (two distinct x positions) and one per row at 390 px (one x position), and a `FormSection.full` child spans the row; `AdminPage` at 390×640 with 30 rows scrolls without an exception.
- [ ] **Step 2: Run** `flutter test test/core/design_system/admin_widgets_test.dart`. Expected: FAIL (`admin.dart` missing).
- [ ] **Step 3: Implement** as in Interfaces.
- [ ] **Step 4: Run** the new tests and `flutter test`. Expected: PASS.
- [ ] **Step 5: Commit**: `Redesign: back-office page, toolbar and form section`

---

### Task 2: Sign-in and the Overview home

**Files:**
- Modify: `app/lib/features/back_office/presentation/sign_in_screen.dart`, `back_office_home_screen.dart`, `app/lib/features/reports/presentation/dashboard_panel.dart`
- Test: extend `app/test/features/reports/reports_test.dart`; add `app/test/features/back_office/sign_in_layout_test.dart`

**Interfaces:**
- Sign-in: `CenteredGlassPage(maxWidth: 440)` with `AppLogoTile`, title, email and password fields, `PrimaryButton(expand: true)` keeping the existing submit key; no `AppBar`.
- Home: `AdminPage`; the principal card (avatar, name, role · stores) as a `GlassCard`; store rows as glass cards with their pairing-code action (`SecondaryButton`, existing keys).
- Dashboard panel: the "Today" numbers as `StatCard`s (net sales, sales, average, each with its yesterday footnote), open shifts and low stock as `StatusChip`-style pills, the 7-day chart, top products and payments in `GlassCard(solid)`; store picker and All reports link kept.

- [ ] **Step 1: Failing tests**: sign-in pumped alone shows no `AppBar` and its email field inside a `GlassCard`; at 390×640 no exception. In `reports_test`, the dashboard panel shows three `StatCard`s.
- [ ] **Step 2–4.** Existing reports tests pass unchanged.
- [ ] **Step 5: Commit**: `Redesign: back-office sign-in and overview home`

---

### Task 3: Reports, shifts and audit log

**Files:**
- Modify: `app/lib/features/reports/presentation/{reports_screen,report_widgets,report_tables}.dart`, `app/lib/features/back_office/presentation/{admin_shifts_screen,audit_screen}.dart`
- Test: extend `reports_test.dart` and `shift_audit_screens_test.dart`

**Interfaces:**
- Reports: `AdminPage` with an `AdminToolbar` holding the period picker, store picker and PDF/Excel export (existing keys); report tabs as `ChipTabs`-styled chips over the existing tab state; every `DataTable` becomes a `GlassTable` with the same columns and totals row text.
- Shifts: `AdminToolbar` (store, date filters); shifts in a `GlassTable` (shift, terminal, opened, closed, cashier, difference as `StatusChip` toned like close shift). Shift report detail in a `solid` card with its actions.
- Audit: `AdminToolbar` (filters, existing keys); entries in a `GlassTable` (time, who, action chip, entity, detail); paging control kept below the table.

- [ ] **Step 1: Failing tests**: reports, shifts and audit each render a `GlassTable` and no `DataTable`/`Card`; the shifts list at 390 px raises no exception.
- [ ] **Step 2–4.** Existing report, shift and audit tests pass unchanged (cell texts are the same).
- [ ] **Step 5: Commit**: `Redesign: reports, shifts and audit log`

---

### Task 4: Catalog lists (products, categories, suppliers, stock)

**Files:**
- Modify: `app/lib/features/back_office/presentation/{products,categories,suppliers,stock}_screen.dart`
- Test: add `app/test/features/back_office/catalog_lists_layout_test.dart` (the rule test for this task: reads the four files and fails if they contain `FloatingActionButton`, `Card(` or `ListTile(` as a row container); extend `catalog_files_test.dart` only if it pumps these screens

**Interfaces:**
- Products: toolbar filters (search, category dropdown), action `PrimaryButton(key: product-new)` only with `catalog.manage` (as the FAB today); `GlassTable` (product with `ProductThumb` 40 + name, category chip, variants, price range numeric, status chip active/inactive); read-only notice as a muted line in the toolbar.
- Categories and suppliers: toolbar with the add action (existing key, same permission); `GlassTable` rows (name, colour dot / contact, product count where shown today, status chip); edit and delete actions kept in the last column.
- Stock: toolbar (store, search, low-stock filter as today); `GlassTable` (product, SKU, on hand with `StockBar` like the terminal catalog, reorder point, value numeric); adjust action kept.

- [ ] **Step 1: Failing test**: the rule test above.
- [ ] **Step 2–4.** All back-office tests pass unchanged.
- [ ] **Step 5: Commit**: `Redesign: products, categories, suppliers and stock lists`

---

### Task 5: Product editor and import

**Files:**
- Modify: `app/lib/features/back_office/presentation/{product_editor_screen,import_screen}.dart`
- Test: extend `import_preview_test.dart`; add `app/test/features/back_office/editor_layout_test.dart` (rule test for the two files)

**Interfaces:**
- Product editor: `AdminPage` with a toolbar holding Back (to the products list, `SecondaryButton`, key `product-editor-back`) and Save (`PrimaryButton`, existing key); `FormSection`s: Basics (name, category, unit, type), Prices & tax, Stock, Variants (`FormSection.full` table of variants with existing add/remove keys), Kitchen station (F&B).
- Import: toolbar with Download template and Choose file (existing keys); the preview's problems in a `GlassTable` (row, column, problem), totals as `StatCard`s (rows, valid, problems); Import `PrimaryButton` disabled until clean (as today).

- [ ] **Step 1: Failing tests**: the rule test (no `Card(`, `FloatingActionButton` in the two files); in `import_preview_test`, the preview shows a `GlassTable`.
- [ ] **Step 2–4.** Existing import tests pass unchanged.
- [ ] **Step 5: Commit**: `Redesign: product editor and import`

---

### Task 6: Purchasing and transfers

**Files:**
- Modify: `app/lib/features/back_office/presentation/{purchase_orders_screen,purchasing_widgets,transfers_screen}.dart`
- Test: extend `purchasing_screens_test.dart`

**Interfaces:**
- Lists: toolbar (status filter, store, new action with its existing key and permission); `GlassTable` (number, supplier or route, date, items, status `StatusChip` (draft neutral, ordered primary, partial warning, received success, cancelled error), total numeric).
- Detail screens (`PurchaseOrderScreen`, `TransferScreen`): toolbar with Back and the status actions (existing keys); header facts in a `FormSection`; lines as a `GlassTable` with the existing quantity fields and keys; receive and send dialogs move in Task 9.

- [ ] **Step 1: Failing tests**: the PO and transfer detail screens show no `Card` and a `GlassTable`; the PO detail at 390×740 raises no exception.
- [ ] **Step 2–4.** Existing purchasing tests pass unchanged.
- [ ] **Step 5: Commit**: `Redesign: purchasing and transfers`

---

### Task 7: Sales (promotions, promotion editor, vouchers, QRIS payments)

**Files:**
- Modify: `app/lib/features/back_office/presentation/{promotions_screen,promotion_editor_screen,vouchers_screen,gateway_payments_screen}.dart`
- Test: extend `promotion_editor_test.dart`; add `app/test/features/back_office/sales_layout_test.dart` (rule test for the four files)

**Interfaces:**
- Promotions list: toolbar with the new action (existing key, `promotion.manage`); `GlassTable` (priority, name, type, schedule, stores, status chip).
- Promotion editor: toolbar Back + Save (existing keys); `FormSection`s: Details, Rules (type-specific fields as today, `FormSection.full` for tier and bundle tables), Schedule, Stores; validation messages unchanged.
- Vouchers: toolbar (search, new action with existing key); `GlassTable` (code, value, used / limit, validity, status chip).
- QRIS payments: toolbar (store, date); `GlassTable` (time, order, amount, gateway status `StatusChip`: paid success, pending warning, failed/expired/cancelled error).

- [ ] **Step 1: Failing tests**: the rule test; the promotion editor at 1280 shows its Save button and at least two `FormSection`s, and at 390×740 raises no exception.
- [ ] **Step 2–4.** Existing promotion tests pass unchanged.
- [ ] **Step 5: Commit**: `Redesign: promotions, vouchers and QRIS payments`

---

### Task 8: Members and settings

**Files:**
- Modify: `app/lib/features/back_office/presentation/{admin_customers_screen,admin_kasbon_screen,loyalty_settings_screen,store_settings_screen,dining_tables_screen}.dart`
- Test: extend `customers_admin_test.dart`; add `app/test/features/back_office/settings_layout_test.dart` (rule test for the five files)

**Interfaces:**
- Customers: toolbar (search, add with existing key); `GlassTable` (`InitialsAvatar` + name, phone, points, kasbon owed `StatusChip` warning when > 0); customer detail as `FormSection`s (profile, points, kasbon) like the terminal member detail.
- Kasbon: the total owed as a `StatCard` (existing key `admin-kasbon-total` on its value via `valueKey`); `GlassTable` of open kasbon (customer, order, due, left, overdue chip).
- Loyalty and store settings: `FormSection`s (Loyalty: earning, redeeming; Store: profile, tax, service charge, cashier, receipt, payment methods as a `FormSection.full` list of switches); Save `PrimaryButton` in the toolbar with existing keys.
- Dining tables: toolbar add action; `GlassTable` (name, area, seats, status chip).

- [ ] **Step 1: Failing tests**: the rule test; `admin-kasbon-total` sits inside a `StatCard`; store settings at 1280 lays its tax fields side by side and at 390×740 raises no exception.
- [ ] **Step 2–4.** Existing customer, kasbon and loyalty tests pass unchanged.
- [ ] **Step 5: Commit**: `Redesign: back-office customers, kasbon, loyalty, settings and tables`

---

### Task 9: Back-office dialogs on glass

**Files:**
- Modify: every `AlertDialog(` and `showModalBottomSheet` under `app/lib/features/back_office/` and `app/lib/features/reports/`
- Test: `app/test/features/back_office/glass_rule_test.dart`

**Interfaces:**
- As phase 2b Task 7: `AlertDialog` → `GlassDialog` with scrolling content, `showModalBottomSheet` → `showGlassSheet`; keys and buttons kept.
- Rule test: no `AlertDialog(`, `showModalBottomSheet`, `FloatingActionButton` or `Card(` remains in `lib/features/back_office/` and `lib/features/reports/`.

- [ ] **Step 1: Failing test**: the rule test (fails, naming the files), plus a category dialog opened from the categories page at 360×640 with `viewInsets.bottom` 300 raising no exception (pump with the repository fake the categories tests use, or a minimal fake of `adminCategoriesProvider`).
- [ ] **Step 2–4.** All tests pass.
- [ ] **Step 5: Commit**: `Redesign: back-office dialogs on frosted glass`

---

### Task 10: Live screenshots, checks, push

- [ ] **Step 1:** Build the web app against the demo project: `flutter build web --release --no-web-resources-cdn --dart-define=SUPABASE_URL=… --dart-define=SUPABASE_ANON_KEY=…` (the values the owner gave), serve `build/web`.
- [ ] **Step 2:** A Playwright script in the scratchpad signs in as the demo owner and opens every back-office route (all tabs of the five sections, one product editor, one promotion editor) plus the sign-in screen, at 1280×800 and 390×844, saving a PNG per page and logging failed requests and console errors. It only reads.
- [ ] **Step 3:** Look at every PNG; fix what overflows or breaks the rules above, with a test where a widget test can reproduce it.
- [ ] **Step 4:** All Global Constraints checks green; commit `Redesign: phase 3 finishing touches` if Step 3 changed code; push the working branch; send the screenshots.
