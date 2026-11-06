import 'package:cashiera/core/design_system/widgets/pin_pad.dart';
import 'package:cashiera/core/design_system/widgets/sync_status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('PinPad', () {
    Future<List<String>> pumpPad(WidgetTester tester) async {
      final submitted = <String>[];
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpLocalized(PinPad(onSubmitted: submitted.add));
      return submitted;
    }

    Future<void> tapKeys(WidgetTester tester, String keys) async {
      for (final k in keys.split('')) {
        await tester.tap(find.byKey(Key('pin-key-$k')));
      }
      await tester.pump();
    }

    testWidgets('submits the typed PIN once and clears', (tester) async {
      final submitted = await pumpPad(tester);
      await tapKeys(tester, '482913');
      await tester.tap(find.byKey(const Key('pin-key-ok')));
      await tester.pump();
      expect(submitted, ['482913']);

      await tester.tap(find.byKey(const Key('pin-key-ok')));
      await tester.pump();
      expect(submitted, ['482913'], reason: 'empty pad does not submit');
    });

    testWidgets('backspace removes the last digit', (tester) async {
      final submitted = await pumpPad(tester);
      await tapKeys(tester, '48291');
      await tester.tap(find.byKey(const Key('pin-key-backspace')));
      await tapKeys(tester, '93');
      await tester.tap(find.byKey(const Key('pin-key-ok')));
      expect(submitted, ['482993']);
    });

    testWidgets('fewer than 4 digits is not submitted', (tester) async {
      final submitted = await pumpPad(tester);
      await tapKeys(tester, '482');
      await tester.tap(find.byKey(const Key('pin-key-ok')));
      expect(submitted, isEmpty);
    });

    testWidgets('stops at 6 digits', (tester) async {
      final submitted = await pumpPad(tester);
      await tapKeys(tester, '48291377');
      await tester.tap(find.byKey(const Key('pin-key-ok')));
      expect(submitted, ['482913']);
    });

    testWidgets('a hardware keyboard or numpad works', (tester) async {
      final submitted = await pumpPad(tester);
      for (final key in [
        LogicalKeyboardKey.digit1,
        LogicalKeyboardKey.digit5,
        LogicalKeyboardKey.digit9,
        LogicalKeyboardKey.digit2,
      ]) {
        await tester.sendKeyEvent(key);
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(submitted, ['1592']);
    });
  });

  group('SyncStatusChip', () {
    testWidgets('offline with pending items (Indonesian)', (tester) async {
      await tester.pumpLocalized(
        const SyncStatusChip(online: false, pending: 3),
      );
      expect(find.text('Offline · 3 tertunda'), findsOneWidget);
    });

    testWidgets('online and fully synced (English)', (tester) async {
      await tester.pumpLocalized(
        const SyncStatusChip(online: true, pending: 0),
        locale: const Locale('en'),
      );
      expect(find.text('Online'), findsOneWidget);
    });

    testWidgets('online with pending items (English)', (tester) async {
      await tester.pumpLocalized(
        const SyncStatusChip(online: true, pending: 1),
        locale: const Locale('en'),
      );
      expect(find.text('Online · 1 pending'), findsOneWidget);
    });
  });
}
