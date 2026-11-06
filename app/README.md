# CashierA app (Flutter)

One codebase, two shells:

| Device | Starts in | What it does |
|---|---|---|
| Paired terminal (Android tablet, Windows PC) | PIN lock → POS | Offline-first: local SQLite (Drift) + outbox synced to `sync_push`. Cashier screen (scan, promos, discounts, vouchers, hold/resume, split payment, kasbon, receipts on thermal printers or PDF), shifts with X/Z reports, cash in/out, voids and refunds with manager PIN, product browser, stock in and out, stock count (opname). F&B stores: tables, kitchen and bar tickets, kitchen display. Dynamic QRIS through Midtrans |
| Browser, phone, desktop signed in by email | Back office | Online: stores and pairing codes, products and variants, categories, suppliers, stock per store with history and low-stock alerts, CSV/XLSX import and export, promotions, vouchers, store settings (tax, rounding, receipt) and payment methods, shifts with their X/Z reports, the audit log, purchase orders and receiving, stock transfers, dining tables, QRIS payments |

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
5. **Receipt.** It shows the change on top. **Bagikan PDF** shares the receipt (the first share of a finished sale counts as printing it; later shares are audited copies), and **Cetak** prints it on the thermal printer (or through the system print dialog when none is set up) and marks it printed. Later prints say **SALINAN** and go to the audit log. **Void** and **Refund** are here too (see below).
6. **Transaksi.** This screen lists today's sales on this terminal and the held bills. Tap a sale to reprint it, or tap a held bill to resume it. **Batalkan** cancels a held bill with a reason; it needs `pos.void` or an approver.

Order numbers look like `PST-T1-261106-0001`: store, terminal, store-local date, then a counter per terminal per day.

### Shifts, corrections and printing (Phase 5)

All of this works offline too. Approvals are a colleague with the permission entering their PIN on this terminal; someone who holds the permission can approve their own action.

- **POS home → Shift.** Shows the cash that should be in the drawer and the live X report (sales, payments by method, voids, refunds, cash, top items).
  - **Kas masuk / Kas keluar** records petty cash with a reason (`shift.cash_movement`). A cash out can't take more than the drawer should hold. It opens the drawer, so staff without `pos.open_drawer` (cashiers) need a manager's PIN, the same as **Buka laci**.
  - **Buka laci** opens the drawer without a sale. It asks for a reason and a PIN with `pos.open_drawer`, and is audited.
  - **Cetak X** prints the X report.
  - **Tutup shift** counts the drawer by note or as a total, shows the selisih (even, over or short), and needs a note when it isn't even. Held bills stay held. The close is sent after the shift's sales, so the server computes the expected cash over the same transactions; if its figure differs it raises `CASH_DISCREPANCY`. The Z report prints and can be shared as a PDF. Earlier shifts are listed below with their selisih.
- **Void** (receipt screen): for a finished sale with no refunds. It needs `pos.void`; after the receipt was printed, a PIN with `pos.void_after_print`. The stock comes back and the cash comes off the shift that is open now.
- **Refund** (receipt screen): pick quantities per line, choose cash or a non-cash method the customer paid with, keep or turn off restocking, give a reason. Every refund needs a PIN with `pos.refund`. Partial refunds add up to the line's amount exactly. The kasbon part of a sale can't be refunded until it is repaid (Phase 6). Refund numbers look like `R-PST-T1-261106-0001`.
- **POS home → Printer.** Find a Bluetooth (BLE) or USB printer, or type a network address (`192.168.1.50`, port 9100 by default). Pick 58 or 80 mm paper, whether the printer opens the cash drawer, and whether every sale prints by itself. **Tes cetak** prints a ruler so you can check the paper width. A printer that is off never blocks a sale: the cashier sees why, and can share the PDF instead.

### Customers, points and kasbon (Phase 6)

Works offline. The terminal keeps its own copy of each customer's points and of this store's kasbon. While a sale or an installment is still in the outbox, a refresh keeps the terminal's figure instead of the server's older one.

- **Points at the till.** With a customer on the bill, the **poin** button shows the balance.
  - Tap it to spend points. The most you can spend is what's left to pay or the balance, and there is a minimum per redemption when the company sets one.
  - Points are earned on the rest: 1 point per Rp 10.000 of net spend, after discounts and points.
  - The receipt shows the points earned. A void gives redeemed points back and takes earned ones away. A refund takes earned points back in proportion.
- **POS home → Pelanggan.** Search by name, phone or code, and see each customer's points and what they owe this store.
  - Open a customer to see each kasbon with what's left, its due date, and how late it is.
  - **Bayar kasbon** takes any amount up to what is owed, in cash or a method the store accepts, with a reference for non-cash. The money goes to the oldest kasbon first. A balance slip prints (previous balance, paid, still owed, LUNAS when settled), and cash opens the drawer.
  - Cash installments count in the shift's cash. A kasbon sale with installments can't be voided (refund it instead), and repaid kasbon becomes refundable.

### F&B, purchasing and transfers (Phase 8)

- **F&B stores.** The owner turns on **Mode F&B** per store in the back office (**Meja**), where the tables are set up (name, area, seats, active). A product is prepared in the kitchen or at the bar by its own station, else by its category's. Terminals pick it all up on their next refresh.
- **Terminal → Meja.** A grid of the store's tables: free, occupied, needs clearing.
  - Tap a free table, enter the guests, and the bill is a dine-in bill on that table.
  - Tap a table with a bill from this terminal to resume it. A second bill on the same table is refused.
  - **Kosongkan meja** frees a table after the guests left; it is refused while a bill is still open on it.
- **Kirim ke dapur** (cashier screen, F&B stores): holds the bill and prints one ticket per station on the kitchen and bar printers (**Printer** has three slots: receipt, kitchen, bar). A ticket shows the table, guests, order number, time, and the items with modifiers and notes, without prices. Sending again prints only what was added, marked **TAMBAHAN**. With no printer for a station, the ticket is still on the kitchen display.
- **Terminal → Dapur** (staff with `kitchen.view`): the open tickets of the store, oldest first, filtered by station, refreshed every 10 seconds and on every change. The border turns amber after 10 minutes and red after 20. **Mulai**, **Siap** and **Disajikan** go through the outbox and show at once. This screen needs the network; offline it keeps the last list.
- **Back office → Pembelian.** Purchase orders per store and status.
  - The editor takes the supplier, the store, the expected date, and lines picked by name or SKU with quantity and cost. **Simpan** keeps a draft, **Pesan** sends it, **Batalkan** cancels it while nothing has arrived.
  - **Terima barang** takes the quantity (at most what is still open) and the cost per line. Each delivery gets a receipt number, adds the stock and averages the cost. Lines are locked once goods arrived.
  - **PDF** gives the order for the supplier.
- **Back office → Transfer.** Incoming and outgoing transfers per store.
  - **Minta transfer**: the receiving store asks another store for items.
  - The sender approves or rejects it (with a reason), then ships the quantities it sends.
  - The receiver enters what arrived. A difference is shown in red and raises a discrepancy alert.
  - The history shows who did what and when.

### Dynamic QRIS (Phase 9)

- Build with `--dart-define=PAYMENT_GATEWAY=midtrans` (production), or `mock` for demos (pays itself after 8 seconds). Without it, **QRIS Dinamis** is not offered; the static QRIS sticker method always works, offline too.
- **Payment screen → QRIS Dinamis → Buat QR.** The QR for the amount (all or part of the bill) shows with a countdown.
  - When the customer pays, the payment is added with a check mark, and can't be removed.
  - **Batalkan QR** cancels it. If the customer paid a second before, it counts as paid.
  - An expired QR books nothing; **QR baru** makes a new one.
- A paid QRIS stays with the bill until the sale is finished: the bill can't be cleared, and it survives leaving the payment screen or holding the bill.
- The server key is never on the device. The terminal talks to the `qris-create` / `qris-cancel` Edge Functions and watches the charge, through Realtime plus a poll every 3 seconds.
- **Back office → Pembayaran QRIS:** every charge per store and period, with the totals. Charges paid without a sale are flagged red, to finish on the terminal or refund at Midtrans.

### Catalog and stock

- **Back office → Import / Export.** Download the template, fill it in Excel or Google Sheets, and upload the `.csv` or `.xlsx`. The preview lists every problem with its row number. Nothing is saved until the whole file is clean, and then it is saved in one transaction, so a failed import changes nothing. Importing the same file again updates the same products (matched by SKU). Stock columns set the counted stock per store and show up in the stock history as an opname. Export gives the same columns back, so export → edit → import works.
- **Back office → Ringkasan (dashboard).** For staff with `reports.view`, the home page shows today against yesterday (net sales, number of sales, average), the last 7 days as a bar chart, today's top products and payment mix, and chips for open shifts, low stock, overdue kasbon and open alerts. The store filter switches between one store and all of them.
- **Back office → Laporan.** Pick a store (or all) and a period (today, yesterday, 7 days, this month, last month, or any dates).
  - **Penjualan:** by day (empty days included) with a chart, the money summary, by store, and by hour in each store's own time.
  - **Pembayaran:** by method with each method's share, refunds by method, kasbon issued and repaid.
  - **Produk:** by category and by product, with quantity, refunded quantity, net, cost and margin.
  - **Staf:** sales, average, discounts, voids and refunds per person.
  - **Pajak:** taxable base, DPP, PPN and exempt sales per day.
  - **Nilai stok:** stock × current cost per store, with the low and negative counts.
  - Every table has **PDF** and **Excel** buttons. Excel keeps numbers as numbers. Sales are completed sales; voids are not sales; refunds count on the day of the refund; net sales = sales − refunds.
- **Back office → Pelanggan / Kasbon / Loyalti & kasbon.**
  - **Pelanggan:** search, add and edit customers (phone, e-mail, kasbon limit, active). A customer's page shows their kasbon with every installment and their points history. **Sesuaikan poin** adds or removes points with a reason; it needs the new `loyalty.adjust` permission (owner and manager), and the balance can't go below 0.
  - **Kasbon:** what each customer owes per store, most overdue first, with the total and overdue amount, flagging customers over their limit.
  - **Loyalti & kasbon:** the company rules (points on or off, spend per point, value per point, minimum redemption, kasbon due days). Only the owner can change them.
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
    pos/          cart, till configuration, order payload, order/shift/refund/kasbon/audit services, receipt,
                  X/Z report layout, PDFs
    payments/     PaymentGateway: Midtrans through the Edge Functions, or the mock
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
                  print actions), customers (points, kasbon, installments), fnb (tables, kitchen tickets,
                  kitchen display), reports (dashboard, report
                  tabs, PDF/Excel export), sync_status, back_office
                  (shell, products, categories, suppliers, stock, import/export, promotions,
                  vouchers, store settings, shifts, audit log, customers, kasbon, loyalty, purchase
                  orders, transfers, dining tables)
test/             unit, sync and widget tests (in-memory SQLite, fake transport)
```
