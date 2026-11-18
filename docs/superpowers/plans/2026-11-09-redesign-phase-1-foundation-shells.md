# Redesign Phase 1: Foundation and Shells Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace CashierA's two themes with the Stitch "Radiant Light White Glass" design system and put every terminal and back-office page inside new five-item shells.

**Architecture:** New tokens and one light `ThemeData` drive plain Material widgets; a small set of glass widgets in `core/design_system/widgets/` gives the Stitch look. A `TerminalShell` (`ShellRoute` over `/pos/*` and `/sync`) and a rewritten `AdminShell` own navigation; nav state is derived from the route by pure functions so it is unit-testable. Screens themselves are restyled in phases 2 and 3; in this phase they render inside the new shells with their existing bodies.

**Tech Stack:** Flutter 3.47.8 / Dart ^3.13 (primary-constructor syntax `const new(...)` is used project-wide), Riverpod 3 with codegen, go_router 18, Drift, flutter_test.

**Spec:** `docs/superpowers/specs/2026-11-09-stitch-redesign-design.md` (sections 2, 3, 5, 6 and phase 1 of 7)

## Global Constraints

- Only look, layout and navigation change; no change to business logic, database schema, sync, pricing, printing or permissions.
- Routes stay as they are; the only routing change is `/pos` redirecting to `/pos/sell`.
- Widget keys used by tests are kept.
- One light theme for terminals and back office; the dark POS theme is removed.
- Colors: primary `#E11D48`, pressed `#BE123C`, primarySoft `#FFF1F2`, success `#10B981`, warning `#F59E0B` / soft `#FEF3C7` / text `#D97706`, error `#EF4444`, text `#0F172A`, textStrong `#020617`, textSecondary `#334155`, textMuted `#64748B`, hairline `#E2E8F0`.
- Background gradient `#FFF1F2 → #FDF2F8 → #F5F3FF` with five glows at 35–45 % opacity, painted once, no blur filter.
- Real blur (`BackdropFilter`, sigma 20) only on the top bar, dialogs and sheets; terminals can switch it off ("Visual effects", default on); back office always on.
- Fonts: Plus Jakarta Sans (headings, body, numbers) and Inter (labels, chips, table headers, buttons), both bundled; money, quantities and codes use tabular figures.
- Radius: card 24, tile 20, control 14, small 8, pill 999. Touch targets ≥ 48 dp.
- Terminal sidebar: Register & Checkout, Overview, Catalog, Members, Settings. Back-office sidebar: Overview, Catalog, Sales, Members, Settings.
- Every new user-facing string goes into both `app_id.arb` and `app_en.arb`; Indonesian stays default.
- Checks before every push: `dart format --output=none --set-exit-if-changed lib test`, `flutter analyze --fatal-infos`, `flutter test`, `flutter build web --release` (in `app/`), and `dart test` in `packages/cashiera_core`.

## Review Focus

1. Visual effects switched off: no `BackdropFilter` may remain anywhere in the terminal shell (top bar, dialogs, sheets). Test in Task 2 and Task 4.
2. Phone width (360×740): neither shell may overflow; the terminal shows the bottom bar, the back office the drawer. Tests in Task 4 and Task 5.
3. Kitchen pill: hidden unless F&B mode is on **and** the staff member has `kitchen.view`. Test in Task 4.
4. Held Orders count: no badge at 0, the number from 1 to 99, `99+` above. Test in Task 4.
5. Existing flow tests now render inside a 240 px sidebar: screens that choose layout from `MediaQuery` width (sell's 900 px two-pane rule) must use the width they actually get. Task 4 switches sell to `LayoutBuilder` and runs the full suite.

---

### Task 0: Toolchain and baseline (no commit)

- [ ] **Step 1: Install Flutter 3.47.8**

```bash
cd /root && curl -sSLO https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.47.8-stable.tar.xz && tar xf flutter_linux_3.47.8-stable.tar.xz && rm flutter_linux_3.47.8-stable.tar.xz
export PATH=/root/flutter/bin:$PATH && flutter --version
```

Expected: `Flutter 3.47.8 • channel stable`.

- [ ] **Step 2: Baseline checks**

```bash
cd /home/user/CashierA/packages/cashiera_core && dart pub get && dart test
cd /home/user/CashierA/app && flutter pub get && flutter analyze --fatal-infos && flutter test
```

Expected: core and app tests all pass, analyzer clean. Record the counts; any pre-existing failure is reported to the owner before Task 1, not fixed silently.

---

### Task 1: Tokens, light theme and fonts

**Files:**
- Modify: `app/lib/core/design_system/tokens.dart` (replace `AppColors`, `AppRadius`; add `AppFonts`, `AppTypography`; keep `AppSpacing`, `AppMotion`, `AppSizes.minTouch`, `BreakpointContext`)
- Modify: `app/lib/core/design_system/theme.dart`
- Modify: `app/pubspec.yaml` (fonts)
- Create: `app/assets/fonts/Inter-Regular.ttf`, `Inter-Medium.ttf`, `Inter-SemiBold.ttf`, `Inter-Bold.ttf`, `app/assets/fonts/Inter-LICENSE.md`
- Modify: every `AppTheme.pos()` / `AppTheme.backOffice()` call (8 call sites in `lib/app/app.dart` and `test/`)
- Test: `app/test/core/design_system/theme_test.dart`

**Interfaces:**
- Produces: `AppColors.{primary, primaryPressed, primarySoft, success, warning, warningSoft, warningText, error, text, textStrong, textSecondary, textMuted, hairline}`; `AppRadius.{card=24, tile=20, control=14, small=8, pill=999}`; `AppFonts.{body='PlusJakartaSans', label='Inter'}`; `AppTypography.tabular` (a `List<FontFeature>` with `FontFeature.tabularFigures()`); `AppTheme.light() -> ThemeData`.

- [ ] **Step 1: Write the failing test**

```dart
void main() {
  final theme = AppTheme.light();
  test('palette and fonts follow the Stitch design', () {
    expect(theme.brightness, Brightness.light);
    expect(theme.colorScheme.primary, const Color(0xFFE11D48));
    expect(theme.colorScheme.secondary, const Color(0xFF10B981));
    expect(theme.colorScheme.error, const Color(0xFFEF4444));
    expect(theme.colorScheme.onSurface, const Color(0xFF0F172A));
    expect(theme.textTheme.bodyMedium!.fontFamily, 'PlusJakartaSans');
    expect(theme.textTheme.labelLarge!.fontFamily, 'Inter');
    // The page background is painted by AppBackground, not the scaffold.
    expect(theme.scaffoldBackgroundColor, Colors.transparent);
  });
  test('controls keep 48 dp touch targets and 14 px corners', () {
    final style = theme.filledButtonTheme.style!;
    expect(style.minimumSize!.resolve({}), const Size(48, 48));
    final shape = style.shape!.resolve({})! as RoundedRectangleBorder;
    expect(shape.borderRadius, BorderRadius.circular(14));
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/core/design_system/theme_test.dart` — Expected: FAIL, `light` is not defined.

- [ ] **Step 3: Add the Inter font files**

```bash
cd /tmp && npm pack inter-font@3.19.0 --silent && tar xzf inter-font-3.19.0.tgz
cp package/ttf/Inter-{Regular,Medium,SemiBold,Bold}.ttf /home/user/CashierA/app/assets/fonts/
cp package/LICENSE.md /home/user/CashierA/app/assets/fonts/Inter-LICENSE.md
```

Register family `Inter` in `pubspec.yaml` with weights 400/500/600/700 next to `PlusJakartaSans`.

- [ ] **Step 4: Implement tokens and `AppTheme.light()`**

Remove the `pos*`/`admin*` colors and `AppTheme.pos()`/`backOffice()`. The color scheme uses the Global Constraints values (surface white, `outline`/`outlineVariant` = hairline, `onSurfaceVariant` = textMuted, `primaryContainer` = primarySoft). Text theme: Plus Jakarta Sans for display/headline/title/body with the spec 2.4 scale; Inter for `label*`. Cards: white at 72 % alpha, 1 px white border at 60 %, radius 24, elevation 0. Inputs: white fill, hairline border, 2 px primary focus border, radius 14. Filled buttons primary, radius 14, Inter w600; outlined buttons white fill with hairline border. Chips pill-shaped. Dialogs and bottom sheets white at 92 % with radius 24. Navigation-rail/drawer themes are not needed (shells draw their own). Replace every `AppTheme.pos()` and `AppTheme.backOffice()` call with `AppTheme.light()`.

- [ ] **Step 5: Run tests**

Run: `flutter test` — Expected: the new test passes; the whole suite still passes (existing tests do not assert colors; fix any that do by asserting the token instead of a literal).

- [ ] **Step 6: Commit**

```bash
git add app/lib/core/design_system app/pubspec.yaml app/assets/fonts app/lib/app/app.dart app/test
git commit -m "Redesign: Stitch tokens, single light theme and bundled Inter"
```

---

### Task 2: Background, glass surfaces and the Visual effects setting

**Files:**
- Create: `app/lib/core/design_system/widgets/app_background.dart`
- Create: `app/lib/core/design_system/widgets/glass.dart` (`GlassCard`, `GlassPill`, `GlassBlur`, `GlassDialog`, `showGlassSheet`)
- Create: `app/lib/core/design_system/visual_effects.dart` (repository + provider)
- Test: `app/test/core/design_system/glass_test.dart`

**Interfaces:**
- Produces:
  - `AppBackground({required Widget child})` — gradient + five glows in a `RepaintBoundary`, child on top.
  - `enum GlassLevel { subtle, regular, solid }` with white alphas 0.45 / 0.72 / 0.92.
  - `GlassCard({required Widget child, GlassLevel level = GlassLevel.regular, EdgeInsetsGeometry padding = const EdgeInsets.all(AppSpacing.xl), double radius = AppRadius.card, VoidCallback? onTap})`.
  - `GlassPill({required Widget child, Color? tint, VoidCallback? onTap, Key? key})` — 40 dp high, pill radius, min touch 48 via padding hit area.
  - `GlassBlur({required Widget child, required BorderRadius borderRadius})` — wraps `child` in `ClipRRect` + `BackdropFilter(ImageFilter.blur(sigmaX: 20, sigmaY: 20))` when `visualEffectsProvider` is true, otherwise returns `child` unchanged.
  - `GlassDialog({required Widget title, required Widget content, List<Widget> actions = const []})` and `Future<T?> showGlassSheet<T>(BuildContext, {required WidgetBuilder builder})`, both using `GlassBlur`.
  - `VisualEffectsRepository(AppDatabase db)` with `Stream<bool> watch()` and `Future<void> set({required bool enabled})`, stored in `LocalCounters` under name `ui.visual_effects` (1 on, 0 off, missing = on). No schema change.
  - `@Riverpod(keepAlive: true) Stream<bool> visualEffects(Ref ref)` (generated `visualEffectsProvider`); on web it yields `true` without touching the database.

- [ ] **Step 1: Write the failing tests**

```dart
testWidgets('GlassBlur blurs only while visual effects are on', (t) async {
  for (final on in [true, false]) {
    await t.pumpWidget(ProviderScope(
      overrides: [visualEffectsProvider.overrideWith((ref) => Stream.value(on))],
      child: const MaterialApp(home: GlassBlur(
        borderRadius: BorderRadius.zero, child: SizedBox(width: 10, height: 10))),
    ));
    await t.pump();
    expect(find.byType(BackdropFilter), on ? findsOneWidget : findsNothing);
  }
});

test('visual effects default on and persist off', () async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final repo = VisualEffectsRepository(db);
  expect(await repo.watch().first, isTrue);
  await repo.set(enabled: false);
  expect(await repo.watch().first, isFalse);
});

testWidgets('AppBackground paints no blur filter', (t) async {
  await t.pumpWidget(const MaterialApp(home: AppBackground(child: SizedBox())));
  expect(find.byType(BackdropFilter), findsNothing);
  expect(find.byType(RepaintBoundary), findsWidgets);
});
```

- [ ] **Step 2: Run to verify they fail** — `flutter test test/core/design_system/glass_test.dart`; Expected: FAIL (undefined names).

- [ ] **Step 3: Implement** the files above. The glows are `RadialGradient` circles (transparent at the edge) at the Stitch positions: top-left (`#FBCFE8`→`#F472B6`, 45 %), right (`#FDA4AF`→`#E0E7FF`, 45 %), bottom (`#DDD6FE`→`#FED7AA`, 40 %), centre (`#FECDD3`→`#FEE2E2`, 35 %), bottom-right (`#FDA4AF`→`#C4B5FD`, 35 %), sized relative to the shortest side. `GlassCard` = `DecoratedBox` (white at level alpha, 1 px white border at 60 %, shadow `0 10 30` `#0F172A` at 8 %) plus a 1 px top highlight line; `InkWell` when `onTap` is set. Run `dart run build_runner build -d` for the provider.

- [ ] **Step 4: Run tests** — same command; Expected: PASS.

- [ ] **Step 5: Commit** — `git commit -m "Redesign: background, glass surfaces and visual effects setting"`

(The on/off switch itself is placed on the terminal Settings screen in phase 2, which calls `VisualEffectsRepository.set`.)

---

### Task 3: Controls and data-display widgets

**Files:**
- Create: `app/lib/core/design_system/widgets/buttons.dart` (`PrimaryButton`, `SecondaryButton`)
- Create: `app/lib/core/design_system/widgets/inputs.dart` (`SearchScanField`, `ChipTabs`, `SegmentedTabs`)
- Create: `app/lib/core/design_system/widgets/data_display.dart` (`PageHeader`, `StatCard`, `StatusChip`, `StockBar`, `MoneyText`, `InitialsAvatar`, `ProductThumb`)
- Create: `app/lib/core/design_system/widgets/glass_table.dart` (`GlassTable`, `GlassColumn`)
- Modify: `app/lib/core/design_system/widgets/empty_state.dart`, `pin_pad.dart`, `sync_status_chip.dart`, `toasts.dart` (tokens only; public APIs unchanged)
- Test: `app/test/core/design_system/controls_test.dart`

**Interfaces:**
- Produces:
  - `PrimaryButton({required String label, required VoidCallback? onPressed, IconData? icon, String? shortcut, bool expand = false, Key? key})` — rose gradient `#E11D48`→`#BE123C`, rose glow shadow, 48 dp min, shortcut badge (e.g. `F12`) on the right.
  - `SecondaryButton({required String label, required VoidCallback? onPressed, IconData? icon, Key? key})` — white glass, hairline border.
  - `SearchScanField({required ValueChanged<String> onChanged, ValueChanged<String>? onSubmitted, String? hint, String? shortcut, TextEditingController? controller, Key? key})` — 48 dp, search icon leading, barcode icon trailing.
  - `ChipTabs<T>({required List<(T, String)> items, required T selected, required ValueChanged<T> onSelected, Key? key})` — horizontal scroll; selected chip filled primary (category style) — also used for page tabs.
  - `SegmentedTabs<T>` — same signature; white glass track, selected segment white with shadow (Today / Yesterday / This week).
  - `PageHeader({required String title, String? subtitle, Widget? status, List<Widget> actions = const []})` — glass card; actions wrap below the title under 720 px.
  - `StatCard({required IconData icon, required String label, required String value, Color tint = AppColors.primary, String? badge, String? footnote})`.
  - `enum StatusTone { success, warning, error, neutral, primary }`; `StatusChip({required String label, StatusTone tone = StatusTone.neutral})`.
  - `StockBar({required double fraction, required StatusTone tone})` — fraction clamped to 0..1.
  - `MoneyText(Money amount, {TextStyle? style})` — text is `amount.format()` (`Rp 25.000`, from `cashiera_core`), tabular figures.
  - `InitialsAvatar({required String name, double size = 48})` — up to two initials, tint derived from `name.hashCode`, `?` for blank names.
  - `ProductThumb({required String name, String? imageUrl, double size = 96})` — `Image.network` with `errorBuilder` and a null/empty URL both falling back to an initials tile.
  - `GlassColumn<T>({required String label, required Widget Function(T) cell, int flex = 1, bool numeric = false})`; `GlassTable<T>({required List<GlassColumn<T>> columns, required List<T> rows, void Function(T)? onRowTap, Key? key})` — uppercase Inter headers, 64 dp rows, hairline rules; under 600 px renders each row as a `GlassCard` listing `label: cell`.

- [ ] **Step 1: Write the failing tests**

```dart
testWidgets('InitialsAvatar takes up to two initials', (t) async {
  await t.pumpLocalized(const InitialsAvatar(name: 'Amanda Pratiwi'));
  expect(find.text('AP'), findsOneWidget);
  await t.pumpLocalized(const InitialsAvatar(name: '  '));
  expect(find.text('?'), findsOneWidget);
});
testWidgets('ProductThumb falls back to initials without an image', (t) async {
  await t.pumpLocalized(const ProductThumb(name: 'Kopi Susu'));
  expect(find.text('KS'), findsOneWidget);
  expect(find.byType(Image), findsNothing);
});
testWidgets('PrimaryButton shows its shortcut and keeps 48 dp', (t) async {
  await t.pumpLocalized(PrimaryButton(label: 'Bayar', shortcut: 'F12', onPressed: () {}));
  expect(find.text('F12'), findsOneWidget);
  expect(t.getSize(find.byType(PrimaryButton)).height, greaterThanOrEqualTo(48));
});
testWidgets('GlassTable becomes cards on phones', (t) async {
  t.view..physicalSize = const Size(360, 740)..devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpLocalized(GlassTable<String>(
    columns: [GlassColumn(label: 'Produk', cell: Text.new)], rows: const ['Teh']));
  expect(find.text('PRODUK'), findsNothing);
  expect(find.byType(GlassCard), findsOneWidget);
});
test('StockBar clamps its fraction', () {
  expect(const StockBar(fraction: 1.7, tone: StatusTone.success).clampedFraction, 1);
  expect(const StockBar(fraction: -1, tone: StatusTone.error).clampedFraction, 0);
});
```

(`pumpLocalized` in `test/helpers/pump_app.dart` now uses `AppTheme.light()`; expose `StockBar.clampedFraction` as a getter.)

- [ ] **Step 2: Run to verify they fail** — `flutter test test/core/design_system/controls_test.dart`; Expected: FAIL.
- [ ] **Step 3: Implement** the widgets with the signatures above; restyle the four existing widgets to the tokens without changing their constructors.
- [ ] **Step 4: Run** the new file and `test/core/design_system/widgets_test.dart`; Expected: PASS.
- [ ] **Step 5: Commit** — `git commit -m "Redesign: buttons, inputs, tables and data-display widgets"`

---

### Task 4: Terminal shell

**Files:**
- Create: `app/lib/app/shell/terminal_nav.dart` (pure nav model)
- Create: `app/lib/app/shell/terminal_shell.dart` (`TerminalShell`, sidebar, top bar, bottom bar)
- Create: `app/lib/app/shell/terminal_search.dart` (`terminalSearchQueryProvider`)
- Modify: `app/lib/app/router.dart` (ShellRoute; `/pos` redirect)
- Modify: `app/lib/app/app.dart` (`AppBackground` via `MaterialApp.router(builder:)`)
- Modify: `app/lib/features/sell/presentation/sell_screen.dart` (two-pane rule from `LayoutBuilder` width)
- Modify: screens that embed `TerminalStatusChip` in their own app bar (`opname_screen`, `catalog_browser_screen`, `shift_screen`, `sync_screen`, `customers_screen`, `orders_screen`, `sell_screen`): remove it there (the shell shows it); keep it on `pin_lock_screen`.
- Delete: `app/lib/features/pos_home/presentation/pos_home_screen.dart`
- Modify: `app/lib/core/l10n/arb/app_id.arb`, `app_en.arb`
- Test: `app/test/app/terminal_nav_test.dart`, `app/test/app/terminal_shell_test.dart`

**Interfaces:**
- Consumes: Tasks 1–3 widgets; `heldOrdersProvider`, `posConfigProvider` (`fnbMode`), `sessionControllerProvider` (`device.deviceCode`, `staff.fullName`, `staff.can`, `store.store.name`), `TerminalStatusChip`, `SessionController.lock()`.
- Produces:
  - `enum TerminalSection { register, overview, catalog, members, settings }` with `String get route` = `/pos/sell`, `/pos/shift`, `/pos/catalog`, `/pos/customers`, `/pos/printer`.
  - `TerminalSection? terminalSectionFor(String location)`: `/pos/sell`, `/pos/pay`, `/pos/receipt/*`, `/pos/refund/*`, `/pos/orders`, `/pos/tables` → register; `/pos/shift*` → overview; `/pos/catalog`, `/pos/opname` → catalog; `/pos/customers*` → members; `/pos/printer`, `/sync` → settings; `/pos/kitchen` → null.
  - `bool showsSearch(String location)` — true for `/pos/sell` and `/pos/catalog`.
  - `String heldBadge(int count)` — `''` for ≤ 0, the number up to 99, `'99+'` above.
  - `terminalSearchQueryProvider` — Riverpod `Notifier<String>` with `set(String)`; read by Register and Catalog in phase 2.
  - `TerminalShell({required Widget child})`. Keys: `terminal-nav-<section.name>`, `terminal-held-orders`, `terminal-kitchen`, `terminal-lock`, `terminal-sidebar-toggle`, `terminal-bottom-bar`.
  - New l10n keys: `navRegister`, `navOverview`, `navCatalog`, `navMembers`, `navSettings`, `shellRetailPos`, `shellHeldOrders`, `shellKitchen`, `shellLock`, `shellCollapse`, `shellExpand`.

- [ ] **Step 1: Write the failing pure tests** (`terminal_nav_test.dart`)

```dart
test('routes map to the five sidebar sections', () {
  expect(terminalSectionFor('/pos/sell'), TerminalSection.register);
  expect(terminalSectionFor('/pos/receipt/abc'), TerminalSection.register);
  expect(terminalSectionFor('/pos/orders'), TerminalSection.register);
  expect(terminalSectionFor('/pos/shift/close'), TerminalSection.overview);
  expect(terminalSectionFor('/pos/opname'), TerminalSection.catalog);
  expect(terminalSectionFor('/pos/customers/c-1'), TerminalSection.members);
  expect(terminalSectionFor('/sync'), TerminalSection.settings);
  expect(terminalSectionFor('/pos/kitchen'), isNull);
});
test('held badge', () {
  expect(heldBadge(0), '');
  expect(heldBadge(7), '7');
  expect(heldBadge(100), '99+');
});
test('search only on Register and Catalog', () {
  expect(showsSearch('/pos/sell'), isTrue);
  expect(showsSearch('/pos/catalog'), isTrue);
  expect(showsSearch('/pos/shift'), isFalse);
});
```

- [ ] **Step 2: Write the failing widget tests** (`terminal_shell_test.dart`, using `openTill` from `test/support/till_harness.dart`, which lands on `/pos/sell` with a shift open)

```dart
testWidgets('five sidebar items, Register selected, navigation works', (t) async {
  final (_, c) = await openTill(t, const Size(1280, 800));
  for (final s in TerminalSection.values) {
    expect(find.byKey(Key('terminal-nav-${s.name}')), findsOneWidget);
  }
  await tapKey(t, 'terminal-nav-overview');
  expect(c.read(routerProvider).state.matchedLocation, '/pos/shift');
});
testWidgets('/pos redirects to Register', (t) async {
  final (_, c) = await openTill(t, const Size(1280, 800));
  await go(t, c, '/pos');
  expect(c.read(routerProvider).state.matchedLocation, '/pos/sell');
});
testWidgets('kitchen pill needs F&B mode and kitchen.view', (t) async {
  await openTill(t, const Size(1280, 800)); // cashier, F&B off
  expect(find.byKey(const Key('terminal-kitchen')), findsNothing);
});
testWidgets('kitchen pill shows for kitchen staff in F&B mode', (t) async {
  await openTill(t, const Size(1280, 800),
      staff: cashier.copyWith(permissions: {...cashier.permissions, 'kitchen.view'}),
      overrides: [fnbModeOverride(on: true)]);
  expect(find.byKey(const Key('terminal-kitchen')), findsOneWidget);
});
testWidgets('visual effects off leaves no blur in the shell', (t) async {
  await openTill(t, const Size(1280, 800),
      overrides: [visualEffectsProvider.overrideWith((ref) => Stream.value(false))]);
  expect(find.byType(BackdropFilter), findsNothing);
});
testWidgets('phone: bottom bar, no overflow', (t) async {
  await openTill(t, const Size(360, 740));
  expect(t.takeException(), isNull);
  expect(find.byKey(const Key('terminal-bottom-bar')), findsOneWidget);
});
testWidgets('lock button locks the terminal', (t) async {
  final (_, c) = await openTill(t, const Size(1280, 800));
  await tapKey(t, 'terminal-lock');
  expect(c.read(routerProvider).state.matchedLocation, AppRoutes.lock);
});
```

`fnbModeOverride` is a small helper added to `till_harness.dart` that overrides `posConfigProvider` with the seeded config copied with `fnbMode: on`; add `StaffMember.copyWith` only if it does not exist (test-side extension otherwise). If `OnDutySession.lock()` does not route to `/pos/lock` in tests, assert the session mode instead.

- [ ] **Step 3: Run to verify they fail** — `flutter test test/app/terminal_nav_test.dart test/app/terminal_shell_test.dart`; Expected: FAIL.

- [ ] **Step 4: Implement** `terminal_nav.dart`, `terminal_search.dart` and `terminal_shell.dart`:
  - Wide (≥ 600 dp): `Row` of sidebar (240 px, or 72 px when collapsed; collapse state in a local `StatefulWidget`) and an `Expanded` column of top bar + child. Sidebar: logo tile (rose gradient square with `Icons.storefront`, "CashierA", "Retail Point of Sale" via l10n), five items (selected = rose gradient pill with white text, others slate), terminal card at the bottom (green dot when online, device code, store name, staff name; ellipsis on overflow).
  - Top bar inside `GlassBlur`: `shellRetailPos` label with the store name; `SearchScanField` bound to `terminalSearchQueryProvider` when `showsSearch`; Held Orders `GlassPill` with `heldBadge` (to `/pos/orders`); Kitchen pill (F&B and `kitchen.view`, to `/pos/kitchen`); Lock pill; `TerminalStatusChip`. Under 900 px the pills collapse into a `PopupMenuButton`.
  - Narrow (< 600 dp): top bar, child, bottom `NavigationBar` with the five sections (`terminal-bottom-bar`).
- [ ] **Step 5: Wire the router**: replace the `/pos` `GoRoute` with `GoRoute(path: AppRoutes.pos, redirect: (_, _) => AppRoutes.sell)`; move every `/pos/...` route and `/sync` into `ShellRoute(builder: (_, _, child) => TerminalShell(child: child), routes: [...])`. Keep `redirectFor` untouched (its tests stay valid). Delete `pos_home_screen.dart`. In `app.dart` use `AppTheme.light()` and `builder: (context, child) => AppBackground(child: child!)`.
- [ ] **Step 6: Sell layout**: replace `MediaQuery.sizeOf(context).width >= _twoPaneWidth` with a `LayoutBuilder` on the body using `constraints.maxWidth`; keep `_twoPaneWidth = 900` but measured against the content width, and lower it to 760 so a 1280 px terminal (1040 px content) keeps two panes.
- [ ] **Step 7: Run the new tests, then the full suite** — `flutter test`; Expected: all pass. Fix any existing flow test that broke only because of layout (duplicate finders, sizes) and list each change for the phase report.
- [ ] **Step 8: Commit** — `git commit -m "Redesign: terminal shell with five-item sidebar and top bar"`

---

### Task 5: Back-office shell

**Files:**
- Create: `app/lib/features/back_office/presentation/admin_nav.dart` (pure section model)
- Modify: `app/lib/features/back_office/presentation/admin_shell.dart` (rewrite)
- Modify: `app/lib/core/l10n/arb/app_id.arb`, `app_en.arb`
- Modify: `app/test/features/back_office/admin_shell_test.dart` (replace the rail-scroll test)
- Test: `app/test/features/back_office/admin_nav_test.dart`

**Interfaces:**
- Consumes: Tasks 1–3 widgets; `SessionController.signOut()`; existing `nav*` l10n keys for tab labels.
- Produces:
  - `enum AdminSection { overview, catalog, sales, members, settings }`.
  - `class AdminTab { const new(this.route, this.label); final String route; final String Function(AppLocalizations) label; }`.
  - `List<AdminTab> adminTabs(AdminSection s)`:
    - overview: `/admin`, `/admin/reports`, `/admin/shifts`, `/admin/audit`
    - catalog: `/admin/products`, `/admin/categories`, `/admin/stock`, `/admin/suppliers`, `/admin/purchase-orders`, `/admin/transfers`, `/admin/import`
    - sales: `/admin/promotions`, `/admin/vouchers`, `/admin/qris-payments`
    - members: `/admin/customers`, `/admin/kasbon`, `/admin/loyalty`
    - settings: `/admin/settings`, `/admin/tables`
  - `({AdminSection section, int tab}) adminLocate(String location)` — longest matching tab route wins (so `/admin/products/new` → catalog, tab 0; `/admin` → overview, tab 0).
  - `AdminShell({required Widget child})`. Keys: `admin-nav-<section.name>`, `admin-tab-<route>`, `sign-out` (kept), `admin-drawer-button`.
  - New l10n keys: `navSales`, `navMembers` (shared with Task 4), `navOverview`, `navCatalog`, `navSettings` (shared).

- [ ] **Step 1: Write the failing tests**

```dart
test('every back-office route belongs to exactly one tab', () {
  final routes = [for (final s in AdminSection.values) ...adminTabs(s).map((t) => t.route)];
  expect(routes.toSet().length, routes.length);
  expect(routes.length, 19);
});
test('locate picks the section and tab', () {
  expect(adminLocate('/admin'), (section: AdminSection.overview, tab: 0));
  expect(adminLocate('/admin/products/new'), (section: AdminSection.catalog, tab: 0));
  expect(adminLocate('/admin/qris-payments'), (section: AdminSection.sales, tab: 2));
  expect(adminLocate('/admin/tables'), (section: AdminSection.settings, tab: 1));
});
```

Widget tests in `admin_shell_test.dart` (router built as today, plus `/admin/products` and `/admin/tables` routes):

```dart
testWidgets('five sections fit a 1920x940 screen without scrolling', (t) async { ... }
  // all five admin-nav-* keys visible, no exception, no Scrollable in the sidebar
testWidgets('Settings section shows its tabs and opens Tables', (t) async { ... }
  // tap admin-nav-settings → 'settings page'; tap admin-tab-/admin/tables → tables page
testWidgets('phone: drawer with five sections, no overflow', (t) async { ... }
  // 360x740, tap admin-drawer-button, five admin-nav-* keys, takeException() isNull
```

- [ ] **Step 2: Run to verify they fail** — `flutter test test/features/back_office/admin_nav_test.dart test/features/back_office/admin_shell_test.dart`; Expected: FAIL.
- [ ] **Step 3: Implement** `admin_nav.dart` and the shell: same sidebar component style as the terminal (extract the shared sidebar item and logo tile into `app/lib/app/shell/sidebar.dart` and use it from both shells), top bar inside `GlassBlur` (page title = current tab label, store name, Sign out), `ChipTabs` row under the top bar when the section has more than one tab; tapping a section goes to its first tab. Under 600 dp: `Drawer` with the five sections, tabs scroll horizontally.
- [ ] **Step 4: Run** the two files, then `flutter test`; Expected: PASS.
- [ ] **Step 5: Commit** — `git commit -m "Redesign: back-office shell with five sections and tabs"`

---

### Task 6: Screenshots, checks and push

**Files:**
- Create: `app/dart_test.yaml` (declares tag `screenshots`; default run uses `exclude_tags: screenshots`)
- Create: `app/test/screenshots/shells_screenshot_test.dart` (tag `screenshots`)

**Interfaces:**
- Consumes: `openTill`, `AdminShell`, `AppTheme.light()`.

- [ ] **Step 1: Write the screenshot test**: load Plus Jakarta Sans and Inter with `FontLoader` from `assets/fonts/` (and `MaterialIcons` from the Flutter SDK's `bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf`) so text renders; pump the terminal shell on Register at 1280×800 and 390×844, and the back-office shell (Overview and Catalog sections) at 1280×800 and 390×844; capture each with `expectLater(find.byType(MaterialApp), matchesGoldenFile('out/<name>.png'))` run under `--update-goldens`. `test/screenshots/out/` is git-ignored.
- [ ] **Step 2: Generate** — `flutter test --tags screenshots --update-goldens test/screenshots`; Expected: PNGs in `test/screenshots/out/`.
- [ ] **Step 3: Run every check** (Global Constraints list), including `flutter test` (screenshot tag excluded) and `flutter build web --release`; Expected: all green.
- [ ] **Step 4: Commit and push**

```bash
git add app/dart_test.yaml app/test/screenshots/shells_screenshot_test.dart app/.gitignore
git commit -m "Redesign: screenshot suite for review"
git push -u origin new-design
```

- [ ] **Step 5: Phase report to the owner**: the screenshots (copied into the scratchpad and sent), the test counts before and after, and every existing test changed with the reason.
