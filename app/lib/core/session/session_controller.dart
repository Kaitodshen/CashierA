import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/auth/models.dart';
import 'package:cashiera/core/auth/pairing_code.dart';
import 'package:cashiera/core/database/app_database.dart';
import 'package:cashiera/core/providers.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_controller.g.dart';

@immutable
class SessionState {
  const new(this.mode, {this.device, this.store, this.staff});

  final AppMode mode;
  final LocalDeviceRow? device;
  final StoreSnapshot? store;

  /// The PIN-verified person on duty (terminal modes only).
  final StaffMember? staff;
}

/// Decides the app mode at startup and owns the transitions: pair, unlock,
/// lock, sign in, sign out.
@Riverpod(keepAlive: true)
class SessionController extends _$SessionController {
  @override
  Future<SessionState> build() async {
    if (!ref.watch(appEnvProvider).isConfigured) {
      return const SessionState(AppMode.setupRequired);
    }
    if (!kIsWeb) {
      final terminal = await ref.read(terminalRepositoryProvider).load();
      if (terminal != null) {
        return SessionState(
          AppMode.terminalLocked,
          device: terminal.device,
          store: terminal.store,
        );
      }
    }
    if (ref.read(backOfficeBackendProvider).hasStaffSession) {
      return const SessionState(AppMode.backOffice);
    }
    return const SessionState(AppMode.signedOut);
  }

  SessionState? get _current => state.value;

  /// Pairs this device as a terminal. Network calls happen first; local data
  /// is written only when all of them succeeded.
  Future<PairedDevice> pair(String rawCode) async {
    final code = normalizePairingCode(rawCode);
    final backend = ref.read(terminalBackendProvider);
    final info = await PackageInfo.fromPlatform();
    final device = await backend.pair(
      code,
      platform: defaultTargetPlatform.name,
      appVersion: info.version,
    );
    final store = await backend.fetchStore(device.storeId);
    final roster = await backend.fetchRoster();
    final repo = ref.read(terminalRepositoryProvider);
    await repo.savePairing(device, store, roster);
    final terminal = await repo.load();
    state = AsyncData(
      SessionState(
        AppMode.terminalLocked,
        device: terminal?.device,
        store: terminal?.store,
      ),
    );
    return device;
  }

  /// Downloads the latest staff list and PIN hashes.
  Future<void> refreshRoster() async {
    final roster = await ref.read(terminalBackendProvider).fetchRoster();
    await ref.read(terminalRepositoryProvider).replaceRoster(roster);
  }

  void unlock(StaffMember staff) {
    final current = _current;
    if (current == null || !isTerminalMode(current.mode)) return;
    state = AsyncData(
      SessionState(
        AppMode.terminalUnlocked,
        device: current.device,
        store: current.store,
        staff: staff,
      ),
    );
  }

  void lock() {
    final current = _current;
    if (current == null || !isTerminalMode(current.mode)) return;
    state = AsyncData(
      SessionState(
        AppMode.terminalLocked,
        device: current.device,
        store: current.store,
      ),
    );
  }

  Future<void> signIn({required String email, required String password}) async {
    await ref
        .read(backOfficeBackendProvider)
        .signIn(email: email.trim(), password: password);
    state = const AsyncData(SessionState(AppMode.backOffice));
  }

  Future<void> signOut() async {
    await ref.read(backOfficeBackendProvider).signOut();
    state = const AsyncData(SessionState(AppMode.signedOut));
  }
}
