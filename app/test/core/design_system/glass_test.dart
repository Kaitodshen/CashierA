import 'package:cashiera/core/database/app_database.dart';
import 'package:cashiera/core/design_system/visual_effects.dart';
import 'package:cashiera/core/design_system/widgets/app_background.dart';
import 'package:cashiera/core/design_system/widgets/glass.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('GlassBlur blurs only while visual effects are on', (t) async {
    for (final on in [true, false]) {
      await t.pumpWidget(
        ProviderScope(
          key: ValueKey(on),
          overrides: [
            visualEffectsProvider.overrideWith((ref) => Stream.value(on)),
          ],
          child: const MaterialApp(
            home: GlassBlur(
              borderRadius: BorderRadius.zero,
              child: SizedBox(width: 10, height: 10),
            ),
          ),
        ),
      );
      await t.pump();
      expect(find.byType(BackdropFilter), on ? findsOneWidget : findsNothing);
    }
  });

  test('visual effects default on and persist off', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = VisualEffectsRepository(db);
    expect(await repo.watch().first, isTrue);
    await repo.set(enabled: false);
    expect(await repo.watch().first, isFalse);
    await repo.set(enabled: true);
    expect(await repo.watch().first, isTrue);
  });

  testWidgets('AppBackground paints no blur filter', (t) async {
    await t.pumpWidget(
      const MaterialApp(home: AppBackground(child: SizedBox())),
    );
    expect(find.byType(BackdropFilter), findsNothing);
    expect(
      find.descendant(
        of: find.byType(AppBackground),
        matching: find.byType(RepaintBoundary),
      ),
      findsWidgets,
    );
  });

  test('glass fills let the background through, like Stitch', () {
    expect(GlassLevel.subtle.alpha, lessThanOrEqualTo(0.15));
    expect(GlassLevel.regular.alpha, lessThanOrEqualTo(0.3));
    // Text-heavy surfaces stay readable but are still glass.
    expect(GlassLevel.solid.alpha, inInclusiveRange(0.45, 0.65));
  });

  test('the decoration itself draws no shadow under the translucent fill', () {
    // GlassCard paints its shadow with the card cut out (as CSS does); a
    // BoxShadow would show through the glass and grey it.
    for (final level in GlassLevel.values) {
      expect(glassDecoration(level: level).boxShadow, isNull);
    }
  });

  testWidgets('GlassCard paints a cut-out shadow behind itself', (t) async {
    await t.pumpWidget(const MaterialApp(home: GlassCard(child: Text('card'))));
    expect(
      find.descendant(
        of: find.byType(GlassCard),
        matching: find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is GlassShadowPainter,
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the whole GlassCard is tappable, not just its content', (
    t,
  ) async {
    var taps = 0;
    await t.pumpWidget(
      MaterialApp(
        home: Row(
          children: [
            Expanded(
              child: GlassCard(
                key: const Key('wide'),
                onTap: () => taps++,
                child: const Text('x'),
              ),
            ),
          ],
        ),
      ),
    );
    final rect = t.getRect(find.byKey(const Key('wide')));
    await t.tapAt(rect.centerRight - const Offset(8, 0));
    expect(taps, 1);
  });

  testWidgets('GlassCard is tappable only with onTap', (t) async {
    var taps = 0;
    await t.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            GlassCard(onTap: () => taps++, child: const Text('tap me')),
            const GlassCard(level: GlassLevel.solid, child: Text('static')),
          ],
        ),
      ),
    );
    await t.tap(find.text('tap me'));
    expect(taps, 1);
    expect(
      find.ancestor(of: find.text('static'), matching: find.byType(InkWell)),
      findsNothing,
    );
  });
}
