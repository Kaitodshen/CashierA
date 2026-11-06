import 'package:cashiera/core/design_system/theme.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/features/back_office/data/back_office_backend.dart';
import 'package:cashiera/features/back_office/data/pos_admin_repository.dart';
import 'package:cashiera/features/back_office/presentation/back_office_providers.dart';
import 'package:cashiera/features/back_office/presentation/promotion_editor_screen.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toastification/toastification.dart';

void main() {
  testWidgets('every promotion type renders its rule fields', (tester) async {
    tester.view
      ..physicalSize = const Size(1000, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          promotionScopeOptionsProvider.overrideWith(
            (ref) async => const ScopeOptions(
              categories: [ScopeOption(id: 'c-1', label: 'Minuman')],
              products: [ScopeOption(id: 'p-1', label: 'Mie Goreng')],
              variants: [
                ScopeOption(id: 'v-1', label: 'Air 600 ml', detail: 'AIR-600'),
              ],
            ),
          ),
          backOfficeStoresProvider.overrideWith(
            (ref) async => const [
              StoreSummary(id: 's-1', code: 'PST', name: 'Pusat'),
            ],
          ),
        ],
        child: ToastificationWrapper(
          child: MaterialApp(
            theme: AppTheme.backOffice(),
            locale: const Locale('id'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const PromotionEditorScreen(promotionId: 'new'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final expectations = {
      PromoType.happyHour: 'Diskon (Rp per unit)',
      PromoType.buyXGetY: 'Jumlah beli',
      PromoType.bundle: 'Harga paket',
      PromoType.tieredQty: 'Tambah tingkat',
      PromoType.minPurchase: 'Minimal belanja',
    };
    for (final MapEntry(key: type, value: label) in expectations.entries) {
      await tester.tap(find.byKey(const Key('promo-type')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_typeLabels[type]!).last);
      await tester.pumpAndSettle();
      expect(find.text(label), findsWidgets, reason: type.code);
    }

    // Saving without a name explains why instead of calling the server.
    await tester.tap(find.byKey(const Key('promo-save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Isi nama promo.', findRichText: true), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}

const Map<PromoType, String> _typeLabels = {
  PromoType.happyHour: 'Diskon jam tertentu',
  PromoType.buyXGetY: 'Beli X gratis/diskon Y',
  PromoType.bundle: 'Paket harga',
  PromoType.tieredQty: 'Diskon grosir (jumlah)',
  PromoType.minPurchase: 'Minimal belanja',
};
