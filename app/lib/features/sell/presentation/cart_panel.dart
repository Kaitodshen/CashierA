import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/empty_state.dart';
import 'package:cashiera/core/design_system/widgets/toasts.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/core/pos/cart.dart';
import 'package:cashiera/core/pos/pos_services.dart';
import 'package:cashiera/core/providers.dart';
import 'package:cashiera/core/session/session_controller.dart';
import 'package:cashiera/features/customers/presentation/customer_providers.dart';
import 'package:cashiera/features/customers/presentation/points_dialog.dart';
import 'package:cashiera/features/sell/presentation/sell_dialogs.dart';
import 'package:cashiera/features/sell/presentation/sell_providers.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Text for a voucher that cannot be used.
String voucherProblemText(AppLocalizations l10n, VoucherProblem p) =>
    switch (p) {
      VoucherProblem.inactive => l10n.voucherInactive,
      VoucherProblem.notStarted => l10n.voucherNotStarted,
      VoucherProblem.expired => l10n.voucherExpired,
      VoucherProblem.usedUp => l10n.voucherUsedUp,
      VoucherProblem.belowMinimum => l10n.voucherBelowMinimum,
    };

/// Asks for approval when the manual discounts are above the store limit.
/// Someone who may approve approves themselves. Returns false when no
/// approval was given.
Future<bool> ensureDiscountApproval(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final ctx = ref.read(saleContextProvider);
  final bill = ref.read(currentBillProvider(discountLabels(l10n)));
  final cart = ref.read(cartControllerProvider);
  if (ctx == null || bill == null) return false;
  if (!bill.needsApproval(ctx.config.discountApprovalBps) ||
      cart.approvedBy != null) {
    return true;
  }
  final controller = ref.read(cartControllerProvider.notifier);
  if (ctx.staff.can('pos.discount_override')) {
    controller.setApprover(ctx.staff.employeeId);
    return true;
  }
  final approver = await showApprovalDialog(
    context,
    permission: 'pos.discount_override',
    reason: l10n.approvalDiscountReason(
      (bill.maxManualBps / 100).toStringAsFixed(
        bill.maxManualBps % 100 == 0 ? 0 : 1,
      ),
      (ctx.config.discountApprovalBps / 100).toStringAsFixed(0),
    ),
  );
  if (approver == null) return false;
  controller.setApprover(approver.employeeId);
  return true;
}

class CartPanel extends ConsumerWidget {
  const new({this.inSheet = false, super.key});

  /// Shown in the phone layout's bottom sheet (closed before paying).
  final bool inSheet;

  Future<void> _lineMenu(
    BuildContext context,
    WidgetRef ref,
    CartLine line,
  ) async {
    final l10n = context.l10n;
    final controller = ref.read(cartControllerProvider.notifier);
    final staff = ref.read(sessionControllerProvider).value?.staff;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                line.displayName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(line.sku),
            ),
            ListTile(
              leading: const Icon(Icons.numbers),
              title: Text(l10n.sellChangeQuantity),
              onTap: () => Navigator.pop(context, 'qty'),
            ),
            if (staff?.can('pos.discount') ?? false)
              ListTile(
                key: const Key('line-discount'),
                leading: const Icon(Icons.percent),
                title: Text(l10n.sellLineDiscount),
                onTap: () => Navigator.pop(context, 'discount'),
              ),
            ListTile(
              leading: const Icon(Icons.sticky_note_2_outlined),
              title: Text(l10n.sellNote),
              onTap: () => Navigator.pop(context, 'note'),
            ),
            ListTile(
              key: const Key('line-remove'),
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: Text(l10n.sellRemove),
              onTap: () => Navigator.pop(context, 'remove'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    switch (action) {
      case 'qty':
        final qty = await showQuantityDialog(
          context,
          itemName: line.displayName,
          unitCode: line.unitCode,
          allowDecimal: line.allowDecimal,
          current: line.quantity,
        );
        if (qty != null) controller.setQuantity(line.id, qty);
      case 'discount':
        final spec = await showDiscountDialog(
          context,
          title: l10n.sellLineDiscount,
          current: line.manualDiscount,
        );
        if (spec == null) return;
        controller
          ..setLineDiscount(
            line.id,
            spec == const FixedDiscount(0) ? null : spec,
          )
          ..setApprover(null);
        if (context.mounted) await ensureDiscountApproval(context, ref);
      case 'note':
        final note = await showTextDialog(
          context,
          title: l10n.sellNote,
          label: l10n.sellNote,
          initial: line.note ?? '',
        );
        if (note != null) controller.setLineNote(line.id, note);
      case 'remove':
        controller.remove(line.id);
    }
  }

  Future<void> _billDiscount(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final controller = ref.read(cartControllerProvider.notifier);
    final spec = await showDiscountDialog(
      context,
      title: l10n.sellBillDiscount,
      current: ref.read(cartControllerProvider).billDiscount,
    );
    if (spec == null) return;
    controller
      ..setBillDiscount(spec == const FixedDiscount(0) ? null : spec)
      ..setApprover(null);
    if (context.mounted) await ensureDiscountApproval(context, ref);
  }

  Future<void> _voucher(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final controller = ref.read(cartControllerProvider.notifier);
    final current = ref.read(cartControllerProvider).voucherCode;
    if (current != null) {
      controller.setVoucher(null);
      return;
    }
    final code = await showTextDialog(
      context,
      title: l10n.voucherTitle,
      label: l10n.voucherCode,
      minLength: 3,
      tooShort: l10n.voucherCodeShort,
      upperCase: true,
    );
    if (code == null || code.isEmpty) return;
    final voucher = await ref
        .read(posConfigRepositoryProvider)
        .findVoucher(code);
    if (!context.mounted) return;
    if (voucher == null) {
      AppToast.error(context, l10n.voucherUnknown(code.toUpperCase()));
      return;
    }
    controller.setVoucher(voucher.code);
  }

  Future<void> _hold(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final ctx = ref.read(saleContextProvider);
    final bill = ref.read(currentBillProvider(discountLabels(l10n)));
    if (ctx == null || bill == null) return;
    if (!await ensureDiscountApproval(context, ref)) return;
    final cart = ref.read(cartControllerProvider);
    try {
      final held = await ref
          .read(orderServiceProvider)
          .hold(cart: cart, bill: bill, ctx: ctx);
      ref.read(cartControllerProvider.notifier).clear();
      ref.read(syncSchedulerProvider.notifier).syncNow().ignore();
      if (context.mounted) {
        AppToast.success(context, l10n.sellHeld(held.orderNumber!));
        if (inSheet) Navigator.of(context).pop();
      }
    } on PosPermissionException catch (e) {
      if (context.mounted) AppToast.error(context, l10n.commonError('$e'));
    }
  }

  Future<void> _clear(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final cart = ref.read(cartControllerProvider);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.sellClearTitle),
        content: Text(
          cart.version > 0 ? l10n.sellClearHeldHint : l10n.sellClearHint,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            key: const Key('sell-clear-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.sellClear),
          ),
        ],
      ),
    );
    if (ok ?? false) ref.read(cartControllerProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cart = ref.watch(cartControllerProvider);
    final bill = ref.watch(currentBillProvider(discountLabels(l10n)));
    final ctx = ref.watch(saleContextProvider);
    final controller = ref.read(cartControllerProvider.notifier);
    final canDiscount = ctx?.staff.can('pos.discount') ?? false;
    final needsApproval =
        bill != null &&
        ctx != null &&
        bill.needsApproval(ctx.config.discountApprovalBps) &&
        cart.approvedBy == null;
    final lineBill = {
      for (final l in bill?.lines ?? const <BillLine>[]) l.id: l,
    };
    final itemDiscounts = <String, List<AppliedDiscount>>{};
    for (final d in bill?.discounts ?? const <AppliedDiscount>[]) {
      if (d.lineId != null) {
        itemDiscounts.putIfAbsent(d.lineId!, () => []).add(d);
      }
    }

    Widget totalRow(
      String label,
      Money value, {
      bool strong = false,
      Key? key,
    }) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: strong ? theme.textTheme.titleMedium : null,
            ),
          ),
          Text(
            value.format(),
            key: key,
            style: strong
                ? theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  )
                : null,
          ),
        ],
      ),
    );

    return Material(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.sm,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    cart.orderNumber ?? l10n.sellNewBill,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  key: const Key('sell-clear'),
                  tooltip: l10n.sellClear,
                  onPressed: cart.isEmpty ? null : () => _clear(context, ref),
                  icon: const Icon(Icons.delete_sweep_outlined),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: InputChip(
              key: const Key('sell-customer'),
              avatar: const Icon(Icons.person_outline, size: 18),
              label: Text(cart.customer?.name ?? l10n.sellAddCustomer),
              onPressed: () async {
                final picked = await showCustomerPicker(context);
                if (picked != null) controller.setCustomer(picked);
              },
              onDeleted: cart.customer == null
                  ? null
                  : () => controller.setCustomer(null),
            ),
          ),
          const Divider(),
          Expanded(
            child: cart.isEmpty
                ? EmptyState(
                    icon: Icons.shopping_basket_outlined,
                    message: l10n.sellEmpty,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    itemCount: cart.lines.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final line = cart.lines[i];
                      final priced = lineBill[line.id];
                      return ListTile(
                        key: Key('cart-line-${line.sku}'),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        onTap: () => _lineMenu(context, ref, line),
                        title: Text(line.displayName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${line.quantity.toPlain()} ${line.unitCode} × '
                              '${(line.unitPrice + line.modifiersUnitTotal) //
                              .format()}',
                            ),
                            for (final m in line.modifiers) Text('+ ${m.name}'),
                            if (line.note != null) Text('"${line.note}"'),
                            for (final d
                                in itemDiscounts[line.id] ??
                                    const <AppliedDiscount>[])
                              Text(
                                '${d.description} -${d.amount.format()}',
                                style: const TextStyle(
                                  color: AppColors.success,
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!line.allowDecimal) ...[
                              IconButton(
                                key: Key('cart-minus-${line.sku}'),
                                onPressed: () => controller.step(line.id, -1),
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              IconButton(
                                key: Key('cart-plus-${line.sku}'),
                                onPressed: () => controller.step(line.id, 1),
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                            ],
                            SizedBox(
                              width: 88,
                              child: Text(
                                (priced?.gross ?? Money.zero).format(),
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (bill != null) ...[
                  totalRow(l10n.receiptSubtotal, bill.gross),
                  if (bill.itemDiscount.rupiah > 0)
                    totalRow(
                      l10n.sellItemDiscounts,
                      Money(-bill.itemDiscount.rupiah),
                    ),
                  for (final d in bill.discounts.where((d) => d.lineId == null))
                    totalRow(d.description, Money(-d.amount.rupiah)),
                  if (bill.serviceCharge.rupiah > 0)
                    totalRow(l10n.receiptService, bill.serviceCharge),
                  if (bill.tax.rupiah > 0)
                    totalRow(
                      ctx?.config.pricing.taxInclusive ?? true
                          ? l10n.sellTaxIncluded(ctx?.config.taxName ?? 'PPN')
                          : ctx?.config.taxName ?? 'PPN',
                      bill.tax,
                    ),
                  if (bill.rounding.rupiah != 0)
                    totalRow(l10n.receiptRounding, bill.rounding),
                  totalRow(
                    l10n.receiptTotal,
                    bill.grandTotal,
                    strong: true,
                    key: const Key('sell-total'),
                  ),
                  if (bill.voucherProblem != null)
                    Text(
                      voucherProblemText(l10n, bill.voucherProblem!),
                      style: const TextStyle(color: AppColors.warning),
                    ),
                  if (needsApproval)
                    TextButton.icon(
                      key: const Key('sell-request-approval'),
                      onPressed: () => ensureDiscountApproval(context, ref),
                      icon: const Icon(
                        Icons.lock_outline,
                        color: AppColors.warning,
                      ),
                      label: Text(l10n.sellNeedsApproval),
                    ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    if (canDiscount)
                      OutlinedButton.icon(
                        key: const Key('sell-bill-discount'),
                        onPressed: cart.isEmpty
                            ? null
                            : () => _billDiscount(context, ref),
                        icon: const Icon(Icons.percent, size: 18),
                        label: Text(l10n.sellDiscount),
                      ),
                    OutlinedButton.icon(
                      key: const Key('sell-voucher'),
                      onPressed: cart.isEmpty
                          ? null
                          : () => _voucher(context, ref),
                      icon: Icon(
                        cart.voucherCode == null
                            ? Icons.confirmation_number_outlined
                            : Icons.close,
                        size: 18,
                      ),
                      label: Text(cart.voucherCode ?? l10n.voucherTitle),
                    ),
                    if (cart.customer != null && bill != null)
                      _PointsButton(cart: cart, bill: bill),
                    OutlinedButton.icon(
                      key: const Key('sell-hold'),
                      onPressed: cart.isEmpty
                          ? null
                          : () => _hold(context, ref),
                      icon: const Icon(Icons.pause_circle_outline, size: 18),
                      label: Text(l10n.sellHold),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  key: const Key('sell-pay'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  onPressed: cart.isEmpty || bill == null || needsApproval
                      ? null
                      : () {
                          final router = GoRouter.of(context);
                          if (inSheet) Navigator.of(context).pop();
                          router.go(AppRoutes.pay);
                        },
                  child: Text(
                    l10n.sellPayAmount(
                      (bill?.grandTotal ?? Money.zero).format(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Spend the customer's points on this bill.
class _PointsButton extends ConsumerWidget {
  const new({required this.cart, required this.bill});

  final Cart cart;
  final Bill bill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final rules = ref.watch(posConfigProvider).value?.business.loyalty;
    final customer = ref.watch(customerRowProvider(cart.customer!.id)).value;
    if (rules == null || !rules.enabled || customer == null) {
      return const SizedBox.shrink();
    }
    final balance = customer.pointsBalance;
    final maximum = rules.redeemable(
      balance: balance,
      payable: bill.grandTotal + bill.pointsDiscount,
    );
    return OutlinedButton.icon(
      key: const Key('sell-points'),
      onPressed: cart.isEmpty || (maximum == 0 && bill.pointsRedeemed == 0)
          ? null
          : () async {
              final points = await showPointsDialog(
                context,
                balance: balance,
                maximum: maximum,
                current: bill.pointsRedeemed,
                rules: rules,
              );
              if (points == null) return;
              ref
                  .read(cartControllerProvider.notifier)
                  .setPointsToRedeem(points);
            },
      icon: const Icon(Icons.stars_outlined, size: 18),
      label: Text(
        bill.pointsRedeemed > 0
            ? l10n.pointsUsed(bill.pointsRedeemed)
            : l10n.pointsButton(balance),
      ),
    );
  }
}
