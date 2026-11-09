import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/empty_state.dart';
import 'package:cashiera/core/design_system/widgets/toasts.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/core/pos/pos_services.dart';
import 'package:cashiera/core/providers.dart';
import 'package:cashiera/core/session/session_controller.dart';
import 'package:cashiera/features/printing/print_actions.dart';
import 'package:cashiera/features/sell/presentation/sell_providers.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final StreamProvider<List<DiningTable>> diningTablesProvider =
    StreamProvider.autoDispose<List<DiningTable>>(
      (ref) => ref.watch(fnbServiceProvider).watchTables(),
    );

Color tableColor(String status) => switch (status) {
  'occupied' => AppColors.warning,
  'cleaning' => AppColors.info,
  'reserved' => AppColors.error,
  _ => AppColors.success,
};

/// Meja (F&B): the store's tables. A free table starts a dine-in bill, a
/// table with this terminal's bill resumes it, and a table whose guests
/// left is cleared.
class TablesScreen extends ConsumerWidget {
  const new({super.key});

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    DiningTable table,
  ) async {
    final l10n = context.l10n;
    final cart = ref.read(cartControllerProvider);
    final controller = ref.read(cartControllerProvider.notifier);
    final busyCart = !cart.isEmpty || cart.version > 0;

    if (table.heldOrder case final order?) {
      if (busyCart && cart.orderId != order.id) {
        AppToast.error(context, l10n.tableFinishCurrent);
        return;
      }
      controller.resume(order);
      context.go(AppRoutes.sell);
      return;
    }
    if (table.occupied) {
      AppToast.error(context, l10n.tableOccupiedElsewhere(table.name));
      return;
    }
    if (busyCart && (cart.version > 0 || cart.tableId != null)) {
      AppToast.error(context, l10n.tableFinishCurrent);
      return;
    }
    final guests = await _askGuests(context, table);
    if (guests == null || !context.mounted) return;
    controller.seatAt(tableId: table.id, tableName: table.name, guests: guests);
    context.go(AppRoutes.sell);
  }

  Future<int?> _askGuests(BuildContext context, DiningTable table) =>
      showDialog<int>(
        context: context,
        builder: (_) => _GuestsDialog(table: table),
      );

  Future<void> _clear(
    BuildContext context,
    WidgetRef ref,
    DiningTable table,
  ) async {
    final l10n = context.l10n;
    final staff = ref.read(sessionControllerProvider).value?.staff;
    if (staff == null) return;
    try {
      await ref.read(fnbServiceProvider).clearTable(table: table, staff: staff);
      ref.read(syncSchedulerProvider.notifier).syncNow().ignore();
      if (context.mounted) {
        AppToast.success(context, l10n.tableCleared(table.name));
      }
    } on PosStateException catch (e) {
      if (context.mounted) AppToast.error(context, posErrorText(l10n, e));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final tables = ref.watch(diningTablesProvider);
    final list = tables.value ?? const <DiningTable>[];
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(AppRoutes.pos)),
        title: Text(l10n.navTables),
        actions: [
          TextButton.icon(
            key: const Key('tables-sell'),
            onPressed: () => context.go(AppRoutes.sell),
            icon: const Icon(Icons.point_of_sale),
            label: Text(l10n.posSell),
          ),
        ],
      ),
      body: tables.isLoading && list.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : list.isEmpty
          ? EmptyState(
              icon: Icons.table_restaurant,
              message: l10n.tablesEmptyTerminal,
            )
          : GridView.extent(
              padding: const EdgeInsets.all(AppSpacing.lg),
              maxCrossAxisExtent: 200,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.1,
              children: [
                for (final t in list)
                  _TableCard(
                    key: Key('pos-table-${t.name}'),
                    table: t,
                    onTap: () => _open(context, ref, t),
                    onClear: t.heldOrder == null && t.status != 'available'
                        ? () => _clear(context, ref, t)
                        : null,
                  ),
              ],
            ),
    );
  }
}

class _TableCard extends StatelessWidget {
  const new({
    required this.table,
    required this.onTap,
    required this.onClear,
    super.key,
  });

  final DiningTable table;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final color = tableColor(table.status);
    final order = table.heldOrder;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: color, width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.table_restaurant, color: color),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(table.name, style: theme.textTheme.titleMedium),
                  ),
                ],
              ),
              Text(
                [?table.area, l10n.tableSeats(table.capacity)].join(' · '),
                style: theme.textTheme.bodySmall,
              ),
              const Spacer(),
              Text(
                l10n.tableStatus(table.status),
                key: Key('pos-table-status-${table.name}'),
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
              if (order != null)
                Text(
                  '${order.orderNumber.split('-').last} · '
                  '${Money(order.grandTotal).format()}',
                  style: theme.textTheme.bodySmall,
                ),
              if (onClear != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    key: Key('pos-table-clear-${table.name}'),
                    onPressed: onClear,
                    child: Text(l10n.tableClear),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuestsDialog extends StatefulWidget {
  const new({required this.table});
  final DiningTable table;

  @override
  State<_GuestsDialog> createState() => _GuestsDialogState();
}

class _GuestsDialogState extends State<_GuestsDialog> {
  late final _field = TextEditingController(
    text: '${widget.table.capacity.clamp(1, 2)}',
  );

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _submit() {
    final n = int.tryParse(_field.text) ?? 0;
    if (n >= 1 && n <= 99) Navigator.pop(context, n);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.tableGuestsTitle(widget.table.name)),
      content: TextField(
        key: const Key('table-guests'),
        controller: _field,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(labelText: l10n.tableGuests),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          key: const Key('table-guests-ok'),
          onPressed: _submit,
          child: Text(l10n.tableSeat),
        ),
      ],
    );
  }
}
