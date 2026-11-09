import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/buttons.dart';
import 'package:cashiera/core/design_system/widgets/data_display.dart';
import 'package:cashiera/core/design_system/widgets/empty_state.dart';
import 'package:cashiera/core/design_system/widgets/glass.dart';
import 'package:cashiera/core/design_system/widgets/toasts.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/core/pos/cart.dart';
import 'package:cashiera/core/pos/pos_config.dart';
import 'package:cashiera/core/pos/pos_services.dart';
import 'package:cashiera/core/providers.dart';
import 'package:cashiera/core/session/session_controller.dart';
import 'package:cashiera/features/customers/presentation/customer_providers.dart';
import 'package:cashiera/features/customers/presentation/points_dialog.dart';
import 'package:cashiera/features/fnb/kitchen_send.dart';
import 'package:cashiera/features/printing/print_actions.dart';
import 'package:cashiera/features/sell/presentation/quick_cash.dart';
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
    } on PosStateException catch (e) {
      if (context.mounted) AppToast.error(context, posErrorText(l10n, e));
    }
  }

  Future<void> _sendToKitchen(BuildContext context, WidgetRef ref) async {
    if (await sendToKitchen(context, ref) && inSheet && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _clear(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final cart = ref.read(cartControllerProvider);
    if (cart.gatewayTenders.isNotEmpty) {
      AppToast.error(context, l10n.sellClearPaidQris);
      return;
    }
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
    final fnb = ctx?.config.fnbMode ?? false;
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

    void pay({String? methodId, int? amount}) {
      final router = GoRouter.of(context);
      if (inSheet) Navigator.of(context).pop();
      router.go(AppRoutes.payWith(methodId: methodId, amount: amount));
    }

    // Same rule as canStartPayment, from the values watched above.
    final payable = !cart.isEmpty && bill != null && !needsApproval;
    final due = bill?.grandTotal ?? Money.zero;
    final tenders = (ctx?.config.paymentOptions ?? const <PaymentOption>[])
        .where((o) => o.kind != TenderKind.kasbon)
        .take(3)
        .toList();
    final cash = (ctx?.config.paymentOptions ?? const <PaymentOption>[])
        .where((o) => o.kind == TenderKind.cash)
        .firstOrNull;

    final header = Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
          child: const Icon(Icons.receipt_long_outlined, color: AppColors.text),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.cartTitle, style: theme.textTheme.headlineSmall),
              Text(
                cart.orderNumber ?? l10n.sellNewBill,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.textMuted,
                  fontFeatures: AppTypography.tabular,
                ),
              ),
            ],
          ),
        ),
        if (!cart.isEmpty)
          StatusChip(
            label: l10n.sellItemsCount(cart.itemCount),
            tone: StatusTone.primary,
          ),
        IconButton(
          key: const Key('sell-clear'),
          tooltip: l10n.sellClear,
          onPressed: cart.isEmpty ? null : () => _clear(context, ref),
          icon: const Icon(Icons.delete_sweep_outlined),
        ),
      ],
    );

    final customer = GlassCard(
      level: GlassLevel.subtle,
      radius: AppRadius.control,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          if (cart.customer == null)
            const Icon(Icons.person_outline, color: AppColors.textMuted)
          else
            InitialsAvatar(name: cart.customer!.name, size: 36),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              cart.customer?.name ?? l10n.cartWalkIn,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall,
            ),
          ),
          if (cart.customer != null)
            IconButton(
              tooltip: l10n.commonRemove,
              onPressed: () => controller.setCustomer(null),
              icon: const Icon(Icons.close, size: 18),
            ),
          Flexible(
            child: TextButton.icon(
              key: const Key('sell-customer'),
              onPressed: () async {
                final picked = await showCustomerPicker(context);
                if (picked != null) controller.setCustomer(picked);
              },
              icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
              label: Text(
                cart.customer == null ? l10n.sellAddCustomer : l10n.cartChange,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );

    Widget line(CartLine line) {
      final priced = lineBill[line.id];
      return InkWell(
        key: Key('cart-line-${line.sku}'),
        borderRadius: BorderRadius.circular(AppRadius.control),
        onTap: () => _lineMenu(context, ref, line),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      '${line.quantity.toPlain()} ${line.unitCode} × '
                      '${(line.unitPrice + line.modifiersUnitTotal).format()}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        fontFeatures: AppTypography.tabular,
                      ),
                    ),
                    for (final m in line.modifiers)
                      Text('+ ${m.name}', style: theme.textTheme.bodySmall),
                    if (line.note != null)
                      Text('"${line.note}"', style: theme.textTheme.bodySmall),
                    for (final d
                        in itemDiscounts[line.id] ?? const <AppliedDiscount>[])
                      Text(
                        '${d.description} -${d.amount.format()}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                  ],
                ),
              ),
              if (!line.allowDecimal) ...[
                _Stepper(
                  key: Key('cart-minus-${line.sku}'),
                  icon: Icons.remove,
                  onTap: () => controller.step(line.id, -1),
                ),
                SizedBox(
                  width: 28,
                  child: Text(
                    line.quantity.toPlain(),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontFeatures: AppTypography.tabular,
                    ),
                  ),
                ),
                _Stepper(
                  key: Key('cart-plus-${line.sku}'),
                  icon: Icons.add,
                  onTap: () => controller.step(line.id, 1),
                ),
              ],
              SizedBox(
                width: 96,
                child: Text(
                  (priced?.gross ?? Money.zero).format(),
                  textAlign: TextAlign.end,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: AppTypography.tabular,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final actions = Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        if (canDiscount)
          OutlinedButton.icon(
            key: const Key('sell-bill-discount'),
            onPressed: cart.isEmpty ? null : () => _billDiscount(context, ref),
            icon: const Icon(Icons.percent, size: 18),
            label: Text(l10n.sellDiscount),
          ),
        OutlinedButton.icon(
          key: const Key('sell-voucher'),
          onPressed: cart.isEmpty ? null : () => _voucher(context, ref),
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
          onPressed: cart.isEmpty ? null : () => _hold(context, ref),
          icon: const Icon(Icons.pause_circle_outline, size: 18),
          label: Text(l10n.sellHold),
        ),
        if (fnb && cart.hasKitchenItems)
          FilledButton.tonalIcon(
            key: const Key('sell-send-kitchen'),
            onPressed: pendingKitchenLines(cart).isEmpty
                ? null
                : () => _sendToKitchen(context, ref),
            icon: const Icon(Icons.soup_kitchen_outlined, size: 18),
            label: Text(l10n.kitchenSend),
          ),
      ],
    );

    final totals = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (bill != null) ...[
          totalRow(l10n.receiptSubtotal, bill.gross),
          if (bill.itemDiscount.rupiah > 0)
            totalRow(l10n.sellItemDiscounts, Money(-bill.itemDiscount.rupiah)),
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
          if (bill.voucherProblem != null)
            Text(
              voucherProblemText(l10n, bill.voucherProblem!),
              style: const TextStyle(color: AppColors.warningText),
            ),
          if (needsApproval)
            TextButton.icon(
              key: const Key('sell-request-approval'),
              onPressed: () => ensureDiscountApproval(context, ref),
              icon: const Icon(Icons.lock_outline, color: AppColors.warning),
              label: Text(l10n.sellNeedsApproval),
            ),
        ],
      ],
    );

    final totalCard = GlassCard(
      level: GlassLevel.solid,
      radius: AppRadius.tile,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.cartTotalDue.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 1,
              ),
            ),
          ),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                due.format(),
                key: const Key('sell-total'),
                style: theme.textTheme.displayMedium?.copyWith(
                  fontFeatures: AppTypography.tabular,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    final payment = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (tenders.isNotEmpty) ...[
          Text(
            l10n.cartPaymentMethod.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              for (final (i, o) in tenders.indexed) ...[
                if (i > 0) const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _TenderTile(
                    key: Key('cart-tender-${o.id}'),
                    option: o,
                    onTap: payable ? () => pay(methodId: o.id) : null,
                  ),
                ),
              ],
            ],
          ),
        ],
        if (cash != null && payable) ...[
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text(l10n.cartQuickCash, style: theme.textTheme.labelMedium),
                const SizedBox(width: AppSpacing.sm),
                for (final (i, amount) in quickCashAmounts(due.rupiah).indexed)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: ActionChip(
                      key: Key('cart-cash-$amount'),
                      label: Text(
                        i == 0 ? l10n.cartExact : Money(amount).format(),
                      ),
                      onPressed: () => pay(methodId: cash.id, amount: amount),
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        PrimaryButton(
          key: const Key('sell-pay'),
          label: l10n.sellPayAmount(due.format()),
          shortcut: inSheet ? null : 'F12',
          expand: true,
          onPressed: payable ? pay : null,
        ),
      ],
    );

    return GlassCard(
      level: GlassLevel.solid,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Material(
        type: MaterialType.transparency,
        child: Builder(
          builder: (context) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SizedBox(height: AppSpacing.md),
              customer,
              if (cart.tableId != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: InputChip(
                    key: const Key('sell-table'),
                    avatar: const Icon(
                      Icons.table_restaurant_outlined,
                      size: 18,
                    ),
                    label: Text(
                      l10n.ticketTable(
                        cart.tableName ?? '',
                        cart.guestCount ?? 0,
                      ),
                    ),
                    onDeleted: cart.version > 0 ? null : controller.clearTable,
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
              // Lines, bill actions and subtotals scroll; the total and the
              // ways to pay stay pinned below.
              Expanded(
                child: ListView(
                  children: [
                    if (cart.isEmpty)
                      EmptyState(
                        icon: Icons.shopping_basket_outlined,
                        message: l10n.sellEmpty,
                      )
                    else
                      for (final (i, l) in cart.lines.indexed) ...[
                        if (i > 0) const Divider(height: 1),
                        line(l),
                      ],
                    const SizedBox(height: AppSpacing.sm),
                    actions,
                    const SizedBox(height: AppSpacing.sm),
                    totals,
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              totalCard,
              const SizedBox(height: AppSpacing.md),
              payment,
            ],
          ),
        ),
      ),
    );
  }
}

/// Whether the bill can go to payment: items, a priced bill and no pending
/// discount approval. The Pay button and F12 both use it.
bool canStartPayment(WidgetRef ref, AppLocalizations l10n) {
  final cart = ref.read(cartControllerProvider);
  final bill = ref.read(currentBillProvider(discountLabels(l10n)));
  final ctx = ref.read(saleContextProvider);
  if (cart.isEmpty || bill == null) return false;
  final needsApproval =
      ctx != null &&
      bill.needsApproval(ctx.config.discountApprovalBps) &&
      cart.approvedBy == null;
  return !needsApproval;
}

/// A 48 dp round +/- stepper on a cart line.
class _Stepper extends StatelessWidget {
  const new({required this.icon, required this.onTap, super.key});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.white.withValues(alpha: 0.7),
        side: BorderSide(color: AppColors.hairline.withValues(alpha: 0.8)),
      ),
      icon: Icon(icon, size: 18, color: AppColors.text),
    );
  }
}

/// A payment-method tile: QRIS, card or cash.
class _TenderTile extends StatelessWidget {
  const new({required this.option, required this.onTap, super.key});

  final PaymentOption option;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (option.kind) {
      TenderKind.cash => Icons.payments_outlined,
      TenderKind.qris => Icons.qr_code_2,
      TenderKind.card => Icons.credit_card,
      TenderKind.transfer => Icons.account_balance_outlined,
      TenderKind.ewallet => Icons.account_balance_wallet_outlined,
      TenderKind.kasbon => Icons.request_quote_outlined,
    };
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: GlassCard(
        radius: AppRadius.control,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.md,
        ),
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: AppSpacing.xs),
            Text(
              option.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
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
