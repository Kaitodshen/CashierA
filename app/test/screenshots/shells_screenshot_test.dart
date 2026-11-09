@Tags(['screenshots'])
library;

import 'dart:io';

import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/design_system/theme.dart';
import 'package:cashiera/core/design_system/visual_effects.dart';
import 'package:cashiera/core/design_system/widgets/app_background.dart';
import 'package:cashiera/core/design_system/widgets/data_display.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/features/back_office/presentation/admin_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../support/till_harness.dart';

/// Review screenshots of both shells, written to `test/screenshots/out/`
/// (git-ignored). Not goldens: nothing is compared.
Future<void> loadFonts() async {
  Future<void> family(String name, List<String> assets) async {
    final loader = FontLoader(name);
    for (final a in assets) {
      loader.addFont(rootBundle.load(a));
    }
    await loader.load();
  }

  await family('PlusJakartaSans', ['assets/fonts/PlusJakartaSans[wght].ttf']);
  await family('Inter', [
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold'])
      'assets/fonts/Inter-$w.ttf',
  ]);
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? '/root/flutter';
  final icons = File(
    '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  final bytes = await icons.readAsBytes();
  final loader = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.sublistView(bytes)));
  await loader.load();
}

const tablet = Size(1280, 800);
const phone = Size(390, 844);

Widget backOffice(String location) => ProviderScope(
  overrides: [visualEffectsProvider.overrideWith((ref) => Stream.value(true))],
  child: MaterialApp.router(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light(),
    locale: const Locale('id'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => AppBackground(child: child!),
    routerConfig: GoRouter(
      initialLocation: location,
      routes: [
        ShellRoute(
          builder: (_, _, child) => AdminShell(child: child),
          routes: [
            for (final path in [AppRoutes.admin, AppRoutes.adminProducts])
              GoRoute(path: path, builder: (_, _) => const _SamplePage()),
          ],
        ),
      ],
    ),
  ),
);

/// Placeholder content so the shell is seen with real building blocks.
class _SamplePage extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        PageHeader(
          title: 'Ringkasan toko',
          subtitle: 'Halaman ini didesain ulang di fase 3.',
        ),
        SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: 260,
              child: StatCard(
                icon: Icons.payments_outlined,
                label: 'Penjualan',
                value: 'Rp 14.850.000',
                badge: '+12,4%',
                footnote: 'Contoh data',
              ),
            ),
            SizedBox(
              width: 260,
              child: StatCard(
                icon: Icons.receipt_long_outlined,
                label: 'Transaksi',
                value: '142',
                tint: Color(0xFF6366F1),
                footnote: 'Contoh data',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A screenshot test with shadows drawn as on devices (flutter_test draws
/// them unblurred by default). The flag must be restored inside the body.
void shot(String description, Future<void> Function(WidgetTester t) body) {
  testWidgets(description, (t) async {
    debugDisableShadows = false;
    try {
      await body(t);
    } finally {
      debugDisableShadows = true;
    }
  });
}

void main() {
  setUpAll(loadFonts);

  for (final (name, size) in [('tablet', tablet), ('phone', phone)]) {
    shot('terminal register $name', (t) async {
      await openTill(t, size);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('out/terminal_register_$name.png'),
      );
    });

    shot('terminal overview $name', (t) async {
      final (_, c) = await openTill(t, size);
      await go(t, c, AppRoutes.shift);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('out/terminal_overview_$name.png'),
      );
    });

    for (final (page, location) in [
      ('overview', AppRoutes.admin),
      ('catalog', AppRoutes.adminProducts),
    ]) {
      shot('back office $page $name', (t) async {
        t.view
          ..physicalSize = size
          ..devicePixelRatio = 1;
        addTearDown(t.view.reset);
        await t.pumpWidget(backOffice(location));
        await t.pumpAndSettle();
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('out/back_office_${page}_$name.png'),
        );
      });
    }
  }
}
