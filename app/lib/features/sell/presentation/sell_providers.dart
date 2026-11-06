import 'dart:convert';

import 'package:cashiera/core/catalog/catalog_item.dart';
import 'package:cashiera/core/database/app_database.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/core/pos/cart.dart';
import 'package:cashiera/core/pos/pos_config.dart';
import 'package:cashiera/core/pos/pos_services.dart';
import 'package:cashiera/core/providers.dart';
import 'package:cashiera/core/session/session_controller.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'sell_providers.g.dart';

String? _storeId(Ref ref) => ref.watch(
  sessionControllerProvider.select((s) => s.value?.device?.storeId),
);

// Written by hand: riverpod_generator cannot name Drift row types.

/// The terminal's open shift, or null.
final StreamProvider<ShiftRow?> openShiftProvider =
    StreamProvider.autoDispose<ShiftRow?>((ref) {
      final storeId = _storeId(ref);
      if (storeId == null) return Stream.value(null);
      return ref.watch(shiftServiceProvider).watchOpen(storeId);
    });

final StreamProvider<List<LocalOrderRow>> heldOrdersProvider =
    StreamProvider.autoDispose<List<LocalOrderRow>>(
      (ref) => ref.watch(orderServiceProvider).watch(statuses: {'held'}),
    );

/// Today's bills (store-local day), newest first.
final StreamProvider<List<LocalOrderRow>> todaysOrdersProvider =
    StreamProvider.autoDispose<List<LocalOrderRow>>((ref) {
      final config = ref.watch(posConfigProvider).value;
      final offset = Duration(minutes: config?.utcOffsetMinutes ?? 7 * 60);
      final local = clock.now().toUtc().add(offset);
      final startOfDay = DateTime.utc(
        local.year,
        local.month,
        local.day,
      ).subtract(offset);
      return ref
          .watch(orderServiceProvider)
          .watch(
            statuses: {'completed', 'cancelled', 'held', 'voided'},
            since: startOfDay.toLocal(),
          );
    });

@Riverpod(keepAlive: true)
Stream<PosConfig?> posConfig(Ref ref) {
  final storeId = _storeId(ref);
  if (storeId == null) return Stream.value(null);
  return ref.watch(posConfigRepositoryProvider).watch(storeId);
}

@Riverpod(keepAlive: true)
Stream<List<Promotion>> allPromotions(Ref ref) =>
    ref.watch(posConfigRepositoryProvider).watchPromotions();

/// Ticks so time-bound promotions start and stop without touching the cart.
@Riverpod(keepAlive: true)
Stream<DateTime> posClock(Ref ref) async* {
  yield clock.now();
  yield* Stream.periodic(const Duration(seconds: 30), (_) => clock.now());
}

/// Discount descriptions in the till's language.
DiscountLabels discountLabels(AppLocalizations l10n) => DiscountLabels(
  manualLine: l10n.discountManualLine,
  manualBill: l10n.discountManualBill,
  voucherPrefix: l10n.discountVoucher,
  points: l10n.discountPoints,
);

/// The bill being rung up. Lives across screens (sell → pay → back) and
/// across staff switches, until it is finished, held or cleared.
@Riverpod(keepAlive: true)
class CartController extends _$CartController {
  static const _uuid = Uuid();

  @override
  Cart build() => _fresh();

  Cart _fresh() => Cart(orderId: _uuid.v7(), startedAt: clock.now());

  /// Adds [item] (or adds to its line). Weighed items get their own line.
  void add(
    CatalogItem item, {
    Qty? quantity,
    List<CartModifier> modifiers = const [],
  }) {
    final line = CartLine(
      id: _uuid.v7(),
      variantId: item.variantId,
      productId: item.productId,
      categoryId: item.categoryId,
      productName: item.productName,
      variantName: item.variantName,
      sku: item.sku,
      unitCode: item.unitCode,
      allowDecimal: item.allowDecimal,
      unitPrice: item.price,
      unitCost: item.cost,
      isTaxable: item.isTaxable,
      trackStock: item.trackStock,
      quantity: quantity ?? Qty.one,
      modifiers: modifiers,
      kitchenStation: item.kitchenStation,
    );
    final lines = [...state.lines];
    final same = item.allowDecimal
        ? -1
        : lines.indexWhere((l) => l.sameItemAs(line));
    if (same >= 0) {
      final existing = lines[same];
      lines[same] = existing.copyWith(
        quantity: Qty(existing.quantity.milli + line.quantity.milli),
      );
    } else {
      lines.add(line);
    }
    state = state.copyWith(lines: lines);
  }

  void setQuantity(String lineId, Qty quantity) {
    if (quantity.milli <= 0) return remove(lineId);
    _update(lineId, (l) => l.copyWith(quantity: quantity));
  }

  void step(String lineId, int delta) {
    final line = state.lines.firstWhere((l) => l.id == lineId);
    setQuantity(lineId, Qty(line.quantity.milli + delta * 1000));
  }

  void remove(String lineId) => state = state.copyWith(
    lines: state.lines.where((l) => l.id != lineId).toList(),
  );

  void setLineDiscount(String lineId, DiscountSpec? discount) => _update(
    lineId,
    (l) => discount == null
        ? l.copyWith(clearDiscount: true)
        : l.copyWith(manualDiscount: discount),
  );

  void setLineNote(String lineId, String note) => _update(
    lineId,
    (l) => note.trim().isEmpty
        ? l.copyWith(clearNote: true)
        : l.copyWith(note: note.trim()),
  );

  void setBillDiscount(DiscountSpec? discount) => state = discount == null
      ? state.copyWith(clearBillDiscount: true)
      : state.copyWith(billDiscount: discount);

  /// Records who approved the manual discounts (or clears it).
  void setApprover(String? employeeId) => state = employeeId == null
      ? state.copyWith(clearApproval: true)
      : state.copyWith(approvedBy: employeeId);

  void setCustomer(CartCustomer? customer) => state = customer == null
      ? state.copyWith(clearCustomer: true)
      : state.copyWith(customer: customer);

  void setVoucher(String? code) => state = code == null
      ? state.copyWith(clearVoucher: true)
      : state.copyWith(voucherCode: code.trim().toUpperCase());

  /// Points to spend on this bill (0 removes them).
  void setPointsToRedeem(int points) =>
      state = state.copyWith(pointsToRedeem: points < 0 ? 0 : points);

  void resume(LocalOrderRow order) => state = Cart.fromJson(
    (jsonDecode(order.cartJson) as Map).cast<String, dynamic>(),
  );

  void clear() => state = _fresh();

  /// Starts a dine-in bill on [tableId] (F&B), or moves the current one there.
  void seatAt({
    required String tableId,
    required String tableName,
    required int guests,
  }) => state = state.copyWith(
    orderType: 'dine_in',
    tableId: tableId,
    tableName: tableName,
    guestCount: guests,
  );

  /// Back to a takeaway bill.
  void clearTable() => state = state.copyWith(clearTable: true);

  void _update(String lineId, CartLine Function(CartLine) change) =>
      state = state.copyWith(
        lines: [
          for (final l in state.lines)
            if (l.id == lineId) change(l) else l,
        ],
      );
}

/// The voucher entered on the cart, looked up in the local mirror.
@riverpod
Future<Voucher?> cartVoucher(Ref ref) async {
  final code = ref.watch(cartControllerProvider.select((c) => c.voucherCode));
  if (code == null) return null;
  return await ref.watch(posConfigRepositoryProvider).findVoucher(code);
}

/// The current cart priced with this store's settings and the promotions
/// active right now.
@riverpod
Bill? currentBill(Ref ref, DiscountLabels labels) {
  final config = ref.watch(posConfigProvider).value;
  if (config == null) return null;
  final cart = ref.watch(cartControllerProvider);
  final now = ref.watch(posClockProvider).value ?? clock.now();
  final promotions = (ref.watch(allPromotionsProvider).value ?? const [])
      .where(
        (p) => p.isActiveAt(
          now,
          utcOffsetMinutes: config.utcOffsetMinutes,
          storeId: config.storeId,
        ),
      )
      .toList();
  return calculateBill(
    lines: [for (final l in cart.lines) l.toPricing()],
    settings: config.pricing,
    promotions: promotions,
    billDiscount: cart.billDiscount,
    voucher: ref.watch(cartVoucherProvider).value,
    points: cart.customer == null || cart.pointsToRedeem <= 0
        ? null
        : PointsRedemption(
            points: cart.pointsToRedeem,
            pointValue: config.business.loyalty.pointValue,
          ),
    now: now.toUtc(),
    labels: labels,
  );
}

/// Store, terminal, person on duty and shift, when all are known.
@riverpod
SaleContext? saleContext(Ref ref) {
  final session = ref.watch(sessionControllerProvider).value;
  final config = ref.watch(posConfigProvider).value;
  final device = session?.device;
  final staff = session?.staff;
  if (config == null || device == null || staff == null) return null;
  return SaleContext(
    config: config,
    deviceCode: device.deviceCode,
    staff: staff,
    shiftId: ref.watch(openShiftProvider).value?.id,
  );
}
