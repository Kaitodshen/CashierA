// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Search text and category filter of the terminal product browser.

@ProviderFor(CatalogQuery)
final catalogQueryProvider = CatalogQueryProvider._();

/// Search text and category filter of the terminal product browser.
final class CatalogQueryProvider
    extends
        $NotifierProvider<CatalogQuery, ({String? categoryId, String search})> {
  /// Search text and category filter of the terminal product browser.
  CatalogQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'catalogQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$catalogQueryHash();

  @$internal
  @override
  CatalogQuery create() => CatalogQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(({String? categoryId, String search}) value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<({String? categoryId, String search})>(value),
    );
  }
}

String _$catalogQueryHash() => r'a7806d1fc5ce14c272ae433f8000464d69d0fe40';

/// Search text and category filter of the terminal product browser.

abstract class _$CatalogQuery
    extends $Notifier<({String? categoryId, String search})> {
  ({String? categoryId, String search}) build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              ({String? categoryId, String search}),
              ({String? categoryId, String search})
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                ({String? categoryId, String search}),
                ({String? categoryId, String search})
              >,
              ({String? categoryId, String search}),
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(catalogItems)
final catalogItemsProvider = CatalogItemsProvider._();

final class CatalogItemsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CatalogItem>>,
          List<CatalogItem>,
          Stream<List<CatalogItem>>
        >
    with
        $FutureModifier<List<CatalogItem>>,
        $StreamProvider<List<CatalogItem>> {
  CatalogItemsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'catalogItemsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$catalogItemsHash();

  @$internal
  @override
  $StreamProviderElement<List<CatalogItem>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<CatalogItem>> create(Ref ref) {
    return catalogItems(ref);
  }
}

String _$catalogItemsHash() => r'f3592f200dbb8173f2ef3309bf08be95786daf27';

@ProviderFor(catalogCategories)
final catalogCategoriesProvider = CatalogCategoriesProvider._();

final class CatalogCategoriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CatalogCategory>>,
          List<CatalogCategory>,
          Stream<List<CatalogCategory>>
        >
    with
        $FutureModifier<List<CatalogCategory>>,
        $StreamProvider<List<CatalogCategory>> {
  CatalogCategoriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'catalogCategoriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$catalogCategoriesHash();

  @$internal
  @override
  $StreamProviderElement<List<CatalogCategory>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<CatalogCategory>> create(Ref ref) {
    return catalogCategories(ref);
  }
}

String _$catalogCategoriesHash() => r'a986a0fd55354c53eb8d2af16085d5b6c2bbc3cb';
