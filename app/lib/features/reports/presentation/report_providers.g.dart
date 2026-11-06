// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(reportsRepository)
final reportsRepositoryProvider = ReportsRepositoryProvider._();

final class ReportsRepositoryProvider
    extends
        $FunctionalProvider<
          ReportsRepository,
          ReportsRepository,
          ReportsRepository
        >
    with $Provider<ReportsRepository> {
  ReportsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reportsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reportsRepositoryHash();

  @$internal
  @override
  $ProviderElement<ReportsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReportsRepository create(Ref ref) {
    return reportsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReportsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReportsRepository>(value),
    );
  }
}

String _$reportsRepositoryHash() => r'28e4973346ad0570e6bc88208a97b8294d5fdd25';

@ProviderFor(salesReport)
final salesReportProvider = SalesReportFamily._();

final class SalesReportProvider
    extends
        $FunctionalProvider<
          AsyncValue<SalesReport>,
          SalesReport,
          FutureOr<SalesReport>
        >
    with $FutureModifier<SalesReport>, $FutureProvider<SalesReport> {
  SalesReportProvider._({
    required SalesReportFamily super.from,
    required ({ReportPeriod period, String? storeId}) super.argument,
  }) : super(
         retry: null,
         name: r'salesReportProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$salesReportHash();

  @override
  String toString() {
    return r'salesReportProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<SalesReport> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SalesReport> create(Ref ref) {
    final argument = this.argument as ({ReportPeriod period, String? storeId});
    return salesReport(ref, period: argument.period, storeId: argument.storeId);
  }

  @override
  bool operator ==(Object other) {
    return other is SalesReportProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$salesReportHash() => r'271c005e79d96dbffbffdafe503536f61f787c42';

final class SalesReportFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<SalesReport>,
          ({ReportPeriod period, String? storeId})
        > {
  SalesReportFamily._()
    : super(
        retry: null,
        name: r'salesReportProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SalesReportProvider call({required ReportPeriod period, String? storeId}) =>
      SalesReportProvider._(
        argument: (period: period, storeId: storeId),
        from: this,
      );

  @override
  String toString() => r'salesReportProvider';
}

@ProviderFor(paymentsReport)
final paymentsReportProvider = PaymentsReportFamily._();

final class PaymentsReportProvider
    extends
        $FunctionalProvider<
          AsyncValue<PaymentsReport>,
          PaymentsReport,
          FutureOr<PaymentsReport>
        >
    with $FutureModifier<PaymentsReport>, $FutureProvider<PaymentsReport> {
  PaymentsReportProvider._({
    required PaymentsReportFamily super.from,
    required ({ReportPeriod period, String? storeId}) super.argument,
  }) : super(
         retry: null,
         name: r'paymentsReportProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$paymentsReportHash();

  @override
  String toString() {
    return r'paymentsReportProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<PaymentsReport> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PaymentsReport> create(Ref ref) {
    final argument = this.argument as ({ReportPeriod period, String? storeId});
    return paymentsReport(
      ref,
      period: argument.period,
      storeId: argument.storeId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PaymentsReportProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$paymentsReportHash() => r'69e5a2d80d4926ce6edd871431246ff5a31af46c';

final class PaymentsReportFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<PaymentsReport>,
          ({ReportPeriod period, String? storeId})
        > {
  PaymentsReportFamily._()
    : super(
        retry: null,
        name: r'paymentsReportProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PaymentsReportProvider call({
    required ReportPeriod period,
    String? storeId,
  }) => PaymentsReportProvider._(
    argument: (period: period, storeId: storeId),
    from: this,
  );

  @override
  String toString() => r'paymentsReportProvider';
}

@ProviderFor(productsReport)
final productsReportProvider = ProductsReportFamily._();

final class ProductsReportProvider
    extends
        $FunctionalProvider<
          AsyncValue<ProductsReport>,
          ProductsReport,
          FutureOr<ProductsReport>
        >
    with $FutureModifier<ProductsReport>, $FutureProvider<ProductsReport> {
  ProductsReportProvider._({
    required ProductsReportFamily super.from,
    required ({ReportPeriod period, String? storeId}) super.argument,
  }) : super(
         retry: null,
         name: r'productsReportProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$productsReportHash();

  @override
  String toString() {
    return r'productsReportProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<ProductsReport> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ProductsReport> create(Ref ref) {
    final argument = this.argument as ({ReportPeriod period, String? storeId});
    return productsReport(
      ref,
      period: argument.period,
      storeId: argument.storeId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ProductsReportProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$productsReportHash() => r'17e1a446cbb8b13b62ba6ac13e72e3e8a43bb3ca';

final class ProductsReportFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<ProductsReport>,
          ({ReportPeriod period, String? storeId})
        > {
  ProductsReportFamily._()
    : super(
        retry: null,
        name: r'productsReportProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ProductsReportProvider call({
    required ReportPeriod period,
    String? storeId,
  }) => ProductsReportProvider._(
    argument: (period: period, storeId: storeId),
    from: this,
  );

  @override
  String toString() => r'productsReportProvider';
}

@ProviderFor(staffReport)
final staffReportProvider = StaffReportFamily._();

final class StaffReportProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<StaffRow>>,
          List<StaffRow>,
          FutureOr<List<StaffRow>>
        >
    with $FutureModifier<List<StaffRow>>, $FutureProvider<List<StaffRow>> {
  StaffReportProvider._({
    required StaffReportFamily super.from,
    required ({ReportPeriod period, String? storeId}) super.argument,
  }) : super(
         retry: null,
         name: r'staffReportProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$staffReportHash();

  @override
  String toString() {
    return r'staffReportProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<StaffRow>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<StaffRow>> create(Ref ref) {
    final argument = this.argument as ({ReportPeriod period, String? storeId});
    return staffReport(ref, period: argument.period, storeId: argument.storeId);
  }

  @override
  bool operator ==(Object other) {
    return other is StaffReportProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$staffReportHash() => r'c8f6ef52b65933739a957d38ac6a44d0cb50464e';

final class StaffReportFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<StaffRow>>,
          ({ReportPeriod period, String? storeId})
        > {
  StaffReportFamily._()
    : super(
        retry: null,
        name: r'staffReportProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  StaffReportProvider call({required ReportPeriod period, String? storeId}) =>
      StaffReportProvider._(
        argument: (period: period, storeId: storeId),
        from: this,
      );

  @override
  String toString() => r'staffReportProvider';
}

@ProviderFor(taxReport)
final taxReportProvider = TaxReportFamily._();

final class TaxReportProvider
    extends
        $FunctionalProvider<
          AsyncValue<TaxReport>,
          TaxReport,
          FutureOr<TaxReport>
        >
    with $FutureModifier<TaxReport>, $FutureProvider<TaxReport> {
  TaxReportProvider._({
    required TaxReportFamily super.from,
    required ({ReportPeriod period, String? storeId}) super.argument,
  }) : super(
         retry: null,
         name: r'taxReportProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$taxReportHash();

  @override
  String toString() {
    return r'taxReportProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<TaxReport> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<TaxReport> create(Ref ref) {
    final argument = this.argument as ({ReportPeriod period, String? storeId});
    return taxReport(ref, period: argument.period, storeId: argument.storeId);
  }

  @override
  bool operator ==(Object other) {
    return other is TaxReportProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$taxReportHash() => r'f5a37290e72515cbf1d611b6515bbd15148ae566';

final class TaxReportFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<TaxReport>,
          ({ReportPeriod period, String? storeId})
        > {
  TaxReportFamily._()
    : super(
        retry: null,
        name: r'taxReportProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TaxReportProvider call({required ReportPeriod period, String? storeId}) =>
      TaxReportProvider._(
        argument: (period: period, storeId: storeId),
        from: this,
      );

  @override
  String toString() => r'taxReportProvider';
}

@ProviderFor(stockValueReport)
final stockValueReportProvider = StockValueReportFamily._();

final class StockValueReportProvider
    extends
        $FunctionalProvider<
          AsyncValue<StockValueReport>,
          StockValueReport,
          FutureOr<StockValueReport>
        >
    with $FutureModifier<StockValueReport>, $FutureProvider<StockValueReport> {
  StockValueReportProvider._({
    required StockValueReportFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'stockValueReportProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$stockValueReportHash();

  @override
  String toString() {
    return r'stockValueReportProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<StockValueReport> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<StockValueReport> create(Ref ref) {
    final argument = this.argument as String?;
    return stockValueReport(ref, storeId: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is StockValueReportProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$stockValueReportHash() => r'f410fb0942b13b3c4157c98dc830f65d64f7bb01';

final class StockValueReportFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<StockValueReport>, String?> {
  StockValueReportFamily._()
    : super(
        retry: null,
        name: r'stockValueReportProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  StockValueReportProvider call({String? storeId}) =>
      StockValueReportProvider._(argument: storeId, from: this);

  @override
  String toString() => r'stockValueReportProvider';
}

/// Today in this browser's time zone (the back office is used locally).

@ProviderFor(dashboard)
final dashboardProvider = DashboardFamily._();

/// Today in this browser's time zone (the back office is used locally).

final class DashboardProvider
    extends
        $FunctionalProvider<
          AsyncValue<DashboardData>,
          DashboardData,
          FutureOr<DashboardData>
        >
    with $FutureModifier<DashboardData>, $FutureProvider<DashboardData> {
  /// Today in this browser's time zone (the back office is used locally).
  DashboardProvider._({
    required DashboardFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'dashboardProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dashboardHash();

  @override
  String toString() {
    return r'dashboardProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<DashboardData> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DashboardData> create(Ref ref) {
    final argument = this.argument as String?;
    return dashboard(ref, storeId: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DashboardProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dashboardHash() => r'40a44ffdec400694a0ed5eaf33e253cea23c9fca';

/// Today in this browser's time zone (the back office is used locally).

final class DashboardFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<DashboardData>, String?> {
  DashboardFamily._()
    : super(
        retry: null,
        name: r'dashboardProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Today in this browser's time zone (the back office is used locally).

  DashboardProvider call({String? storeId}) =>
      DashboardProvider._(argument: storeId, from: this);

  @override
  String toString() => r'dashboardProvider';
}
