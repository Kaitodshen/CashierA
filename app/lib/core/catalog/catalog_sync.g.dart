// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_sync.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Keeps the terminal's catalog mirror fresh: at start, every 5 minutes,
/// when the network comes back, and shortly after stock changes on the
/// server (Realtime on stock_levels for this store).

@ProviderFor(CatalogSync)
final catalogSyncProvider = CatalogSyncProvider._();

/// Keeps the terminal's catalog mirror fresh: at start, every 5 minutes,
/// when the network comes back, and shortly after stock changes on the
/// server (Realtime on stock_levels for this store).
final class CatalogSyncProvider
    extends $NotifierProvider<CatalogSync, CatalogSyncState> {
  /// Keeps the terminal's catalog mirror fresh: at start, every 5 minutes,
  /// when the network comes back, and shortly after stock changes on the
  /// server (Realtime on stock_levels for this store).
  CatalogSyncProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'catalogSyncProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$catalogSyncHash();

  @$internal
  @override
  CatalogSync create() => CatalogSync();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CatalogSyncState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CatalogSyncState>(value),
    );
  }
}

String _$catalogSyncHash() => r'498ce99eddd039f581986e1437e75b8a94ebfade';

/// Keeps the terminal's catalog mirror fresh: at start, every 5 minutes,
/// when the network comes back, and shortly after stock changes on the
/// server (Realtime on stock_levels for this store).

abstract class _$CatalogSync extends $Notifier<CatalogSyncState> {
  CatalogSyncState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CatalogSyncState, CatalogSyncState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CatalogSyncState, CatalogSyncState>,
              CatalogSyncState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
