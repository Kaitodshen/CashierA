# CashierA redesign to the Stitch "Radiant Light White Glass" design

Date: 2026-11-09 · Branch: `new-design` · Status: design approved in chat, spec awaiting review

## 1. Goal

Make every CashierA screen follow the Stitch project **Minimalist Flutter POS System**
(project `15741213647774536894`, screen family "Register & Checkout – Radiant Light
White Glass POS"), for production use in real stores.

Only the look, layout and navigation change. Business logic, database, sync,
pricing, printing, permissions and routes stay as they are.

### Success criteria

- The five Stitch screens (Register & Checkout, Merchandise Catalog, Overview & Shift
  Management, Loyalty & Members, Store Settings) are matched closely by their
  CashierA counterparts. Every other screen uses the same design system.
- Both sidebars have five items (section 4).
- `dart format`, `flutter analyze --fatal-infos`, `flutter test` (app) and `dart test`
  (core) pass, and `flutter build web --release` succeeds, with Flutter 3.47.8 (the CI
  version).
- Smooth on modest Android POS tablets: no blur on cards or tiles, and the remaining
  blur can be switched off.

### Decisions taken with the owner

| Topic | Decision |
|---|---|
| Location | Branch `new-design` in this repository (not a separate repository) |
| Purpose | Production in real stores |
| Approach | Design system first, then restyle every screen; three phases with screenshots |
| Sidebar | Five items, like Stitch; other pages move to tabs or top-bar pills |
| Sales | Its own back-office section (Promotions, Vouchers, QRIS payments) |
| Glass | Glass look everywhere; real blur only on the top bar, dialogs and sheets; a "Visual effects" switch turns that blur off |
| Theme | One light theme for terminals and back office; the dark POS theme is removed |

### Not in scope

- New features. Elements of the mockups with no CashierA data behind them are
  dropped, never filled with invented numbers: the hourly sales chart and sales
  target, membership tiers, the barcode-scanner and customer-display cards,
  firmware and latency labels.
- Product photo upload (the product editor has no upload today). Photos are shown
  when a product already has an `image_path`.
- Dark mode.

## 2. Design language

Source of truth: the Stitch HTML of the five screens (Tailwind config and CSS).

### 2.1 Colors (`tokens.dart`, replacing the current palette)

| Token | Value | Use |
|---|---|---|
| `primary` | `#E11D48` | Main actions, active nav item, totals, category labels |
| `primaryPressed` | `#BE123C` | Pressed and gradient end |
| `primarySoft` | `#FFF1F2` | Selected chips, badges, avatar tint |
| `success` | `#10B981` | Paid, online, positive change |
| `warning` / `warningSoft` / `warningText` | `#F59E0B` / `#FEF3C7` / `#D97706` | Low stock, pending |
| `error` | `#EF4444` | Errors, voids, stock alerts |
| `text` / `textStrong` | `#0F172A` / `#020617` | Body and headings |
| `textSecondary` | `#334155` | Labels, table content |
| `textMuted` | `#64748B` | Metadata, SKUs, hints |
| `hairline` | `#E2E8F0` | Dividers, table rules, input borders |

### 2.2 Background

A fixed gradient `#FFF1F2 → #FDF2F8 → #F5F3FF` (top-left to bottom-right) with five
soft colour glows at the Stitch positions (pink/rose top-left, rose/indigo right,
violet/peach bottom, rose/lavender centre, rose/violet bottom-right) at 35–45 %
opacity. The glows are radial gradients painted once by a `CustomPainter` inside a
`RepaintBoundary`; no blur filter is used.

### 2.3 Glass

- **Glass card** (`GlassCard`): white fill at a level per variant, 1 px white border
  (≈ 60 % alpha), a 1 px inner top highlight, shadow `0 10 30 rgba(15,23,42,0.08)`.
  Variants: `subtle` (decorative, lower opacity), `regular`, `solid` (cart, tables,
  forms: near-opaque so text stays crisp under store lighting).
- **Real blur** (`BackdropFilter`, sigma ≈ 20) only on the top bar, dialogs and
  bottom sheets, where content moves behind the glass.
- **Visual effects switch**: a terminal setting in Settings (default on), stored in
  the terminal's local database next to its printer settings. Off replaces every
  `BackdropFilter` with the faked glass. The back office (web and desktop) always
  uses real blur on those three surfaces and has no switch.

### 2.4 Typography

| Role | Font | Notes |
|---|---|---|
| Display, headline, title, body, big numbers | Plus Jakarta Sans (bundled) | As in the Stitch Tailwind config |
| Labels, chips, table headers, buttons | Inter (new bundled asset, OFL) | Uppercase + letter-spacing for table headers and section labels |
| Money, quantities, codes (SKU, `#TRX-…`) | Same fonts with tabular figures | No extra monospace font |

Type scale follows the Stitch design system: display 32/40 w700, headline-lg
24/32 w600, headline-md 20/28 w600, body-lg 16/24, body-md 14/20, label-lg 14/20
w600, label-md 12/16 w600, label-sm 11/14 w500, numeric-xl 28/32 w700,
numeric-lg 20/24 w700.

### 2.5 Shape, spacing, touch

Radius: card 24, tile 20, control 14, small 8, pill full. Spacing keeps the 4/8/12/16/24/32
scale. Every touch target ≥ 48 dp, including cart steppers (Stitch draws 36).

### 2.6 Shared widgets (`core/design_system/widgets/`)

`AppBackground`, `GlassCard`, `GlassPill`, `GlassDialog` / `showGlassSheet`,
`PrimaryButton` (rose gradient with soft rose glow), `SecondaryButton` (white glass),
`SearchScanField`, `ChipTabs` (category chips and page tabs), `SegmentedTabs`,
`StatCard` (icon tile, delta badge, label, value, footnote), `PageHeader`
(title, subtitle, status line, actions), `GlassTable` (uppercase headers, 64 dp rows,
cards on phones), `StatusChip`, `StockBar`, `MoneyText`, `InitialsAvatar`,
`ProductThumb` (photo or initials tile). `EmptyState`, `PinPad`, `SyncStatusChip`,
toasts and skeletons are restyled.

`ThemeData` is rebuilt from these tokens so plain Material widgets (buttons,
inputs, dialogs, switches, tabs) already match.

## 3. Shells

### 3.1 Terminal shell (after PIN login)

- **Sidebar**, 240 px, collapsible to a 72 px rail: logo tile ("CashierA",
  "Retail Point of Sale"), five items, and a terminal card at the bottom (device
  code, store, online state).

  | Item | Route | Today |
  |---|---|---|
  | Register & Checkout | `/pos/sell` (landing after unlock) | `SellScreen` |
  | Overview | `/pos/shift` | `ShiftScreen` |
  | Catalog | `/pos/catalog` | `CatalogBrowserScreen` |
  | Members | `/pos/customers` | `CustomersScreen` |
  | Settings | `/pos/printer` | `PrinterScreen` + terminal/sync info |

- **Top bar**: store · terminal label; `SearchScanField` on Register and Catalog;
  **Held Orders** pill with count (opens `/pos/orders`); **Kitchen** pill in F&B
  mode for staff with `kitchen.view`; **Lock**; status pill (online/offline +
  unsynced count, opens `/sync`).
- **F&B**: a Tables / Quick sale switch at the top of Register opens `/pos/tables`.
- `/pos` (the old home cards) redirects to `/pos/sell`. The information on the old
  cards moves: on-duty staff and terminal → sidebar card and top bar; store tax and
  paper → Settings; open shift → Overview; outbox → status pill.
- **Below 600 dp**: bottom bar (Register, Overview, Catalog, Members, Settings),
  cart as a slide-up sheet, top-bar pills collapse into an overflow menu.

### 3.2 Back-office shell

Same sidebar style, five sections. Each section shows `ChipTabs` under the page
header; each tab is its existing route.

| Section | Tabs (routes) |
|---|---|
| Overview | Home `/admin` · Reports · Shifts · Audit log |
| Catalog | Products · Categories · Stock · Suppliers · Purchasing · Transfers · Import |
| Sales | Promotions · Vouchers · QRIS payments |
| Members | Customers · Kasbon · Loyalty |
| Settings | Store · Tables |

Top bar: page title, store name, Sign out. Below 600 dp: slide-out drawer with the
five sections; tabs scroll horizontally.

### 3.3 Screens without a shell

Splash, setup, welcome, pairing, PIN lock and sign-in: one centred glass card on
the background.

## 4. Screen mapping

### 4.1 Register & Checkout (`sell_screen`, `cart_panel`)

- Category chips above a product grid of 3–4 columns (`ProductThumb`, stock badge,
  category in rose uppercase, name, price, rose **+**).
- Cart "Active Ticket": order number, Clear, item count; customer row with Assign;
  line items with steppers and per-unit price; promo/voucher row; subtotal,
  discount, tax; total card; payment tiles (QRIS, Card, Cash – from the store's
  enabled payment methods); quick-cash chips; **Pay (F12)**.
- Pay opens the restyled payment screen with the chosen method and amount filled
  in. Split payments, kasbon and QRIS behave as today.
- With no open shift, Register shows the existing open-shift panel as a glass card
  (as today), so landing here after unlock never allows a sale without a shift.

### 4.2 Overview (`shift_screen`)

- Header: shift number, opened at and by; Close shift; Print X report.
- Four `StatCard`s from the live X report: gross sales, transactions (with average
  basket), expected cash in drawer (with float), non-cash total.
- Recent orders of this shift (from the local database), payment breakdown, cash
  in/out actions. With no open shift: the open-shift card as today.

### 4.3 Catalog (`catalog_browser_screen`; back-office `products_screen`)

- `GlassTable`: product & variant (thumb, name, variant), SKU / barcode, category
  chip, stock (`StockBar`, status text), price. Category chips, stock-status filter,
  sort.
- Terminal actions: stock in/out, opname. Back office: add product, export, import.

### 4.4 Members (`customers_screen`; back-office customers)

- List: `InitialsAvatar`, name, phone, points, kasbon balance. Detail panel: points
  balance and redeem, kasbon, recent purchases, **Use in current sale**. No tiers.

### 4.5 Settings (`printer_screen` + terminal info + sync)

- Cards: store profile (read-only), receipt printer (connection, paper, Test print),
  cash drawer (existing auto-open), Visual effects switch, terminal and sync status.

### 4.6 All other screens

Payment, QRIS dialog, receipt, refund, orders, close shift, shift report, sync,
tables, kitchen, opname, stock adjust and sell dialogs; all back-office pages and
editors. Rules: `PageHeader` + glass cards; lists use `GlassTable` (cards on
phones); forms are two-column cards on wide screens; dialogs use `GlassDialog`;
flow screens (payment, receipt, refund, close shift) use a centred or split glass
layout.

## 5. Engineering

- **Toolchain**: Flutter 3.47.8 installed in the work environment; all CI checks run
  before every push.
- **Performance**: background painted once in a `RepaintBoundary`; blur limited to
  three surface types and switchable; grid tiles are `const` where possible.
- **Images**: `ProductThumb` loads the product's public `product-images` URL with
  `Image.network`; any error or offline state shows the initials tile.
- **Fonts**: Inter variable TTF bundled under `app/assets/fonts/` with its OFL text.
- **l10n**: new strings in `app_id.arb` and `app_en.arb`; Indonesian stays default.
- **Keys and routes**: widget keys used by tests are kept; routes unchanged except
  `/pos` redirecting to `/pos/sell`.

## 6. Testing

- Existing app (160) and core tests stay green. Tests that only asserted the old
  layout (e.g. the POS home cards) are rewritten to assert the same behaviour in its
  new place; each change is listed in the phase report.
- New widget tests: both five-item sidebars and their tabs; F&B Tables switch and
  Kitchen pill visibility; Held Orders count; Visual effects switch removes blur;
  phone layouts (bottom bar, drawer).
- Screenshot suite (`app/test/screenshots/`, tagged so the normal run skips it):
  pumps the main screens with fake data and real fonts, writes PNGs at 1280×800 and
  390×844 for review. Not committed as goldens.

## 7. Phases

1. **Foundation and shells**: tokens, theme, fonts, background, glass widgets,
   terminal and back-office shells with five-item sidebars and tabs, Visual effects
   switch.
2. **Terminal screens**: the five Stitch screens, then payment, QRIS, receipt,
   refund, orders, close shift, shift report, PIN lock, pairing, welcome, setup,
   splash, sync, tables, kitchen, opname, dialogs.
3. **Back office**: every page, editor and the sign-in screen.

Each phase ends with all checks passing, screenshots sent to the owner, and a push
to `new-design`.
