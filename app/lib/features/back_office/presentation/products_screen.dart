import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/empty_state.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/features/back_office/data/catalog_admin_models.dart';
import 'package:cashiera/features/back_office/presentation/back_office_providers.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  String _search = '';
  String? _categoryId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canEdit =
        ref.watch(principalProvider).value?.can('catalog.manage') ?? false;
    final categories = ref.watch(adminCategoriesProvider).value ?? const [];
    final products = ref.watch(
      adminProductsProvider(search: _search, categoryId: _categoryId),
    );
    final list = products.value ?? const <ProductSummary>[];

    return Scaffold(
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              key: const Key('product-new'),
              onPressed: () => context.go(AppRoutes.adminProduct('new')),
              icon: const Icon(Icons.add),
              label: Text(l10n.productsNew),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                SizedBox(
                  width: 320,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: l10n.catalogSearchHint,
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                SizedBox(
                  width: 240,
                  child: DropdownButtonFormField<String?>(
                    initialValue: _categoryId,
                    decoration: InputDecoration(
                      labelText: l10n.productCategory,
                    ),
                    items: [
                      DropdownMenuItem(child: Text(l10n.productsAllCategories)),
                      for (final c in categories)
                        DropdownMenuItem(value: c.id, child: Text(c.name)),
                    ],
                    onChanged: (v) => setState(() => _categoryId = v),
                  ),
                ),
              ],
            ),
          ),
          if (!canEdit)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(l10n.productsReadOnly),
            ),
          Expanded(
            child: products.hasError
                ? EmptyState(
                    icon: Icons.cloud_off_outlined,
                    message: l10n.commonError('${products.error}'),
                  )
                : !products.isLoading && list.isEmpty
                ? EmptyState(
                    icon: Icons.inventory_2_outlined,
                    message: l10n.productsEmpty,
                  )
                : Skeletonizer(
                    enabled: products.isLoading,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        96,
                      ),
                      itemCount: products.isLoading ? 6 : list.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, i) => _ProductTile(
                        product: products.isLoading ? _placeholder : list[i],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

const _placeholder = ProductSummary(
  id: '',
  name: 'Nama produk contoh',
  unitCode: 'pcs',
  variantCount: 1,
  minPrice: Money(10000),
  maxPrice: Money(10000),
  isActive: true,
  categoryName: 'Kategori',
);

class _ProductTile extends StatelessWidget {
  const new({required this.product});

  final ProductSummary product;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final price = product.minPrice == product.maxPrice
        ? product.minPrice.format()
        : '${product.minPrice.format()} – ${product.maxPrice.format()}';
    return Card(
      child: ListTile(
        onTap: product.id.isEmpty
            ? null
            : () => context.go(AppRoutes.adminProduct(product.id)),
        title: Text(
          product.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: product.isActive ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Text(
          [
            product.categoryName ?? '—',
            product.unitCode,
            l10n.productsVariants(product.variantCount),
            if (!product.isActive) l10n.commonInactive,
          ].join(' · '),
        ),
        trailing: Text(
          price,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
