import 'package:cashiera/core/design_system/widgets/buttons.dart';
import 'package:cashiera/core/design_system/widgets/data_display.dart';
import 'package:cashiera/core/design_system/widgets/glass.dart';
import 'package:cashiera/core/design_system/widgets/glass_table.dart';
import 'package:cashiera/core/design_system/widgets/inputs.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('InitialsAvatar takes up to two initials', (t) async {
    await t.pumpLocalized(const InitialsAvatar(name: 'Amanda Pratiwi'));
    expect(find.text('AP'), findsOneWidget);
    await t.pumpLocalized(const InitialsAvatar(name: 'budi'));
    expect(find.text('B'), findsOneWidget);
    await t.pumpLocalized(const InitialsAvatar(name: '  '));
    expect(find.text('?'), findsOneWidget);
  });

  testWidgets('ProductThumb falls back to initials without an image', (
    t,
  ) async {
    await t.pumpLocalized(const ProductThumb(name: 'Kopi Susu'));
    expect(find.text('KS'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    await t.pumpLocalized(const ProductThumb(name: 'Teh', imageUrl: ''));
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('PrimaryButton shows its shortcut, keeps 48 dp and taps', (
    t,
  ) async {
    var taps = 0;
    await t.pumpLocalized(
      PrimaryButton(label: 'Bayar', shortcut: 'F12', onPressed: () => taps++),
    );
    expect(find.text('F12'), findsOneWidget);
    expect(
      t.getSize(find.byType(PrimaryButton)).height,
      greaterThanOrEqualTo(48),
    );
    await t.tap(find.text('Bayar'));
    expect(taps, 1);
  });

  testWidgets('disabled PrimaryButton ignores taps', (t) async {
    await t.pumpLocalized(const PrimaryButton(label: 'Bayar', onPressed: null));
    await t.tap(find.text('Bayar'), warnIfMissed: false);
    // No exception and nothing to count: the button has no callback.
    expect(t.takeException(), isNull);
  });

  testWidgets('ChipTabs reports the tapped item', (t) async {
    String? picked;
    await t.pumpLocalized(
      ChipTabs<String>(
        items: const [('all', 'Semua'), ('drink', 'Minuman')],
        selected: 'all',
        onSelected: (v) => picked = v,
      ),
    );
    await t.tap(find.text('Minuman'));
    expect(picked, 'drink');
  });

  testWidgets('MoneyText uses the rupiah format', (t) async {
    await t.pumpLocalized(const MoneyText(Money(145000)));
    expect(find.text('Rp 145.000'), findsOneWidget);
  });

  testWidgets('GlassTable shows uppercase headers on wide screens', (t) async {
    t.view
      ..physicalSize = const Size(1280, 800)
      ..devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpLocalized(
      const SizedBox(
        width: 900,
        child: GlassTable<String>(
          columns: [GlassColumn(label: 'Produk', cell: Text.new)],
          rows: ['Teh', 'Kopi'],
        ),
      ),
    );
    expect(find.text('PRODUK'), findsOneWidget);
    expect(find.text('Kopi'), findsOneWidget);
  });

  testWidgets('GlassTable becomes cards on phones', (t) async {
    t.view
      ..physicalSize = const Size(360, 740)
      ..devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpLocalized(
      const GlassTable<String>(
        columns: [GlassColumn(label: 'Produk', cell: Text.new)],
        rows: ['Teh'],
      ),
    );
    expect(find.text('PRODUK'), findsNothing);
    expect(find.byType(GlassCard), findsOneWidget);
    expect(find.text('Teh'), findsOneWidget);
  });

  test('StockBar clamps its fraction', () {
    expect(
      const StockBar(fraction: 1.7, tone: StatusTone.success).clampedFraction,
      1,
    );
    expect(
      const StockBar(fraction: -1, tone: StatusTone.error).clampedFraction,
      0,
    );
  });

  testWidgets('StatCard shows label, value, badge and footnote', (t) async {
    await t.pumpLocalized(
      const SizedBox(
        width: 300,
        child: StatCard(
          icon: Icons.payments_outlined,
          label: 'Penjualan',
          value: 'Rp 14.850.000',
          badge: '+12%',
          footnote: '142 transaksi',
        ),
      ),
    );
    // Labels are uppercase, as in the Stitch stat cards.
    for (final s in ['PENJUALAN', 'Rp 14.850.000', '+12%', '142 transaksi']) {
      expect(find.text(s), findsOneWidget);
    }
  });

  testWidgets('PageHeader stacks actions on narrow widths without overflow', (
    t,
  ) async {
    t.view
      ..physicalSize = const Size(360, 740)
      ..devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpLocalized(
      PageHeader(
        title: 'Katalog Barang',
        subtitle: 'Stok, varian dan harga',
        actions: [
          SecondaryButton(label: 'Ekspor CSV', onPressed: () {}),
          PrimaryButton(label: 'Tambah produk', onPressed: () {}),
        ],
      ),
    );
    expect(t.takeException(), isNull);
    expect(find.text('Tambah produk'), findsOneWidget);
  });
}
