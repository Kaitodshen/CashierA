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

  test('glass shadows stay outside the translucent fill', () {
    // An inner shadow would show through the white and grey the card.
    for (final level in GlassLevel.values) {
      final shadows = glassDecoration(level: level).boxShadow!;
      expect(shadows.map((s) => s.blurStyle), everyElement(BlurStyle.outer));
    }
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
