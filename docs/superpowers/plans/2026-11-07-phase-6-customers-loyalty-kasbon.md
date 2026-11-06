# Phase 6: Customers, Loyalty and Kasbon Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** customers earn and redeem points at the till with correct balances, and a kasbon is repaid in installments (offline, any method) with a balance slip. The back office manages customers, points adjustments, kasbon follow-up and the loyalty settings.

**Architecture:**
- **`cashiera_core`:** loyalty rules (earn and redeem limits) and kasbon math (allocation oldest-first, aging).
- **Server (migration 1700):** the server re-checks points against `business_profile`. It adds `adjust_points`, `kasbon_overview` and `customer_statement`.
- **Terminal (Drift v5):**
  - mirrors this store's receivables
  - keeps local balances (points, kasbon paid) while outbox items are pending, like stock
  - `KasbonService` sends one `receivable_payment.create` per kasbon

**Tech stack:** existing stack, no new packages.

**Spec:** [phase-0 A6, A7, §8 Phase 6](../../phase-0-architecture.md), [supabase/README §5](../../../supabase/README.md) (`receivable_payment.create`, `customer.upsert`).

## Global Constraints

- **Points (A6):** earned = ⌊net_total / loyalty_earn_amount⌋ (net after discounts and points). Redeemed points are worth `loyalty_point_value` each. A redemption must reach `loyalty_min_redeem_points`. Loyalty off means no points at all. Points need a customer.
- **Kasbon (A7):**
  - It needs a named customer.
  - It is due after `kasbon_default_due_days`.
  - It is repaid at the store that issued it.
  - Cash repayments need an open shift and count in that shift's cash.
- **Offline:** a repayment is accepted up to the outstanding balance the terminal knows. Overpayment is refused on the terminal; the server still flags it if it happens.
- The balance shown never goes below 0 on the terminal. The server raises `LOYALTY_NEGATIVE` if two terminals redeem the same points.

## Review Focus

1. **Two installments then the rest:** the receivables go open → partial → paid; the balance slip shows the right remainder (server and terminal tests).
2. **Redeeming more points than the bill allows:** capped at what is left to pay. Below the minimum, nothing is redeemed (core test).
3. **A sale while offline, then a pull:** the local points balance is not overwritten by the older server figure while the sale is still in the outbox (pull test).
4. **Refunding a sale that was part kasbon, after the kasbon was repaid:** the repaid part becomes refundable (refund test).
5. **Voiding a kasbon sale that has repayments:** refused on the terminal, as the server does (`void_with_kasbon_payments`).

---

### Task 1: Core (`packages/cashiera_core/lib/src/loyalty/`)
- `LoyaltyRules{enabled, earnAmount, pointValue, minRedeemPoints}`
  - `pointsEarned(Money net)`
  - `redeemable({balance, payable})` → max points
  - `check(points, balance)` → `RedeemProblem?`
- `KasbonDebt{orderId, amount, paid, dueDate}` with `remaining`.
- `allocateRepayment(debts, amount)` → oldest due first, never above what is owed.
- `aging(debts, today)` → current, 1–30, 31–60, over 60 days late.
- Tests pin: the floor rule, the cap at payable, the minimum, oldest-first allocation, refusing an overpayment, the aging buckets.

### Task 2: Server (`1700_loyalty_kasbon.sql`, pgTAP `160_loyalty_kasbon.test.sql`)
- `validate_order_totals` adds:
  - `points_earned_mismatch`
  - `points_value_mismatch`
  - `points_below_minimum`
  - `loyalty_disabled`
- `adjust_points(customer_id, points, note)`:
  - needs `customer.manage`
  - refuses a balance below 0 (`points_insufficient`)
  - audit `loyalty.adjusted`
- `kasbon_overview(store_id)`: per customer and store, the outstanding, overdue and oldest due date. Needs `kasbon.manage` or `reports.view`.
- `customer_statement(customer_id)`: kasbon with its payments in the stores the caller may see, plus the last 100 ledger entries.

### Task 3: Terminal data and services (Drift v5)
- `LocalReceivables` (PK order_id): mirror of `receivables` for this store, plus kasbon sales made here.
- `LocalReceivablePayments`: repayments made on this terminal.
- Pull:
  - while order, refund or kasbon-repayment items are pending, keep the local `points_balance` and kasbon paid amount
  - otherwise take the server's
- On a completed sale: the points balance changes by earned − redeemed, and a kasbon line becomes a local receivable.
- `KasbonService`:
  - `debts(customerId)` and `repay(customerId, amount, method, ctx)`
  - repayments are allocated oldest due first
  - `receivable_payment.create` by `order_id`
  - returns a `RepaymentResult` for the slip
- Shift report: kasbon repaid in total and in cash. Refunds: repaid kasbon becomes refundable. Void: refused when the kasbon has repayments.

### Task 4: Till and terminal screens
- Cart: **Tukar poin** when the customer has points (balance, maximum, minimum). The order carries `points_redeemed` and `points_earned`.
- Receipt: points earned, redeemed and the new balance.
- `/pos/customers`:
  - search
  - detail: points, kasbon list with remaining and due dates, overdue in red
  - **Bayar kasbon**: amount, method, reference; prints a balance slip
  - add and edit a customer

### Task 5: Back office
- **Pelanggan**: list and search; edit name, phone, e-mail, kasbon limit and active; detail with points history, **Sesuaikan poin** and the kasbon statement.
- **Kasbon**: per store, outstanding by customer, overdue first, and the total.
- **Pengaturan → Loyalti & kasbon** (owner): loyalty on or off, Rp per point earned, Rp per point redeemed, minimum redeem, kasbon days.

### Task 6: Verify
- `dart format` and both analyzers are clean.
- Core, app and database tests pass.
- `flutter build web` succeeds.
- Docs are updated, and the plan gets its "As built" notes.

## As built (deviations)

- **A new `loyalty.adjust` permission (owner, manager).** `customer.manage` is held by cashiers too, and changing a points balance is like giving money, so `adjust_points` needs its own permission.
- **Earning is mandatory.** A sale with a customer always earns by the company rule; the server refuses any other figure. Two old database tests switched earning off for convenience; they now follow the rule. The test helper earns on net (A6), not the grand total.
- **Redeemed points are not given back by a refund.** Only a void returns them, as the server already did. A refund takes earned points back in proportion: ⌊earned × amount / grand total⌋, capped at what's left. The terminal mirrors this with `pointsReversedByRefunds`.
- **One installment row per kasbon paid.** A payment that covers two kasbon sends two `receivable_payment.create` items (by `order_id`), oldest due first.
- **Repayments are capped by what the terminal knows.** Another terminal's unsynced installment can still lead to an overpayment, which the server flags (`KASBON_OVERPAID`).
- **Back-office repayments are not built.** Installments are taken at the terminal (cash needs the till's open shift). The back office shows and follows up kasbon.
- **Bugs found while building:** none beyond the test fixtures above.
- **Verified on 2026-11-07:**
  - `dart format`, `flutter analyze` and `dart analyze` are clean.
  - Tests pass: core 122, app 135, database 18 files / 348 assertions.
  - `flutter build web` succeeds.
  - New app tests:
    - points and kasbon services: earning, redemption limits, void and refund reversal, oldest-first installments, shift kasbon cash
    - pull balance protection
    - till flows: points at checkout, two installments with balance slips
    - back-office customers, kasbon and loyalty settings
    - the v3 → v5 database upgrade
  - Not run on real devices or a live Supabase project.
- **Phase 5 review findings fixed (2026-11-07, migration 1800, pgTAP `170`):**
  - Approvals naming another employee are accepted only from a paired terminal.
  - Payments are allowed only on completed orders, and expected cash counts completed and voided sales only.
  - A cash in/out needs `pos.open_drawer` or a manager's PIN.
  - Sharing a finished sale's PDF marks it printed; later shares are audited copies.
  - After the fixes: core 122, app 137, database 19 files / 356 assertions, all passing.
