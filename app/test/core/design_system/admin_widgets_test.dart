import 'package:cashiera/core/design_system/theme.dart';
import 'package:cashiera/core/design_system/widgets/admin.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pump(WidgetTester t, Size size, Widget child) async {
  t.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    ),
  );
}

const filter = SizedBox(key: Key('f'), width: 200, height: 48);
const action = SizedBox(key: Key('a'), width: 120, height: 48);

Widget section() => const Scaffold(
  body: SingleChildScrollView(
    child: FormSection(
      title: 'Dasar',
      children: [
        SizedBox(key: Key('c0'), height: 40),
        SizedBox(key: Key('c1'), height: 40),
        SizedBox(key: Key('c2'), height: 40),
        FormFullWidth(SizedBox(key: Key('wide'), height: 40)),
      ],
    ),
  ),
);

void main() {
  testWidgets('toolbar: actions right of filters on wide screens', (t) async {
    await pump(
      t,
      const Size(1280, 800),
      const Scaffold(
        body: AdminToolbar(filters: [filter], actions: [action]),
      ),
    );
    final f = t.getTopLeft(find.byKey(const Key('f')));
    final a = t.getTopLeft(find.byKey(const Key('a')));
    expect(a.dx, greaterThan(f.dx + 300));
  });

  testWidgets('toolbar: actions under filters on phones', (t) async {
    await pump(
      t,
      const Size(390, 800),
      const Scaffold(
        body: AdminToolbar(filters: [filter], actions: [action]),
      ),
    );
    final f = t.getTopLeft(find.byKey(const Key('f')));
    final a = t.getTopLeft(find.byKey(const Key('a')));
    expect(a.dy, greaterThan(f.dy));
  });

  testWidgets('form section: two columns wide, one on phones', (t) async {
    await pump(t, const Size(1000, 800), section());
    final xs = {
      for (final k in ['c0', 'c1', 'c2']) t.getTopLeft(find.byKey(Key(k))).dx,
    };
    expect(xs, hasLength(2));
    final card = t.getSize(find.byType(FormSection)).width;
    expect(
      t.getSize(find.byKey(const Key('wide'))).width,
      greaterThan(card / 2),
    );

    await pump(t, const Size(390, 800), section());
    final phoneXs = {
      for (final k in ['c0', 'c1', 'c2']) t.getTopLeft(find.byKey(Key(k))).dx,
    };
    expect(phoneXs, hasLength(1));
  });

  testWidgets('admin page scrolls many rows on a phone', (t) async {
    await pump(
      t,
      const Size(390, 640),
      AdminPage(
        toolbar: const AdminToolbar(filters: [filter]),
        children: [for (var i = 0; i < 30; i++) Text('Baris $i')],
      ),
    );
    expect(t.takeException(), isNull);
    expect(find.byType(Scrollable), findsWidgets);
  });

  testWidgets('admin message puts the empty state on glass', (t) async {
    await pump(
      t,
      const Size(1280, 800),
      Scaffold(
        body: adminMessage(icon: Icons.inbox_outlined, message: 'Kosong'),
      ),
    );
    expect(find.text('Kosong'), findsOneWidget);
  });
}
