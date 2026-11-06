import 'package:cashiera/core/catalog/catalog_item.dart';
import 'package:cashiera/core/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'catalog_providers.g.dart';

/// Search text and category filter of the terminal product browser.
@riverpod
class CatalogQuery extends _$CatalogQuery {
  @override
  ({String search, String? categoryId}) build() =>
      (search: '', categoryId: null);

  void setSearch(String value) =>
      state = (search: value, categoryId: state.categoryId);

  void setCategory(String? id) =>
      state = (search: state.search, categoryId: id);
}

@riverpod
Stream<List<CatalogItem>> catalogItems(Ref ref) {
  final query = ref.watch(catalogQueryProvider);
  return ref
      .watch(terminalCatalogProvider)
      .watchItems(search: query.search, categoryId: query.categoryId);
}

@riverpod
Stream<List<CatalogCategory>> catalogCategories(Ref ref) =>
    ref.watch(terminalCatalogProvider).watchCategories();
