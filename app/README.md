# CashierA app (Flutter)

One codebase, two shells:

| Device | Starts in | What it does |
|---|---|---|
| Paired terminal (Android tablet, Windows PC) | PIN lock → POS | Offline-first: local SQLite (Drift) + outbox synced to `sync_push`. Cashier screen (scan, promos, discounts, vouchers, hold/resume, split payment, kasbon, receipts on thermal printers or PDF), shifts with X/Z reports, cash in/out, voids and refunds with manager PIN, product browser, stock in and out, stock count (opname) |
| Browser, phone, desktop signed in by email | Back office | Online: stores and pairing codes, products and variants, categories, suppliers, stock per store with history and low-stock alerts, CSV/XLSX import and export, promotions, vouchers, store settings (tax, rounding, receipt) and payment methods, shifts with their X/Z reports, the audit log |

## Run

You need a Supabase project that has the migrations from `../supabase` applied (see `../supabase/README.md`).

```bash
flutter run -d chrome --dart-define=SUPABASE_URL=https://<ref>.supabase.co --dart-define=SUPABASE_ANON_KEY=<publishable key>
```

The web build only contains the back office. A terminal needs a native build:
- **Android tablet:** install Android Studio (Android SDK), connect the tablet, then `flutter run -d <device>`.
- **Windows PC:** install Visual Studio with "Desktop development with C++", turn on Windows Developer Mode, then `flutter run -d windows`.

Without the two `--dart-define` values the app shows a "Setup incomplete" screen instead of crashing.

### First run of a terminal

1. In the back office, sign in as a manager and choose **Create pairing code** next to the store.
2. On the terminal, choose **Pair a cashier terminal** and type the 8-character code.
3. Staff tap their name and enter their PIN. This works offline, and 5 wrong tries lock that person for 5 minutes.

### Selling (Phase 4)

Everything below works offline. Sales reach the server through the outbox, which checks every amount again.

1. **POS home → Kasir.** The first time, open the shift with the cash in the drawer. Opening needs `shift.manage`.
2. **Add items.** Scan a barcode and press Enter, or tap a product. Use the search box and the category chips to find items. Weighed items ask for the quantity, and products with modifiers ask for the choices. On tablets the bill is on the right. On phones it opens from the bar at the bottom.
3. **On the bill.** Tap a line to change the quantity, give a line discount, add a note or remove it. **Diskon** gives a bill discount. **Voucher** takes a code. **Tahan** parks the bill. The customer chip finds or adds a customer.
   - Promotions apply on their own: happy hour, buy X get Y, bundles, quantity tiers and minimum purchase, by priority and stacking rule.
   - A manual discount above the store's limit (default 20%) needs a colleague with `pos.discount_override` to enter their PIN. Someone who has the permission approves their own discount.
4. **Bayar.** Pick a method. Cash offers exact and round amounts and shows the change. Card, transfer and e-wallet take a reference when the method needs one. You can split the payment, and only cash gives change. Kasbon asks for a customer and is due after the company's kasbon days.
5. **Receipt.** It shows the change on top. **Bagikan PDF** shares the receipt, and **Cetak** prints it on the thermal printer (or through the system print dialog when none is set up) and marks it printed. Later prints say **SALINAN** and go to the audit log. **Void** and **Refund** are here too (see below).
6. **Transaksi.** This screen lists today's sales on this terminal and the held bills. Tap a sale to reprint it, or tap a held bill to resume it. **Batalkan** cancels a held bill with a reason; it needs `pos.void` or an approver.

Order numbers look like `PST-T1-261106-0001`: store, terminal, store-local date, then a counter per terminal per day.

### Shifts, corrections and printing (Phase 5)

All of this works offline too. Approvals are a colleague with the permission entering their PIN on this terminal; someone who holds the permission can approve their own action.

- **POS home → Shift.** Shows the cash that should be in the drawer and the live X report (sales, payments by method, voids, refunds, cash, top items).
  - **Kas masuk / Kas keluar** records petty cash with a reason (`shift.cash_movement`). A cash out can't take more than the drawer should hold.
  - **Buka laci** opens the drawer without a sale. It asks for a reason and a PIN with `pos.open_drawer`, and is audited.
  - **Cetak X** prints the X report.
  - **Tutup shift** counts the drawer by note or as a total, shows the selisih (even, over or short), and needs a note when it isn't even. Held bills stay held. The close is sent after the shift's sales, so the server computes the expected cash over the same transactions; if its figure differs it raises `CASH_DISCREPANCY`. The Z report prints and can be shared as a PDF. Earlier shifts are listed below with their selisih.
- **Void** (receipt screen): for a finished sale with no refunds. It needs `pos.void`; after the receipt was printed, a PIN with `pos.void_after_print`. The stock comes back and the cash comes off the shift that is open now.
- **Refund** (receipt screen): pick quantities per line, choose cash or a non-cash method the customer paid with, keep or turn off restocking, give a reason. Every refund needs a PIN with `pos.refund`. Partial refunds add up to the line's amount exactly. The kasbon part of a sale can't be refunded until it is repaid (Phase 6). Refund numbers look like `R-PST-T1-261106-0001`.
- **POS home → Printer.** Find a Bluetooth (BLE) or USB printer, or type a network address (`192.168.1.50`, port 9100 by default). Pick 58 or 80 mm paper, whether the printer opens the cash drawer, and whether every sale prints by itself. **Tes cetak** prints a ruler so you can check the paper width. A printer that is off never blocks a sale: the cashier sees why, and can share the PDF instead.

### Catalog and stock

- **Back office → Import / Export.** Download the template, fill it in Excel or Google Sheets, and upload the `.csv` or `.xlsx`. The preview lists every problem with its row number. Nothing is saved until the whole file is clean, and then it is saved in one transaction, so a failed import changes nothing. Importing the same file again updates the same products (matched by SKU). Stock columns set the counted stock per store and show up in the stock history as an opname. Export gives the same columns back, so export → edit → import works.
- **Back office → Shift / Log audit.** Shift lists every shift by store and period with its selisih and sales; tap one for its X or Z report (print or share as PDF). Log audit shows who did what, who approved it and on which terminal, filtered by store, period, kind, or approvals only, newest first with **Muat lagi** for older entries.
- **Back office → Promo / Voucher / Pengaturan toko.** Promotions use one form per type, with the products they apply to, the days and hours, the stores and the priority. Vouchers have a percent or a fixed amount, a minimum spend, a ceiling and a usage limit. Store settings cover tax (rate, included or added), service charge, rounding, the discount approval limit, kasbon, the receipt header and footer and the paper width, plus which payment methods the store accepts. Terminals pick up changes on their next refresh.
- **Back office → Stock.** Pick a store to see on-hand stock, filter to low items, open an item's movement history, adjust it, and resolve low-stock alerts.
- **Terminal → Products.** The terminal keeps its own copy of the catalog and of its store's stock. It refreshes at start, every 5 minutes, when the network comes back, and shortly after stock changes on the server. Search by name or SKU, or scan a barcode and press Enter. Staff with `inventory.adjust` can record stock in or out, and staff with `inventory.opname` can do a stock count. Both work offline and are sent through the outbox. While such a change is waiting to be sent, the terminal does not overwrite its local stock with the server's older figure.

## Develop

```bash
dart run build_runner build
```

```bash
flutter test
```

```bash
flutter analyze
```

Run `build_runner` after changing a Drift table or an `@riverpod` provider. `flutter gen-l10n` runs automatically; the strings live in `lib/core/l10n/arb/` (`app_id.arb` is the template, `app_en.arb` the English copy).

## Layout

```text
lib/
  app/            app widget, router, AppMode + redirect rules
  core/
    auth/         pairing, staff roster, offline PIN check, server interfaces
    config/       --dart-define environment
    catalog/      catalog mirror pull, local catalog queries, offline stock changes, refresh scheduling
    pos/          cart, till configuration, order payload, order/shift/refund/audit services, receipt,
                  X/Z report layout, PDFs
    printing/     printer setting, ESC/POS transport (plugin + TCP 9100, web stub), slips, printer service
    database/     Drift tables (local mirror + sync_queue)
    design_system/ tokens, themes (dark POS / light back office), shared widgets
    l10n/         ARB strings and generated localizations
    network/      secure session storage for Supabase
    session/      SessionController: decides and changes AppMode
    sync/         outbox DAO, sync engine, sync_push transport
    providers.dart  Riverpod wiring
  features/       startup, pairing, pin_login, pos_home, catalog (terminal), sell (cashier,
                  payment, receipt, refund, sales), shift (X/Z, close), printing (printer setup,
                  print actions), sync_status, back_office (shell, products, categories, suppliers,
                  stock, import/export, promotions, vouchers, store settings, shifts, audit log)
test/             unit, sync and widget tests (in-memory SQLite, fake transport)
```
