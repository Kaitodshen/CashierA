import 'package:drift/drift.dart';

// Offline mirror of the company catalog and this terminal's store data.
// Filled by CatalogPullService; never edited by the UI except stock_levels,
// which local stock movements update until the server confirms them.
// Quantities are integer thousandths (Qty.milli); money is integer rupiah.

@DataClassName('CategoryRow')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get parentId => text().nullable()();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer()();
  TextColumn get color => text().nullable()();
  TextColumn get icon => text().nullable()();
  TextColumn get kitchenStation => text().nullable()();
  BoolColumn get isActive => boolean()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('UnitRow')
class Units extends Table {
  TextColumn get id => text()();
  TextColumn get code => text()();
  TextColumn get name => text()();
  BoolColumn get allowDecimal => boolean()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ProductRow')
class Products extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get unitId => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get productType => text()();
  BoolColumn get trackStock => boolean()();
  BoolColumn get isTaxable => boolean()();
  TextColumn get kitchenStation => text().nullable()();
  TextColumn get imagePath => text().nullable()();
  BoolColumn get isActive => boolean()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('VariantRow')
class ProductVariants extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text()();
  TextColumn get name => text()();
  TextColumn get sku => text()();
  TextColumn get barcode => text().nullable()();
  IntColumn get price => integer()();
  IntColumn get cost => integer()();
  IntColumn get sortOrder => integer()();
  BoolColumn get isActive => boolean()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// This store's price override, reorder point and availability per variant.
@DataClassName('StoreVariantSettingRow')
class StoreVariantSettings extends Table {
  TextColumn get variantId => text()();
  IntColumn get priceOverride => integer().nullable()();
  IntColumn get reorderPointMilli => integer().nullable()();
  IntColumn get reorderQtyMilli => integer().nullable()();
  BoolColumn get isAvailable => boolean()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {variantId};
}

@DataClassName('ModifierGroupRow')
class ModifierGroups extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get minSelect => integer()();
  IntColumn get maxSelect => integer()();
  IntColumn get sortOrder => integer()();
  BoolColumn get isActive => boolean()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ModifierRow')
class Modifiers extends Table {
  TextColumn get id => text()();
  TextColumn get groupId => text()();
  TextColumn get name => text()();
  IntColumn get priceDelta => integer()();
  IntColumn get sortOrder => integer()();
  BoolColumn get isActive => boolean()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ProductModifierGroupRow')
class ProductModifierGroups extends Table {
  TextColumn get productId => text()();
  TextColumn get groupId => text()();
  IntColumn get sortOrder => integer()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {productId, groupId};
}

@DataClassName('StoreFavoriteRow')
class StoreFavorites extends Table {
  TextColumn get productId => text()();
  IntColumn get sortOrder => integer()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {productId};
}

/// On-hand stock in this store.
@DataClassName('StockLevelRow')
class StockLevels extends Table {
  TextColumn get variantId => text()();
  IntColumn get quantityMilli => integer()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {variantId};
}
