import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/admin.dart';
import 'package:cashiera/core/design_system/widgets/buttons.dart';
import 'package:cashiera/core/design_system/widgets/data_display.dart';
import 'package:cashiera/core/design_system/widgets/glass_table.dart';
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

    return AdminPage(
      toolbar: AdminToolbar(
        filters: [
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
              decoration: InputDecoration(labelText: l10n.productCategory),
              items: [
                DropdownMenuItem(child: Text(l10n.productsAllCategories)),
                for (final c in categories)
                  DropdownMenuItem(value: c.id, child: Text(c.name)),
              ],
              onChanged: (v) => setState(() => _categoryId = v),
            ),
          ),
          if (!canEdit)
            Text(
              l10n.productsReadOnly,
              style: const TextStyle(color: AppColors.textMuted),
            ),
        ],
        actions: [
          if (canEdit)
            PrimaryButton(
              key: const Key('product-new'),
              onPressed: () => context.go(AppRoutes.adminProduct('new')),
              icon: Icons.add,
              label: l10n.productsNew,
            ),
        ],
      ),
      children: [
        if (products.hasError)
          adminMessage(
            icon: Icons.cloud_off_outlined,
            message: l10n.commonError('${products.error}'),
          )
        else if (!products.isLoading && list.isEmpty)
          adminMessage(
            icon: Icons.inventory_2_outlined,
            message: l10n.productsEmpty,
          )
        else
          Skeletonizer(
            enabled: products.isLoading,
            child: _ProductTable(
              products: products.isLoading
                  ? List.filled(6, _placeholder)
                  : list,
            ),
          ),
      ],
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

class _ProductTable extends StatelessWidget {
  const new({required this.products});

  final List<ProductSummary> products;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String price(ProductSummary p) => p.minPrice == p.maxPrice
        ? p.minPrice.format()
        : '${p.minPrice.format()} – ${p.maxPrice.format()}';
    return GlassTable<ProductSummary>(
      rows: products,
      onRowTap: (p) {
        if (p.id.isNotEmpty) context.go(AppRoutes.adminProduct(p.id));
      },
      columns: [
        GlassColumn(
          label: l10n.catalogColProduct,
          flex: 4,
          cell: (p) => Row(
            children: [
              ProductThumb(name: p.name, size: 40),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  p.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration: p.isActive ? null : TextDecoration.lineThrough,
                  ),
                ),
              ),
            ],
          ),
        ),
        GlassColumn(
          label: l10n.catalogColCategory,
          flex: 2,
          cell: (p) => p.categoryName == null
              ? const Text('—')
              : StatusChip(label: p.categoryName!, tone: StatusTone.primary),
        ),
        GlassColumn(
          label: l10n.adminColVariants,
          cell: (p) =>
              Text('${l10n.productsVariants(p.variantCount)} · ${p.unitCode}'),
        ),
        GlassColumn(
          label: l10n.catalogColPrice,
          flex: 2,
          numeric: true,
          cell: (p) => Text(
            price(p),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        GlassColumn(
          label: l10n.adminColStatus,
          cell: (p) => StatusChip(
            label: p.isActive ? l10n.commonActive : l10n.commonInactive,
            tone: p.isActive ? StatusTone.success : StatusTone.neutral,
          ),
        ),
      ],
    );
  }
}
