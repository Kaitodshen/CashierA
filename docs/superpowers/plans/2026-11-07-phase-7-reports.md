# Phase 7: Dashboard and Reports Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** owners and managers see a dashboard and the sales, payment, product, staff, tax and stock-value reports for one store or all of their stores, over any period. Every report exports to PDF and Excel, and the numbers reconcile with each other and with the orders.

**Architecture:**
- **Server (migration 1900):** one `SECURITY DEFINER` RPC per report. Each takes `p_store_id` (null = every store the caller may see with `reports.view`) and an inclusive `business_date` range, and reads the existing `(store_id, business_date)` indexes.
- **App:**
  - a `ReportsRepository` that parses each RPC into small models
  - one generic `ReportTable` (title, columns, rows, totals) for PDF and XLSX export
  - back-office screens, with charts from `fl_chart ^1.3.0` (Phase 0 dependency list)

**Tech stack:** existing stack plus `fl_chart`.

**Spec:** [phase-0 §8 Phase 7, R15](../../phase-0-architecture.md).

## Global Constraints

- Sales are completed orders by their `business_date` (store-local, so WIB/WITA/WIT stores each use their own day).
  - Voids are reported separately, by the voided order's business date. They are not in sales.
  - Refunds are reported by the refund's business date. **Net sales = grand total − refunds.**
- Reconciliation identities (pinned by pgTAP `180`):
  - Σ by_day = Σ by_store = totals
  - Σ payments by method = grand total
  - Σ product net = net total, and Σ category net = net total
  - Σ staff grand = grand total
  - tax report total = tax total
  - DPP + PPN = taxable base (inclusive tax)
- Money is integer rupiah; quantities are sent as numeric and parsed to `Qty`.
- Reports are online only (A12) and use the back office; terminals keep their X/Z reports.

## Review Focus

1. **A day with no sales** appears as zero in the daily series. The chart and table show no gaps.
2. **A WITA store and a WIB store in one "all stores" report:** each uses its own business date (pgTAP: a sale at 23:30 WIB is that store's day).
3. **A refund in a later period than its sale:** it reduces that later period's net sales. The product report shows refunded quantity against the sale's period.
4. **A manager with one store asks for all stores:** they get only their store. Asking for another store is `permission_denied`.
5. **An export with Indonesian text:** XLSX keeps the text exactly. The PDF uses a Latin-1 font, so unsupported characters become `?`, as on receipts.

---

### Task 1: Server (`1900_reports.sql`, pgTAP `180_reports.test.sql`)
- `report_sales(store, from, to)`:
  - totals: orders, items, gross, discounts, net, service, tax, rounding, grand, average, refunds, net sales, voids
  - `by_day` (every date in the range), `by_hour` (store-local hour), `by_store`
- `report_payments(store, from, to)`: by payment method (count, amount), refunds by method, kasbon issued and repaid.
- `report_products(store, from, to, limit)`: by variant (qty sold, qty refunded, net, cost, margin) and by category.
- `report_staff(store, from, to)`: by cashier (orders, grand, average, discounts given, voids, refunds).
- `report_tax(store, from, to)`: by day, taxable base, DPP, tax, exempt sales.
- `report_stock_value(store)`: by store and variant (qty, cost, value), totals, and counts of negative and low items.
- `dashboard_summary(store, today)`:
  - today and yesterday totals, the last 7 days
  - today's top 5 products and payment mix
  - open shifts, low-stock and other open alerts, overdue kasbon
- pgTAP:
  - a three-day scenario in PST plus one sale in TGR, with split payments, a kasbon, a void and a refund on a later day
  - every identity above, plus hand-computed figures
  - store scope and permissions

### Task 2: App data and export
- `ReportsRepository` and models; `ReportPeriod` presets (today, yesterday, 7 days, this month, last month, custom).
- `ReportTable` → `buildReportPdf` (A4, landscape when there are more than 6 columns) and `buildReportXlsx` (numbers as numbers, a totals row). Both are saved with `saveBytes`.

### Task 3: Screens
- **Dashboard** (back-office home):
  - store filter
  - cards for today vs yesterday
  - a 7-day bar chart, top products and payment mix
  - alerts: low stock, overdue kasbon, open shifts
- **Laporan** page with tabs (Penjualan, Pembayaran, Produk, Staf, Pajak, Nilai stok):
  - store and period filters
  - each tab has a chart where useful, a table, and **PDF** / **Excel** buttons

### Task 4: Verify
- `dart format` and the analyzers are clean.
- Core, app and database tests pass.
- `flutter build web` succeeds.
- Docs are updated, and the plan gets its "As built" notes.

## As built (deviations)

- **No demo sales in the seed.** The seed has no orders, so "reconciles with the seed scenarios" is proven by a fixed scenario in `180_reports.test.sql`:
  - three days in Pusat (split payments, a kasbon, a void, a refund on a later day, an empty day)
  - one sale in Tangerang moved to WITA, at 00:30 local time
  - every identity and the hand-computed figures are checked against it
- **The product report lists at most 500 variants** (largest net first). The screen says when more were sold, and the totals still cover everything.
- **"Today" on the dashboard is the browser's date.** Each store's sales still use that store's own business date.
- **PDF text uses the built-in Helvetica (Latin-1)**, like the receipts. Dates use a plain hyphen, and Excel keeps every character.
- **Stock value ignores negative stock** (it adds no value). The negative count is shown separately.
- **Verified on 2026-11-07:**
  - `dart format` and the analyzers are clean.
  - Tests pass: core 122, app 144, database 20 files / 386 assertions.
  - `flutter build web` succeeds.
  - New app tests cover:
    - period presets, including last month across a year boundary
    - the percent helper and the change against yesterday
    - Σ rows = the totals row
    - Excel cells (numbers as numbers)
    - the PDF for a wide table
    - the reports screen (the empty day shows, the payment share, a new period reloads)
    - the dashboard (today against yesterday, the attention chips)
  - Not run against a live Supabase project.
