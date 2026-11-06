import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/empty_state.dart';
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

    return Scaffold(
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              key: const Key('promo-add'),
              onPressed: () => context.go(AppRoutes.adminPromotion('new')),
              icon: const Icon(Icons.add),
              label: Text(l10n.commonAdd),
            )
          : null,
      body: promotions.isLoading
          ? const Center(child: CircularProgressIndicator())
          : promotions.hasError
          ? Center(child: Text(l10n.commonError('${promotions.error}')))
          : list.isEmpty
          ? EmptyState(icon: Icons.sell_outlined, message: l10n.promosEmpty)
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                96,
              ),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) {
                final p = list[i];
                return Card(
                  child: ListTile(
                    key: Key('promo-${p.id}'),
                    leading: CircleAvatar(child: Text('${p.priority}')),
                    title: Text(p.name),
                    subtitle: Text(
                      [
                        promoTypeLabel(l10n, p.type),
                        promoSummary(l10n, p),
                        if (p.storeIds.isNotEmpty)
                          l10n.promoStoreCount(p.storeIds.length),
                        if (p.isStackable) l10n.promoStackable,
                        if (!p.isActive) l10n.commonInactive,
                      ].join(' · '),
                    ),
                    trailing: canEdit ? const Icon(Icons.chevron_right) : null,
                    onTap: canEdit
                        ? () => context.go(AppRoutes.adminPromotion(p.id))
                        : null,
                  ),
                );
              },
            ),
    );
  }
}
