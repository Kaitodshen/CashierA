// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'visual_effects.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(visualEffectsRepository)
final visualEffectsRepositoryProvider = VisualEffectsRepositoryProvider._();

final class VisualEffectsRepositoryProvider
    extends
        $FunctionalProvider<
          VisualEffectsRepository,
          VisualEffectsRepository,
          VisualEffectsRepository
        >
    with $Provider<VisualEffectsRepository> {
  VisualEffectsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'visualEffectsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$visualEffectsRepositoryHash();

  @$internal
  @override
  $ProviderElement<VisualEffectsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  VisualEffectsRepository create(Ref ref) {
    return visualEffectsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VisualEffectsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VisualEffectsRepository>(value),
    );
  }
}

String _$visualEffectsRepositoryHash() =>
    r'719b00a32769613e51dd79755ad6dbe051ab192f';

/// Whether real blur is on. The back office (web) always has it on.

@ProviderFor(visualEffects)
final visualEffectsProvider = VisualEffectsProvider._();

/// Whether real blur is on. The back office (web) always has it on.

final class VisualEffectsProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  /// Whether real blur is on. The back office (web) always has it on.
  VisualEffectsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'visualEffectsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$visualEffectsHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return visualEffects(ref);
  }
}

String _$visualEffectsHash() => r'38b22df3331e6c0eddd353934d8b85040cc99315';
