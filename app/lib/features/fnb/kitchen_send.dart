import 'package:cashiera/core/design_system/widgets/toasts.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/core/pos/cart.dart';
import 'package:cashiera/core/pos/pos_services.dart';
import 'package:cashiera/core/printing/printer_setting.dart';
import 'package:cashiera/core/printing/printer_transport.dart';
import 'package:cashiera/core/printing/slips.dart';
import 'package:cashiera/core/providers.dart';
import 'package:cashiera/features/printing/print_actions.dart';
import 'package:cashiera/features/sell/presentation/cart_panel.dart';
import 'package:cashiera/features/sell/presentation/sell_providers.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

String stationLabel(AppLocalizations l10n, String station) => switch (station) {
  'bar' => l10n.stationBar,
  _ => l10n.stationKitchen,
};

/// The tickets for what [cart] has not sent yet: one per station.
Map<String, ReceiptDocument> kitchenTickets(
  Cart cart, {
  required AppLocalizations l10n,
  required String timeText,
}) {
  final pending = pendingKitchenLines(cart);
  final addition = cart.kitchenSent.isNotEmpty;
  return {
    for (final MapEntry(key: station, value: lines) in pending.entries)
      station: kitchenTicketDocument(
        stationLabel: stationLabel(l10n, station),
        orderNumber: cart.orderNumber ?? '',
        timeText: timeText,
        lines: lines,
        tableLine: cart.tableName == null
            ? l10n.orderTakeaway
            : l10n.ticketTable(cart.tableName!, cart.guestCount ?? 0),
        note: cart.note,
        additionLabel: addition ? l10n.ticketAddition : null,
      ),
  };
}

/// Kirim ke dapur: holds the bill (the server opens the kitchen tickets),
/// then prints what is new on the kitchen and bar printers. A missing or
/// failing printer never loses the order: the kitchen display has it.
/// Returns true when the bill was held.
Future<bool> sendToKitchen(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final ctx = ref.read(saleContextProvider);
  final bill = ref.read(currentBillProvider(discountLabels(l10n)));
  if (ctx == null || bill == null) return false;
  if (!await ensureDiscountApproval(context, ref)) return false;
  final cart = ref.read(cartControllerProvider);
  final Cart held;
  try {
    held = await ref
        .read(orderServiceProvider)
        .hold(cart: markKitchenSent(cart), bill: bill, ctx: ctx);
  } on Exception catch (e) {
    if (context.mounted) AppToast.error(context, posErrorText(l10n, e));
    return false;
  }
  ref.read(cartControllerProvider.notifier).clear();
  ref.read(syncSchedulerProvider.notifier).syncNow().ignore();

  // What was new before this send, numbered now.
  final tickets = kitchenTickets(
    Cart.fromJson({...cart.toJson(), 'order_number': held.orderNumber}),
    l10n: l10n,
    timeText: DateFormat('HH:mm').format(ctx.config.localTime(clock.now())),
  );
  final repo = ref.read(printerRepositoryProvider);
  final printer = ref.read(printerServiceProvider);
  final missing = <String>[];
  for (final MapEntry(key: station, value: doc) in tickets.entries) {
    final slot = station == 'bar'
        ? PrinterRepository.barId
        : PrinterRepository.kitchenId;
    final setting = await repo.current(slot: slot);
    if (setting == null) {
      missing.add(stationLabel(l10n, station));
      continue;
    }
    try {
      await printer.print(doc, using: setting);
    } on PrinterException catch (e) {
      if (context.mounted) {
        AppToast.error(context, printerErrorText(l10n, e));
      }
    }
  }
  if (context.mounted) {
    AppToast.success(context, l10n.kitchenSent(held.orderNumber!));
    if (missing.isNotEmpty) {
      AppToast.info(context, l10n.kitchenNoPrinter(missing.join(', ')));
    }
  }
  return true;
}
