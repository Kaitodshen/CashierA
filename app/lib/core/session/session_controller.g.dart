// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Decides the app mode at startup and owns the transitions: pair, unlock,
/// lock, sign in, sign out.

@ProviderFor(SessionController)
final sessionControllerProvider = SessionControllerProvider._();

/// Decides the app mode at startup and owns the transitions: pair, unlock,
/// lock, sign in, sign out.
final class SessionControllerProvider
    extends $AsyncNotifierProvider<SessionController, SessionState> {
  /// Decides the app mode at startup and owns the transitions: pair, unlock,
  /// lock, sign in, sign out.
  SessionControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionControllerHash();

  @$internal
  @override
  SessionController create() => SessionController();
}

String _$sessionControllerHash() => r'bca88d81e853f684d01ea505a85d9a763c57e3ef';

/// Decides the app mode at startup and owns the transitions: pair, unlock,
/// lock, sign in, sign out.

abstract class _$SessionController extends $AsyncNotifier<SessionState> {
  FutureOr<SessionState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<SessionState>, SessionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SessionState>, SessionState>,
              AsyncValue<SessionState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
