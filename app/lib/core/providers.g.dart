// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appEnv)
final appEnvProvider = AppEnvProvider._();

final class AppEnvProvider extends $FunctionalProvider<AppEnv, AppEnv, AppEnv>
    with $Provider<AppEnv> {
  AppEnvProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appEnvProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appEnvHash();

  @$internal
  @override
  $ProviderElement<AppEnv> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppEnv create(Ref ref) {
    return appEnv(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppEnv value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppEnv>(value),
    );
  }
}

String _$appEnvHash() => r'6753f6cd7309820934abb47023866db6d36ae441';

/// Only read when [AppEnv.isConfigured] (Supabase is initialized in
/// bootstrap).

@ProviderFor(supabaseClient)
final supabaseClientProvider = SupabaseClientProvider._();

/// Only read when [AppEnv.isConfigured] (Supabase is initialized in
/// bootstrap).

final class SupabaseClientProvider
    extends $FunctionalProvider<SupabaseClient, SupabaseClient, SupabaseClient>
    with $Provider<SupabaseClient> {
  /// Only read when [AppEnv.isConfigured] (Supabase is initialized in
  /// bootstrap).
  SupabaseClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supabaseClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supabaseClientHash();

  @$internal
  @override
  $ProviderElement<SupabaseClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SupabaseClient create(Ref ref) {
    return supabaseClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SupabaseClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SupabaseClient>(value),
    );
  }
}

String _$supabaseClientHash() => r'3db2a4c212c7f24cea9810e376225aa1a6cab012';

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'36ac7d334fd9928f919a918954bea2214f9c1be2';

@ProviderFor(terminalRepository)
final terminalRepositoryProvider = TerminalRepositoryProvider._();

final class TerminalRepositoryProvider
    extends
        $FunctionalProvider<
          TerminalRepository,
          TerminalRepository,
          TerminalRepository
        >
    with $Provider<TerminalRepository> {
  TerminalRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'terminalRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$terminalRepositoryHash();

  @$internal
  @override
  $ProviderElement<TerminalRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TerminalRepository create(Ref ref) {
    return terminalRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TerminalRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TerminalRepository>(value),
    );
  }
}

String _$terminalRepositoryHash() =>
    r'69dfe4cd83647834458d63f4e69f9b22257eea32';

@ProviderFor(terminalBackend)
final terminalBackendProvider = TerminalBackendProvider._();

final class TerminalBackendProvider
    extends
        $FunctionalProvider<TerminalBackend, TerminalBackend, TerminalBackend>
    with $Provider<TerminalBackend> {
  TerminalBackendProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'terminalBackendProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$terminalBackendHash();

  @$internal
  @override
  $ProviderElement<TerminalBackend> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TerminalBackend create(Ref ref) {
    return terminalBackend(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TerminalBackend value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TerminalBackend>(value),
    );
  }
}

String _$terminalBackendHash() => r'90ec9f683609d39f07ea0b49ee66dfec624d76e1';

@ProviderFor(backOfficeBackend)
final backOfficeBackendProvider = BackOfficeBackendProvider._();

final class BackOfficeBackendProvider
    extends
        $FunctionalProvider<
          BackOfficeBackend,
          BackOfficeBackend,
          BackOfficeBackend
        >
    with $Provider<BackOfficeBackend> {
  BackOfficeBackendProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backOfficeBackendProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backOfficeBackendHash();

  @$internal
  @override
  $ProviderElement<BackOfficeBackend> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BackOfficeBackend create(Ref ref) {
    return backOfficeBackend(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BackOfficeBackend value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BackOfficeBackend>(value),
    );
  }
}

String _$backOfficeBackendHash() => r'f13f384d80bf6c67ef35b02ea794492b48e71ae4';

@ProviderFor(pinVerifier)
final pinVerifierProvider = PinVerifierProvider._();

final class PinVerifierProvider
    extends $FunctionalProvider<PinVerifier, PinVerifier, PinVerifier>
    with $Provider<PinVerifier> {
  PinVerifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pinVerifierProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pinVerifierHash();

  @$internal
  @override
  $ProviderElement<PinVerifier> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PinVerifier create(Ref ref) {
    return pinVerifier(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PinVerifier value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PinVerifier>(value),
    );
  }
}

String _$pinVerifierHash() => r'425ff72ac72ca08f40accdd9899d191f87fb08ae';

/// True when the device has any network interface up.

@ProviderFor(online)
final onlineProvider = OnlineProvider._();

/// True when the device has any network interface up.

final class OnlineProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  /// True when the device has any network interface up.
  OnlineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onlineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onlineHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return online(ref);
  }
}

String _$onlineHash() => r'42f68373b37fdf21a48ee8b789ebb30877549254';

@ProviderFor(terminalCatalog)
final terminalCatalogProvider = TerminalCatalogProvider._();

final class TerminalCatalogProvider
    extends
        $FunctionalProvider<
          TerminalCatalogRepository,
          TerminalCatalogRepository,
          TerminalCatalogRepository
        >
    with $Provider<TerminalCatalogRepository> {
  TerminalCatalogProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'terminalCatalogProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$terminalCatalogHash();

  @$internal
  @override
  $ProviderElement<TerminalCatalogRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TerminalCatalogRepository create(Ref ref) {
    return terminalCatalog(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TerminalCatalogRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TerminalCatalogRepository>(value),
    );
  }
}

String _$terminalCatalogHash() => r'3ba807872ae3803fb33ba555cd138da2a3d72506';

@ProviderFor(stockService)
final stockServiceProvider = StockServiceProvider._();

final class StockServiceProvider
    extends $FunctionalProvider<StockService, StockService, StockService>
    with $Provider<StockService> {
  StockServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'stockServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$stockServiceHash();

  @$internal
  @override
  $ProviderElement<StockService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  StockService create(Ref ref) {
    return stockService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StockService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StockService>(value),
    );
  }
}

String _$stockServiceHash() => r'8cfddaeb4a713d78c5442e85466b884cbf5569b0';

@ProviderFor(posConfigRepository)
final posConfigRepositoryProvider = PosConfigRepositoryProvider._();

final class PosConfigRepositoryProvider
    extends
        $FunctionalProvider<
          PosConfigRepository,
          PosConfigRepository,
          PosConfigRepository
        >
    with $Provider<PosConfigRepository> {
  PosConfigRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'posConfigRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$posConfigRepositoryHash();

  @$internal
  @override
  $ProviderElement<PosConfigRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PosConfigRepository create(Ref ref) {
    return posConfigRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PosConfigRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PosConfigRepository>(value),
    );
  }
}

String _$posConfigRepositoryHash() =>
    r'f5c55c2cf86d58e1bceab63da6ee08c86f46e966';

@ProviderFor(shiftService)
final shiftServiceProvider = ShiftServiceProvider._();

final class ShiftServiceProvider
    extends $FunctionalProvider<ShiftService, ShiftService, ShiftService>
    with $Provider<ShiftService> {
  ShiftServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shiftServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shiftServiceHash();

  @$internal
  @override
  $ProviderElement<ShiftService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ShiftService create(Ref ref) {
    return shiftService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShiftService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShiftService>(value),
    );
  }
}

String _$shiftServiceHash() => r'119cfd17d8d0eec1b176ca7f4a7fe899ec57ca3d';

@ProviderFor(orderService)
final orderServiceProvider = OrderServiceProvider._();

final class OrderServiceProvider
    extends $FunctionalProvider<OrderService, OrderService, OrderService>
    with $Provider<OrderService> {
  OrderServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'orderServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$orderServiceHash();

  @$internal
  @override
  $ProviderElement<OrderService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  OrderService create(Ref ref) {
    return orderService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OrderService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OrderService>(value),
    );
  }
}

String _$orderServiceHash() => r'b54c351e929185aafa75ac1ad42b4acdb48da25c';

@ProviderFor(refundService)
final refundServiceProvider = RefundServiceProvider._();

final class RefundServiceProvider
    extends $FunctionalProvider<RefundService, RefundService, RefundService>
    with $Provider<RefundService> {
  RefundServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'refundServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$refundServiceHash();

  @$internal
  @override
  $ProviderElement<RefundService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RefundService create(Ref ref) {
    return refundService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RefundService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RefundService>(value),
    );
  }
}

String _$refundServiceHash() => r'a4b1e7dba06db749cdfac99dac947e5919602a97';

@ProviderFor(auditService)
final auditServiceProvider = AuditServiceProvider._();

final class AuditServiceProvider
    extends $FunctionalProvider<AuditService, AuditService, AuditService>
    with $Provider<AuditService> {
  AuditServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'auditServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$auditServiceHash();

  @$internal
  @override
  $ProviderElement<AuditService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuditService create(Ref ref) {
    return auditService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuditService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuditService>(value),
    );
  }
}

String _$auditServiceHash() => r'e217a4028ea27412ad96a60708b526a947390e0c';

@ProviderFor(customerService)
final customerServiceProvider = CustomerServiceProvider._();

final class CustomerServiceProvider
    extends
        $FunctionalProvider<CustomerService, CustomerService, CustomerService>
    with $Provider<CustomerService> {
  CustomerServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'customerServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$customerServiceHash();

  @$internal
  @override
  $ProviderElement<CustomerService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CustomerService create(Ref ref) {
    return customerService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CustomerService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CustomerService>(value),
    );
  }
}

String _$customerServiceHash() => r'e0658ad2221adedd14f9020660496f8b7ea8e89b';

@ProviderFor(printerRepository)
final printerRepositoryProvider = PrinterRepositoryProvider._();

final class PrinterRepositoryProvider
    extends
        $FunctionalProvider<
          PrinterRepository,
          PrinterRepository,
          PrinterRepository
        >
    with $Provider<PrinterRepository> {
  PrinterRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'printerRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$printerRepositoryHash();

  @$internal
  @override
  $ProviderElement<PrinterRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PrinterRepository create(Ref ref) {
    return printerRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PrinterRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PrinterRepository>(value),
    );
  }
}

String _$printerRepositoryHash() => r'ac889607bf965e310463e2463e8650c411b8ca70';

@ProviderFor(printerTransport)
final printerTransportProvider = PrinterTransportProvider._();

final class PrinterTransportProvider
    extends
        $FunctionalProvider<
          PrinterTransport,
          PrinterTransport,
          PrinterTransport
        >
    with $Provider<PrinterTransport> {
  PrinterTransportProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'printerTransportProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$printerTransportHash();

  @$internal
  @override
  $ProviderElement<PrinterTransport> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PrinterTransport create(Ref ref) {
    return printerTransport(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PrinterTransport value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PrinterTransport>(value),
    );
  }
}

String _$printerTransportHash() => r'71d585ee7791c5573bf0ba2c89f2a5b958ff5d0d';

@ProviderFor(printerService)
final printerServiceProvider = PrinterServiceProvider._();

final class PrinterServiceProvider
    extends $FunctionalProvider<PrinterService, PrinterService, PrinterService>
    with $Provider<PrinterService> {
  PrinterServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'printerServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$printerServiceHash();

  @$internal
  @override
  $ProviderElement<PrinterService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PrinterService create(Ref ref) {
    return printerService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PrinterService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PrinterService>(value),
    );
  }
}

String _$printerServiceHash() => r'647525c97a4e04cbff9b9664b27fe88d062b28bd';

/// The receipt printer set up on this terminal, or null.

@ProviderFor(receiptPrinter)
final receiptPrinterProvider = ReceiptPrinterProvider._();

/// The receipt printer set up on this terminal, or null.

final class ReceiptPrinterProvider
    extends
        $FunctionalProvider<
          AsyncValue<PrinterSetting?>,
          PrinterSetting?,
          Stream<PrinterSetting?>
        >
    with $FutureModifier<PrinterSetting?>, $StreamProvider<PrinterSetting?> {
  /// The receipt printer set up on this terminal, or null.
  ReceiptPrinterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'receiptPrinterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$receiptPrinterHash();

  @$internal
  @override
  $StreamProviderElement<PrinterSetting?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<PrinterSetting?> create(Ref ref) {
    return receiptPrinter(ref);
  }
}

String _$receiptPrinterHash() => r'33abd90ae0723ef4e7b866648033057d4d9282e3';

@ProviderFor(catalogSource)
final catalogSourceProvider = CatalogSourceProvider._();

final class CatalogSourceProvider
    extends $FunctionalProvider<CatalogSource, CatalogSource, CatalogSource>
    with $Provider<CatalogSource> {
  CatalogSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'catalogSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$catalogSourceHash();

  @$internal
  @override
  $ProviderElement<CatalogSource> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CatalogSource create(Ref ref) {
    return catalogSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CatalogSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CatalogSource>(value),
    );
  }
}

String _$catalogSourceHash() => r'53c262fa9c8e849ec5b9804ae88a5b188e3d54a0';

/// Active staff of this terminal's store, from the local roster.

@ProviderFor(roster)
final rosterProvider = RosterProvider._();

/// Active staff of this terminal's store, from the local roster.

final class RosterProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<StaffMember>>,
          List<StaffMember>,
          Stream<List<StaffMember>>
        >
    with
        $FutureModifier<List<StaffMember>>,
        $StreamProvider<List<StaffMember>> {
  /// Active staff of this terminal's store, from the local roster.
  RosterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'rosterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$rosterHash();

  @$internal
  @override
  $StreamProviderElement<List<StaffMember>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<StaffMember>> create(Ref ref) {
    return roster(ref);
  }
}

String _$rosterHash() => r'f61274aa1761be1f8dc67f3db618d856444b3bdd';

@ProviderFor(syncOutstanding)
final syncOutstandingProvider = SyncOutstandingProvider._();

final class SyncOutstandingProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  SyncOutstandingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncOutstandingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncOutstandingHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return syncOutstanding(ref);
  }
}

String _$syncOutstandingHash() => r'9c70eb2355ca3f867a0cabf80c2cd10b86d37bcb';

@ProviderFor(syncItems)
final syncItemsProvider = SyncItemsProvider._();

final class SyncItemsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SyncItem>>,
          List<SyncItem>,
          Stream<List<SyncItem>>
        >
    with $FutureModifier<List<SyncItem>>, $StreamProvider<List<SyncItem>> {
  SyncItemsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncItemsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncItemsHash();

  @$internal
  @override
  $StreamProviderElement<List<SyncItem>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<SyncItem>> create(Ref ref) {
    return syncItems(ref);
  }
}

String _$syncItemsHash() => r'6d376084b3479601d13e8196adac6424d28e312e';

@ProviderFor(syncTransport)
final syncTransportProvider = SyncTransportProvider._();

final class SyncTransportProvider
    extends $FunctionalProvider<SyncTransport, SyncTransport, SyncTransport>
    with $Provider<SyncTransport> {
  SyncTransportProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncTransportProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncTransportHash();

  @$internal
  @override
  $ProviderElement<SyncTransport> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SyncTransport create(Ref ref) {
    return syncTransport(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncTransport value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncTransport>(value),
    );
  }
}

String _$syncTransportHash() => r'68e69595a2a13e999defc22d21d46044224f6289';

@ProviderFor(syncEngine)
final syncEngineProvider = SyncEngineProvider._();

final class SyncEngineProvider
    extends $FunctionalProvider<SyncEngine, SyncEngine, SyncEngine>
    with $Provider<SyncEngine> {
  SyncEngineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncEngineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncEngineHash();

  @$internal
  @override
  $ProviderElement<SyncEngine> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SyncEngine create(Ref ref) {
    return syncEngine(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncEngine value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncEngine>(value),
    );
  }
}

String _$syncEngineHash() => r'804188852a22f34ab419ac6b2a0fee4578d34533';

/// Runs the outbox while a terminal is active: once at start (after
/// recovering interrupted items), whenever the network comes back, and every
/// 15 seconds. State is the last run's summary.

@ProviderFor(SyncScheduler)
final syncSchedulerProvider = SyncSchedulerProvider._();

/// Runs the outbox while a terminal is active: once at start (after
/// recovering interrupted items), whenever the network comes back, and every
/// 15 seconds. State is the last run's summary.
final class SyncSchedulerProvider
    extends $NotifierProvider<SyncScheduler, SyncRunSummary?> {
  /// Runs the outbox while a terminal is active: once at start (after
  /// recovering interrupted items), whenever the network comes back, and every
  /// 15 seconds. State is the last run's summary.
  SyncSchedulerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncSchedulerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncSchedulerHash();

  @$internal
  @override
  SyncScheduler create() => SyncScheduler();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncRunSummary? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncRunSummary?>(value),
    );
  }
}

String _$syncSchedulerHash() => r'ad3e5b39f2f1f3d257238b0355a18a3816510660';

/// Runs the outbox while a terminal is active: once at start (after
/// recovering interrupted items), whenever the network comes back, and every
/// 15 seconds. State is the last run's summary.

abstract class _$SyncScheduler extends $Notifier<SyncRunSummary?> {
  SyncRunSummary? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SyncRunSummary?, SyncRunSummary?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SyncRunSummary?, SyncRunSummary?>,
              SyncRunSummary?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
