// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'back_office_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(principal)
final principalProvider = PrincipalProvider._();

final class PrincipalProvider
    extends
        $FunctionalProvider<
          AsyncValue<Principal>,
          Principal,
          FutureOr<Principal>
        >
    with $FutureModifier<Principal>, $FutureProvider<Principal> {
  PrincipalProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'principalProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$principalHash();

  @$internal
  @override
  $FutureProviderElement<Principal> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Principal> create(Ref ref) {
    return principal(ref);
  }
}

String _$principalHash() => r'1481b25b8c603c488f941d1bf412843d18b9c42c';

@ProviderFor(backOfficeStores)
final backOfficeStoresProvider = BackOfficeStoresProvider._();

final class BackOfficeStoresProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<StoreSummary>>,
          List<StoreSummary>,
          FutureOr<List<StoreSummary>>
        >
    with
        $FutureModifier<List<StoreSummary>>,
        $FutureProvider<List<StoreSummary>> {
  BackOfficeStoresProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backOfficeStoresProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backOfficeStoresHash();

  @$internal
  @override
  $FutureProviderElement<List<StoreSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<StoreSummary>> create(Ref ref) {
    return backOfficeStores(ref);
  }
}

String _$backOfficeStoresHash() => r'badd875a36a99fdd30e0e4bf58fa3978c740ec7c';

@ProviderFor(catalogAdmin)
final catalogAdminProvider = CatalogAdminProvider._();

final class CatalogAdminProvider
    extends
        $FunctionalProvider<
          CatalogAdminRepository,
          CatalogAdminRepository,
          CatalogAdminRepository
        >
    with $Provider<CatalogAdminRepository> {
  CatalogAdminProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'catalogAdminProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$catalogAdminHash();

  @$internal
  @override
  $ProviderElement<CatalogAdminRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CatalogAdminRepository create(Ref ref) {
    return catalogAdmin(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CatalogAdminRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CatalogAdminRepository>(value),
    );
  }
}

String _$catalogAdminHash() => r'08c9f04f149410797302814b3a236440933cf54e';

@ProviderFor(adminCategories)
final adminCategoriesProvider = AdminCategoriesProvider._();

final class AdminCategoriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AdminCategory>>,
          List<AdminCategory>,
          FutureOr<List<AdminCategory>>
        >
    with
        $FutureModifier<List<AdminCategory>>,
        $FutureProvider<List<AdminCategory>> {
  AdminCategoriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminCategoriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminCategoriesHash();

  @$internal
  @override
  $FutureProviderElement<List<AdminCategory>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AdminCategory>> create(Ref ref) {
    return adminCategories(ref);
  }
}

String _$adminCategoriesHash() => r'14285114f33c91187fe5e254ecf6eb3258813976';

@ProviderFor(adminUnits)
final adminUnitsProvider = AdminUnitsProvider._();

final class AdminUnitsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AdminUnit>>,
          List<AdminUnit>,
          FutureOr<List<AdminUnit>>
        >
    with $FutureModifier<List<AdminUnit>>, $FutureProvider<List<AdminUnit>> {
  AdminUnitsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminUnitsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminUnitsHash();

  @$internal
  @override
  $FutureProviderElement<List<AdminUnit>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AdminUnit>> create(Ref ref) {
    return adminUnits(ref);
  }
}

String _$adminUnitsHash() => r'8265c7bd42b0d29561b7938cc89957580abffb7a';

@ProviderFor(adminSuppliers)
final adminSuppliersProvider = AdminSuppliersProvider._();

final class AdminSuppliersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AdminSupplier>>,
          List<AdminSupplier>,
          FutureOr<List<AdminSupplier>>
        >
    with
        $FutureModifier<List<AdminSupplier>>,
        $FutureProvider<List<AdminSupplier>> {
  AdminSuppliersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminSuppliersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminSuppliersHash();

  @$internal
  @override
  $FutureProviderElement<List<AdminSupplier>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AdminSupplier>> create(Ref ref) {
    return adminSuppliers(ref);
  }
}

String _$adminSuppliersHash() => r'038f1bbf2443eefccaeffb9414c41c14b1d53f30';

@ProviderFor(adminProducts)
final adminProductsProvider = AdminProductsFamily._();

final class AdminProductsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ProductSummary>>,
          List<ProductSummary>,
          FutureOr<List<ProductSummary>>
        >
    with
        $FutureModifier<List<ProductSummary>>,
        $FutureProvider<List<ProductSummary>> {
  AdminProductsProvider._({
    required AdminProductsFamily super.from,
    required ({String search, String? categoryId}) super.argument,
  }) : super(
         retry: null,
         name: r'adminProductsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$adminProductsHash();

  @override
  String toString() {
    return r'adminProductsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<ProductSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ProductSummary>> create(Ref ref) {
    final argument = this.argument as ({String search, String? categoryId});
    return adminProducts(
      ref,
      search: argument.search,
      categoryId: argument.categoryId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AdminProductsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$adminProductsHash() => r'90a810edd61637689ddcabc647a1fc409d732268';

final class AdminProductsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<ProductSummary>>,
          ({String search, String? categoryId})
        > {
  AdminProductsFamily._()
    : super(
        retry: null,
        name: r'adminProductsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AdminProductsProvider call({String search = '', String? categoryId}) =>
      AdminProductsProvider._(
        argument: (search: search, categoryId: categoryId),
        from: this,
      );

  @override
  String toString() => r'adminProductsProvider';
}

@ProviderFor(stockOverview)
final stockOverviewProvider = StockOverviewFamily._();

final class StockOverviewProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<StockRow>>,
          List<StockRow>,
          FutureOr<List<StockRow>>
        >
    with $FutureModifier<List<StockRow>>, $FutureProvider<List<StockRow>> {
  StockOverviewProvider._({
    required StockOverviewFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'stockOverviewProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$stockOverviewHash();

  @override
  String toString() {
    return r'stockOverviewProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<StockRow>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<StockRow>> create(Ref ref) {
    final argument = this.argument as String;
    return stockOverview(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is StockOverviewProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$stockOverviewHash() => r'8b55cb29d729202cda8a32a05e0a29c76da8de1f';

final class StockOverviewFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<StockRow>>, String> {
  StockOverviewFamily._()
    : super(
        retry: null,
        name: r'stockOverviewProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  StockOverviewProvider call(String storeId) =>
      StockOverviewProvider._(argument: storeId, from: this);

  @override
  String toString() => r'stockOverviewProvider';
}

@ProviderFor(storeAlerts)
final storeAlertsProvider = StoreAlertsFamily._();

final class StoreAlertsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AlertRow>>,
          List<AlertRow>,
          FutureOr<List<AlertRow>>
        >
    with $FutureModifier<List<AlertRow>>, $FutureProvider<List<AlertRow>> {
  StoreAlertsProvider._({
    required StoreAlertsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'storeAlertsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$storeAlertsHash();

  @override
  String toString() {
    return r'storeAlertsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<AlertRow>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AlertRow>> create(Ref ref) {
    final argument = this.argument as String;
    return storeAlerts(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is StoreAlertsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$storeAlertsHash() => r'f73e1bd42737d1737dceb26fde7f568754219392';

final class StoreAlertsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<AlertRow>>, String> {
  StoreAlertsFamily._()
    : super(
        retry: null,
        name: r'storeAlertsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  StoreAlertsProvider call(String storeId) =>
      StoreAlertsProvider._(argument: storeId, from: this);

  @override
  String toString() => r'storeAlertsProvider';
}

@ProviderFor(stockMovements)
final stockMovementsProvider = StockMovementsFamily._();

final class StockMovementsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MovementRow>>,
          List<MovementRow>,
          FutureOr<List<MovementRow>>
        >
    with
        $FutureModifier<List<MovementRow>>,
        $FutureProvider<List<MovementRow>> {
  StockMovementsProvider._({
    required StockMovementsFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'stockMovementsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$stockMovementsHash();

  @override
  String toString() {
    return r'stockMovementsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<MovementRow>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MovementRow>> create(Ref ref) {
    final argument = this.argument as (String, String);
    return stockMovements(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is StockMovementsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$stockMovementsHash() => r'3e1f9f72b0be4e6a7b98598cbfcb1c3ed3a7e47d';

final class StockMovementsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<MovementRow>>,
          (String, String)
        > {
  StockMovementsFamily._()
    : super(
        retry: null,
        name: r'stockMovementsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  StockMovementsProvider call(String storeId, String variantId) =>
      StockMovementsProvider._(argument: (storeId, variantId), from: this);

  @override
  String toString() => r'stockMovementsProvider';
}

@ProviderFor(posAdmin)
final posAdminProvider = PosAdminProvider._();

final class PosAdminProvider
    extends
        $FunctionalProvider<
          PosAdminRepository,
          PosAdminRepository,
          PosAdminRepository
        >
    with $Provider<PosAdminRepository> {
  PosAdminProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'posAdminProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$posAdminHash();

  @$internal
  @override
  $ProviderElement<PosAdminRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PosAdminRepository create(Ref ref) {
    return posAdmin(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PosAdminRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PosAdminRepository>(value),
    );
  }
}

String _$posAdminHash() => r'7751bf62c4d3ecf8a252b354f1232e21bfb7554f';

@ProviderFor(adminStoreSettings)
final adminStoreSettingsProvider = AdminStoreSettingsFamily._();

final class AdminStoreSettingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<StoreSettingsDraft>,
          StoreSettingsDraft,
          FutureOr<StoreSettingsDraft>
        >
    with
        $FutureModifier<StoreSettingsDraft>,
        $FutureProvider<StoreSettingsDraft> {
  AdminStoreSettingsProvider._({
    required AdminStoreSettingsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'adminStoreSettingsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$adminStoreSettingsHash();

  @override
  String toString() {
    return r'adminStoreSettingsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<StoreSettingsDraft> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<StoreSettingsDraft> create(Ref ref) {
    final argument = this.argument as String;
    return adminStoreSettings(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AdminStoreSettingsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$adminStoreSettingsHash() =>
    r'88bbeb09548630050644de664c1bc725bf002773';

final class AdminStoreSettingsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<StoreSettingsDraft>, String> {
  AdminStoreSettingsFamily._()
    : super(
        retry: null,
        name: r'adminStoreSettingsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AdminStoreSettingsProvider call(String storeId) =>
      AdminStoreSettingsProvider._(argument: storeId, from: this);

  @override
  String toString() => r'adminStoreSettingsProvider';
}

@ProviderFor(adminPaymentMethods)
final adminPaymentMethodsProvider = AdminPaymentMethodsFamily._();

final class AdminPaymentMethodsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<StorePaymentMethod>>,
          List<StorePaymentMethod>,
          FutureOr<List<StorePaymentMethod>>
        >
    with
        $FutureModifier<List<StorePaymentMethod>>,
        $FutureProvider<List<StorePaymentMethod>> {
  AdminPaymentMethodsProvider._({
    required AdminPaymentMethodsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'adminPaymentMethodsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$adminPaymentMethodsHash();

  @override
  String toString() {
    return r'adminPaymentMethodsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<StorePaymentMethod>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<StorePaymentMethod>> create(Ref ref) {
    final argument = this.argument as String;
    return adminPaymentMethods(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AdminPaymentMethodsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$adminPaymentMethodsHash() =>
    r'17d9e27bb20b081ac287982b5ac441eed5d764e6';

final class AdminPaymentMethodsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<StorePaymentMethod>>, String> {
  AdminPaymentMethodsFamily._()
    : super(
        retry: null,
        name: r'adminPaymentMethodsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AdminPaymentMethodsProvider call(String storeId) =>
      AdminPaymentMethodsProvider._(argument: storeId, from: this);

  @override
  String toString() => r'adminPaymentMethodsProvider';
}

@ProviderFor(adminPromotions)
final adminPromotionsProvider = AdminPromotionsProvider._();

final class AdminPromotionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Promotion>>,
          List<Promotion>,
          FutureOr<List<Promotion>>
        >
    with $FutureModifier<List<Promotion>>, $FutureProvider<List<Promotion>> {
  AdminPromotionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminPromotionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminPromotionsHash();

  @$internal
  @override
  $FutureProviderElement<List<Promotion>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Promotion>> create(Ref ref) {
    return adminPromotions(ref);
  }
}

String _$adminPromotionsHash() => r'9c5cf189a7704dce0d94e1dd58871c0175ae476e';

@ProviderFor(adminVouchers)
final adminVouchersProvider = AdminVouchersProvider._();

final class AdminVouchersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AdminVoucher>>,
          List<AdminVoucher>,
          FutureOr<List<AdminVoucher>>
        >
    with
        $FutureModifier<List<AdminVoucher>>,
        $FutureProvider<List<AdminVoucher>> {
  AdminVouchersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminVouchersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminVouchersHash();

  @$internal
  @override
  $FutureProviderElement<List<AdminVoucher>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AdminVoucher>> create(Ref ref) {
    return adminVouchers(ref);
  }
}

String _$adminVouchersHash() => r'5815977476618749ca6f0d3431fce6f70c57d0a0';

@ProviderFor(promotionScopeOptions)
final promotionScopeOptionsProvider = PromotionScopeOptionsProvider._();

final class PromotionScopeOptionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<ScopeOptions>,
          ScopeOptions,
          FutureOr<ScopeOptions>
        >
    with $FutureModifier<ScopeOptions>, $FutureProvider<ScopeOptions> {
  PromotionScopeOptionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'promotionScopeOptionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$promotionScopeOptionsHash();

  @$internal
  @override
  $FutureProviderElement<ScopeOptions> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ScopeOptions> create(Ref ref) {
    return promotionScopeOptions(ref);
  }
}

String _$promotionScopeOptionsHash() =>
    r'53eef5ffddd5189e2a0370faff8ecb1b226a3d8f';

@ProviderFor(shiftAudit)
final shiftAuditProvider = ShiftAuditProvider._();

final class ShiftAuditProvider
    extends
        $FunctionalProvider<
          ShiftAuditRepository,
          ShiftAuditRepository,
          ShiftAuditRepository
        >
    with $Provider<ShiftAuditRepository> {
  ShiftAuditProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shiftAuditProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shiftAuditHash();

  @$internal
  @override
  $ProviderElement<ShiftAuditRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ShiftAuditRepository create(Ref ref) {
    return shiftAudit(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShiftAuditRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShiftAuditRepository>(value),
    );
  }
}

String _$shiftAuditHash() => r'0f6e3f8e9cec3b4ca85616a46a1918e5125a453e';

/// Shifts with a business date from [from] to [to]; [storeId] null = all.

@ProviderFor(adminShifts)
final adminShiftsProvider = AdminShiftsFamily._();

/// Shifts with a business date from [from] to [to]; [storeId] null = all.

final class AdminShiftsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ShiftOverviewRow>>,
          List<ShiftOverviewRow>,
          FutureOr<List<ShiftOverviewRow>>
        >
    with
        $FutureModifier<List<ShiftOverviewRow>>,
        $FutureProvider<List<ShiftOverviewRow>> {
  /// Shifts with a business date from [from] to [to]; [storeId] null = all.
  AdminShiftsProvider._({
    required AdminShiftsFamily super.from,
    required ({DateTime from, DateTime to, String? storeId}) super.argument,
  }) : super(
         retry: null,
         name: r'adminShiftsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$adminShiftsHash();

  @override
  String toString() {
    return r'adminShiftsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<ShiftOverviewRow>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ShiftOverviewRow>> create(Ref ref) {
    final argument =
        this.argument as ({DateTime from, DateTime to, String? storeId});
    return adminShifts(
      ref,
      from: argument.from,
      to: argument.to,
      storeId: argument.storeId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AdminShiftsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$adminShiftsHash() => r'bd6fd290308c9537eb8b1b1385bdc6ee3cf787ff';

/// Shifts with a business date from [from] to [to]; [storeId] null = all.

final class AdminShiftsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<ShiftOverviewRow>>,
          ({DateTime from, DateTime to, String? storeId})
        > {
  AdminShiftsFamily._()
    : super(
        retry: null,
        name: r'adminShiftsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Shifts with a business date from [from] to [to]; [storeId] null = all.

  AdminShiftsProvider call({
    required DateTime from,
    required DateTime to,
    String? storeId,
  }) => AdminShiftsProvider._(
    argument: (from: from, to: to, storeId: storeId),
    from: this,
  );

  @override
  String toString() => r'adminShiftsProvider';
}

@ProviderFor(adminShiftReport)
final adminShiftReportProvider = AdminShiftReportFamily._();

final class AdminShiftReportProvider
    extends
        $FunctionalProvider<
          AsyncValue<ShiftReport>,
          ShiftReport,
          FutureOr<ShiftReport>
        >
    with $FutureModifier<ShiftReport>, $FutureProvider<ShiftReport> {
  AdminShiftReportProvider._({
    required AdminShiftReportFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'adminShiftReportProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$adminShiftReportHash();

  @override
  String toString() {
    return r'adminShiftReportProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ShiftReport> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ShiftReport> create(Ref ref) {
    final argument = this.argument as String;
    return adminShiftReport(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AdminShiftReportProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$adminShiftReportHash() => r'e5ecff14fbbff9f0d3b24655ca0bbbc3c74d7727';

final class AdminShiftReportFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ShiftReport>, String> {
  AdminShiftReportFamily._()
    : super(
        retry: null,
        name: r'adminShiftReportProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AdminShiftReportProvider call(String shiftId) =>
      AdminShiftReportProvider._(argument: shiftId, from: this);

  @override
  String toString() => r'adminShiftReportProvider';
}
