import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/admin.dart';
import 'package:cashiera/core/design_system/widgets/buttons.dart';
import 'package:cashiera/core/design_system/widgets/data_display.dart';
import 'package:cashiera/core/design_system/widgets/glass_table.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/core/pos/money_input.dart';
import 'package:cashiera/features/back_office/presentation/back_office_providers.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

String promoTypeLabel(AppLocalizations l10n, PromoType t) => switch (t) {
  PromoType.happyHour => l10n.promoTypeHappyHour,
  PromoType.buyXGetY => l10n.promoTypeBuyXGetY,
  PromoType.bundle => l10n.promoTypeBundle,
  PromoType.tieredQty => l10n.promoTypeTiered,
  PromoType.minPurchase => l10n.promoTypeMinPurchase,
};

String discountText(DiscountSpec d) => switch (d) {
  PercentDiscount(:final bps) => '${bpsToPercentText(bps)}%',
  FixedDiscount(:final amount) => Money(amount).format(),
};

/// One line about what a promotion does, for the list.
String promoSummary(AppLocalizations l10n, Promotion p) => switch (p.rules) {
  HappyHourRules(:final discount) => l10n.promoSummaryDiscount(
    discountText(discount),
  ),
  BuyXGetYRules(:final buyQuantity, :final getQuantity, :final getDiscount) =>
    l10n.promoSummaryBuyGet(
      buyQuantity,
      getQuantity,
      discountText(getDiscount),
    ),
  BundleRules(:final components, :final bundlePrice) => l10n.promoSummaryBundle(
    components.fold(0, (a, c) => a + c.quantity),
    Money(bundlePrice).format(),
  ),
  TieredQtyRules(:final tiers) =>
    tiers
        .map((t) => '${t.minQuantity}+ ${discountText(t.discount)}')
        .join(', '),
  MinPurchaseRules(:final minSubtotal, :final discount) =>
    l10n.promoSummaryMinPurchase(
      Money(minSubtotal).format(),
      discountText(discount),
    ),
};

class PromotionsScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final canEdit =
        ref.watch(principalProvider).value?.can('promo.manage') ?? false;
    final promotions = ref.watch(adminPromotionsProvider);
    final list = promotions.value ?? const <Promotion>[];

    final muted = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: AppColors.textMuted);
    return AdminPage(
      toolbar: AdminToolbar(
        actions: [
          if (canEdit)
            PrimaryButton(
              key: const Key('promo-add'),
              onPressed: () => context.go(AppRoutes.adminPromotion('new')),
              icon: Icons.add,
              label: l10n.commonAdd,
            ),
        ],
      ),
      children: [
        if (promotions.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (promotions.hasError)
          adminMessage(
            icon: Icons.cloud_off_outlined,
            message: l10n.commonError('${promotions.error}'),
          )
        else if (list.isEmpty)
          adminMessage(icon: Icons.sell_outlined, message: l10n.promosEmpty)
        else
          GlassTable<Promotion>(
            rows: list,
            onRowTap: canEdit
                ? (p) => context.go(AppRoutes.adminPromotion(p.id))
                : null,
            columns: [
              GlassColumn(
                label: l10n.promoGeneral,
                flex: 5,
                cell: (p) => Row(
                  key: Key('promo-${p.id}'),
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(AppRadius.control),
                      ),
                      child: Text(
                        '${p.priority}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            p.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            [
                              promoTypeLabel(l10n, p.type),
                              promoSummary(l10n, p),
                              if (p.storeIds.isNotEmpty)
                                l10n.promoStoreCount(p.storeIds.length),
                              if (p.isStackable) l10n.promoStackable,
                            ].join(' · '),
                            style: muted,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              GlassColumn(
                label: l10n.adminColStatus,
                cell: (p) => StatusChip(
                  label: p.isActive ? l10n.commonActive : l10n.commonInactive,
                  tone: p.isActive ? StatusTone.success : StatusTone.neutral,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
