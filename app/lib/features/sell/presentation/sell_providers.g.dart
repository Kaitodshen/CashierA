// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sell_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(posConfig)
final posConfigProvider = PosConfigProvider._();

final class PosConfigProvider
    extends
        $FunctionalProvider<
          AsyncValue<PosConfig?>,
          PosConfig?,
          Stream<PosConfig?>
        >
    with $FutureModifier<PosConfig?>, $StreamProvider<PosConfig?> {
  PosConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'posConfigProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$posConfigHash();

  @$internal
  @override
  $StreamProviderElement<PosConfig?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<PosConfig?> create(Ref ref) {
    return posConfig(ref);
  }
}

String _$posConfigHash() => r'982dc346216ec29562da993ab1edc349a742ff37';

@ProviderFor(allPromotions)
final allPromotionsProvider = AllPromotionsProvider._();

final class AllPromotionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Promotion>>,
          List<Promotion>,
          Stream<List<Promotion>>
        >
    with $FutureModifier<List<Promotion>>, $StreamProvider<List<Promotion>> {
  AllPromotionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allPromotionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allPromotionsHash();

  @$internal
  @override
  $StreamProviderElement<List<Promotion>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Promotion>> create(Ref ref) {
    return allPromotions(ref);
  }
}

String _$allPromotionsHash() => r'087eefc748f405dbeefcb28e7f75460f9c9a8215';

/// Ticks so time-bound promotions start and stop without touching the cart.

@ProviderFor(posClock)
final posClockProvider = PosClockProvider._();

/// Ticks so time-bound promotions start and stop without touching the cart.

final class PosClockProvider
    extends
        $FunctionalProvider<AsyncValue<DateTime>, DateTime, Stream<DateTime>>
    with $FutureModifier<DateTime>, $StreamProvider<DateTime> {
  /// Ticks so time-bound promotions start and stop without touching the cart.
  PosClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'posClockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$posClockHash();

  @$internal
  @override
  $StreamProviderElement<DateTime> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<DateTime> create(Ref ref) {
    return posClock(ref);
  }
}

String _$posClockHash() => r'd08321de8cf011aeb0ee7f9630bbb9ef42f86c72';

/// The bill being rung up. Lives across screens (sell → pay → back) and
/// across staff switches, until it is finished, held or cleared.

@ProviderFor(CartController)
final cartControllerProvider = CartControllerProvider._();

/// The bill being rung up. Lives across screens (sell → pay → back) and
/// across staff switches, until it is finished, held or cleared.
final class CartControllerProvider
    extends $NotifierProvider<CartController, Cart> {
  /// The bill being rung up. Lives across screens (sell → pay → back) and
  /// across staff switches, until it is finished, held or cleared.
  CartControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cartControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cartControllerHash();

  @$internal
  @override
  CartController create() => CartController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Cart value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Cart>(value),
    );
  }
}

String _$cartControllerHash() => r'a1ace3beabe6a55f0784d5b827d202aed623775e';

/// The bill being rung up. Lives across screens (sell → pay → back) and
/// across staff switches, until it is finished, held or cleared.

abstract class _$CartController extends $Notifier<Cart> {
  Cart build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Cart, Cart>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Cart, Cart>,
              Cart,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The voucher entered on the cart, looked up in the local mirror.

@ProviderFor(cartVoucher)
final cartVoucherProvider = CartVoucherProvider._();

/// The voucher entered on the cart, looked up in the local mirror.

final class CartVoucherProvider
    extends
        $FunctionalProvider<AsyncValue<Voucher?>, Voucher?, FutureOr<Voucher?>>
    with $FutureModifier<Voucher?>, $FutureProvider<Voucher?> {
  /// The voucher entered on the cart, looked up in the local mirror.
  CartVoucherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cartVoucherProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cartVoucherHash();

  @$internal
  @override
  $FutureProviderElement<Voucher?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Voucher?> create(Ref ref) {
    return cartVoucher(ref);
  }
}

String _$cartVoucherHash() => r'8f5a064a515875f1a8edce89fc9d0ce8856263f1';

/// The current cart priced with this store's settings and the promotions
/// active right now.

@ProviderFor(currentBill)
final currentBillProvider = CurrentBillFamily._();

/// The current cart priced with this store's settings and the promotions
/// active right now.

final class CurrentBillProvider extends $FunctionalProvider<Bill?, Bill?, Bill?>
    with $Provider<Bill?> {
  /// The current cart priced with this store's settings and the promotions
  /// active right now.
  CurrentBillProvider._({
    required CurrentBillFamily super.from,
    required DiscountLabels super.argument,
  }) : super(
         retry: null,
         name: r'currentBillProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$currentBillHash();

  @override
  String toString() {
    return r'currentBillProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<Bill?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Bill? create(Ref ref) {
    final argument = this.argument as DiscountLabels;
    return currentBill(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Bill? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Bill?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CurrentBillProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$currentBillHash() => r'7c1354f9a34d0ed74743838c382494bf4d1d0ece';

/// The current cart priced with this store's settings and the promotions
/// active right now.

final class CurrentBillFamily extends $Family
    with $FunctionalFamilyOverride<Bill?, DiscountLabels> {
  CurrentBillFamily._()
    : super(
        retry: null,
        name: r'currentBillProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The current cart priced with this store's settings and the promotions
  /// active right now.

  CurrentBillProvider call(DiscountLabels labels) =>
      CurrentBillProvider._(argument: labels, from: this);

  @override
  String toString() => r'currentBillProvider';
}

/// Store, terminal, person on duty and shift, when all are known.

@ProviderFor(saleContext)
final saleContextProvider = SaleContextProvider._();

/// Store, terminal, person on duty and shift, when all are known.

final class SaleContextProvider
    extends $FunctionalProvider<SaleContext?, SaleContext?, SaleContext?>
    with $Provider<SaleContext?> {
  /// Store, terminal, person on duty and shift, when all are known.
  SaleContextProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'saleContextProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$saleContextHash();

  @$internal
  @override
  $ProviderElement<SaleContext?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SaleContext? create(Ref ref) {
    return saleContext(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SaleContext? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SaleContext?>(value),
    );
  }
}

String _$saleContextHash() => r'9f53a179407e82f6173877e8ca0a64b418bc7c21';
