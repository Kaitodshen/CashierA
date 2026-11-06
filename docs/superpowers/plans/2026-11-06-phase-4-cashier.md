# Phase 4: Cashier, Pricing, Payments and Receipts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** a cashier on a paired terminal sells offline: scan or tap items, apply promos, manual discounts and vouchers, take cash, card, QRIS, transfer, e-wallet or kasbon (split allowed), and share or print a PDF receipt. The server books exactly the same numbers.

**Architecture:**
- **Pricing in `cashiera_core`** (pure Dart, TDD): promo engine, bill calculator and payment settlement. It produces the `order.upsert` money fields that `app.validate_order_totals` re-checks, so the server and the terminal can never disagree silently.
- **Terminal:** new mirrors (stores, settings, business profile, payment methods, promotions, vouchers, customers). A local orders table keeps every sale and held bill. Each sale writes the order row, the local stock change and the outbox item in one transaction.
- **Back office:** store settings (tax, rounding, receipt, discount threshold, kasbon), payment methods per store, promotions (atomic `save_promotion` RPC) and vouchers.

**Tech stack:** existing stack plus `pdf` and `printing` (receipt PDF, share, system print).

**Spec:** [phase-0 §4.5 money and tax, §4.8 payments, §8 Phase 4](../../phase-0-architecture.md), [supabase/README §5 order.upsert](../../../supabase/README.md), promotion rule shapes in migration `0500`.

## Global Constraints

- Money is integer rupiah; rates are basis points; quantities are `Qty` thousandths, sent as `"1.250"`.
- Calculation order (docs §4.5): line gross → item discounts (promos by priority, then manual) → bill discounts (bill promos, manual, voucher, then points) spread by largest remainder → service = round(net × bps / 10000) → tax inclusive `round(base × r / (10000 + r))` or exclusive `round(base × r / 10000)` → rounding (none/nearest/up/down to 50/100/500/1000) → tax spread over taxable lines by largest remainder.
- Server identities must hold: `net = gross − item − bill − points`, `grand = net + service + (exclusive ? tax : 0) + rounding`, Σ payments = grand, Σ non-kasbon = paid_total, change only on cash.
- Manual discount effective size = max(ceil(amount × 10000 / base), bps). Above `discount_approval_bps` needs `approved_by` with `pos.discount_override` (self allowed).
- Completed orders need an open shift; kasbon needs a customer, `kasbon_enabled` and `kasbon.manage`.
- Order numbers: `<STORE>-<TERMINAL>-<yyMMdd>-<0001>`, counted per terminal per store-local business date.
- Stores are WIB/WITA/WIT with fixed offsets +7/+8/+9 (no daylight saving).

## Review Focus

1. **A promo makes a line or the bill negative** (fixed discount above the price, stacked promos): amounts are capped at what is left; the total never goes below 0 (engine tests).
2. **Kg items** (`1.250 kg`) in promos: tiered counts the decimal quantity, buy-X-get-Y and bundles count whole units only (engine tests).
3. **Exact-cash and over-tender with split**: card plus cash with change; a non-cash tender above the amount due is refused (settlement tests).
4. **All lines PPN-exempt** (beras, telur): tax 0 with any settings; no tax allocated to exempt lines (engine tests).
5. **Resuming a held bill and finishing it**: the second snapshot has a higher version, and the same order id is completed, not duplicated (order service test).

---

### Task 1: Core pricing engine (`packages/cashiera_core/lib/src/pricing/`)

**Files:** `allocation.dart`, `promotion.dart`, `promo_engine.dart`, `bill.dart`, `settlement.dart`, tests `test/pricing/*_test.dart`.

**Produces:**
- `List<int> allocateLargestRemainder(int amount, List<int> weights)`
- `Promotion.fromJson(Map)` with `isActiveAt(DateTime storeLocal, String storeId)`; types `happy_hour, buy_x_get_y, bundle, tiered_qty, min_purchase`.
- `PricingLine{id, productId, variantId, categoryId, unitPrice, modifiersUnitTotal, quantity, isTaxable, manualDiscount?}`, `DiscountSpec.percent(bps) | DiscountSpec.fixed(amount)`.
- `PricingSettings{taxRateBps, taxInclusive, serviceChargeBps, serviceChargeTaxable, roundingMode, roundingUnit, discountApprovalBps}`.
- `BillCalculator.calculate(lines, settings, {promotions, now, storeId, billDiscount, voucher, pointsDiscount}) → Bill{lines, discounts, totals}`, where each `AppliedDiscount{source, lineId?, promotionId?, voucherId?, description, amount, bps}` maps 1:1 to `order_discounts`.
- `Bill.needsApproval` / `manualDiscountBps(...)`.
- `settle(grandTotal, tenders) → Settlement{payments, paidTotal, changeTotal, kasbonAmount}` or `SettlementError`.

Tests pin: docs example (Rp 25.000 → PPN 2.477), exclusive tax, service charge, each promo type, priority and non-stackable exclusivity, caps, voucher rules (min subtotal, max discount, expiry, used up), rounding modes, largest remainder sums, split payments and change.

### Task 2: Server additions (migration `1500_pos.sql`, pgTAP `130_pos.test.sql`)

- `save_promotion(p jsonb)`: promotion plus its store list in one transaction, `promo.manage`.
- Fix: a bill whose only taxable part is the service charge has no taxable line to carry the tax; the line-tax check then compares against 0 lines. The rule becomes: Σ line tax = tax_total when any line is taxable, else Σ line tax = 0.
- pgTAP: a completed order built exactly like the Dart engine output (promo + manual bill discount + split cash/card) is applied; a held order then completed with a higher version stays one order; `save_promotion` replaces the store list.

### Task 3: Terminal data (Drift v3)

- Mirrors: `local_payment_methods`, `local_store_payment_methods`, `local_promotions` (rules JSON), `local_promotion_stores`, `local_vouchers`, `local_customers`, `local_business_profile`; store and settings refresh on every pull.
- `local_shifts` (open shift per terminal), `local_orders` (id, number, status, version, cart JSON, payload JSON, totals, timestamps), `local_counters` (order sequence per business date).
- `ShiftService.open(...)` → `shift.open`; `OrderService.hold/complete/cancelHeld` → `order.upsert` with version + 1, local stock decrease on completion, all in one transaction. `CustomerService.quickAdd` → `customer.upsert`.

### Task 4: Cashier screens

- `/pos/sell`: product grid (favorites, categories, search, scanner), cart panel (qty, line discount, note, remove), customer, bill discount, voucher, hold, pay. Two-pane on tablets, cart sheet on phones.
- Payment sheet: due, methods enabled for the store, cash keypad with quick amounts, reference when required, split list, kasbon with due date.
- Receipt screen: on-screen receipt, share PDF, print (system dialog, then `order.mark_printed`), new sale.
- `/pos/orders`: today's sales and held bills (resume, cancel with reason), open receipt.
- Shift open dialog when there is no open shift. Manager approval dialog (staff + PIN, offline) for discounts above the threshold.

### Task 5: Back-office screens

- Store settings: tax on/off, rate, included or added, service charge, rounding, discount approval threshold, kasbon, receipt header and footer, paper width.
- Payment methods per store (enable, order).
- Promotions list and editor (type-specific rules, scope picker, schedule, stores, priority, stackable). Vouchers list and editor.

### Task 6: Verify

- `flutter analyze`, `dart analyze` clean; all Dart tests, database tests and `flutter build web` pass; READMEs and this plan's "As built" notes updated.

## As built (deviations)

- **Shift opening is in Phase 4.** Completed orders need a shift, so the cashier screen opens one (`shift.open`, opening cash). Closing it, and the X and Z reports, stay in Phase 5.
- **Manager approval is in Phase 4.** It is limited to discounts above the store limit and to cancelling held bills: a colleague with the permission picks their name and enters their PIN, checked offline. Phase 5 adds void-after-print, drawer and audit screens.
- **Small reference tables are JSON mirrors.** Payment methods, store payment methods, promotions, promotion stores, vouchers and the business profile are kept as JSON rows in `mirror_records`. Customers, shifts and orders are real tables. Promotion store-list deletions are applied from any store, because an empty list means every store.
- **Promotion semantics the spec left open:**
  - A fixed happy-hour or tier discount is per unit.
  - Buy X get Y gives the cheapest units as the "get" units.
  - Bundles take the most expensive units and spread the saving by unit value.
  - Weighed quantities count only as whole units for buy X get Y and bundles.
  - A non-stackable bill promotion stops the bill promotions after it.
  - These rules are pinned in `promo_engine_test.dart`.
- **Receipt PDF fonts.** The receipt PDF uses the built-in Courier font. Characters outside Latin-1 print as `?`.
- **Riverpod providers.** Providers that return Drift rows (open shift, held and today's orders) are written by hand, because riverpod_generator cannot name Drift types.
- **Loyalty is engine-only for now.** Earning and redeeming points works in the engine (`PointsRedemption`), but the till shows it in Phase 6. `points_earned` is sent as 0.
- **Verified on 2026-11-06:**
  - `flutter analyze` and `dart analyze` are clean.
  - Tests pass: core 86, app 96 (including full offline sales at tablet and phone width), database 15 files / 263 assertions.
  - `flutter build web` succeeds.
  - Not yet run against a live Supabase project. Terminal screens were exercised only in widget tests, since this PC cannot build Android or Windows.
