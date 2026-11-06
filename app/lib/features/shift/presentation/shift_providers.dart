import 'package:cashiera/core/database/app_database.dart';
import 'package:cashiera/core/providers.dart';
import 'package:cashiera/core/session/session_controller.dart';
import 'package:cashiera/features/sell/presentation/sell_providers.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

// Written by hand: riverpod_generator cannot name Drift row types.

/// This terminal's shifts, newest first.
final StreamProvider<List<ShiftRow>> recentShiftsProvider =
    StreamProvider.autoDispose<List<ShiftRow>>(
      (ref) => ref.watch(shiftServiceProvider).watchRecent(),
    );

final StreamProviderFamily<List<CashMovementRow>, String>
shiftMovementsProvider = StreamProvider.autoDispose
    .family<List<CashMovementRow>, String>(
      (ref, shiftId) => ref.watch(shiftServiceProvider).watchMovements(shiftId),
    );

/// The live X (open) or Z (closed) report of one shift, from local rows.
final StreamProviderFamily<ShiftReport?, String> shiftReportProvider =
    StreamProvider.autoDispose.family<ShiftReport?, String>((
      ref,
      shiftId,
    ) async* {
      final config = ref.watch(posConfigProvider).value;
      final device = ref.watch(
        sessionControllerProvider.select((s) => s.value?.device?.deviceCode),
      );
      if (config == null) return;
      final service = ref.watch(shiftServiceProvider);
      final shift = await service.find(shiftId);
      if (shift == null) {
        yield null;
        return;
      }
      yield* service.watchReport(shift, config: config, deviceCode: device);
    });
