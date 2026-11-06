import 'dart:async';

import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/empty_state.dart';
import 'package:cashiera/core/design_system/widgets/toasts.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/core/pos/pos_services.dart';
import 'package:cashiera/core/providers.dart';
import 'package:cashiera/core/session/session_controller.dart';
import 'package:cashiera/features/fnb/kitchen_send.dart';
import 'package:cashiera/features/printing/print_actions.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _order = ['new', 'preparing', 'ready', 'served'];

/// Minutes since the ticket opened → colour: fresh, late (10'), very late
/// (20').
Color ticketAgeColor(Duration age) => age.inMinutes >= 20
    ? AppColors.error
    : age.inMinutes >= 10
    ? AppColors.warning
    : AppColors.success;

/// Dapur: the kitchen display. Active tickets of the store, oldest first,
/// refreshed every 10 seconds and on Realtime changes. Mulai / Siap /
/// Disajikan go through the outbox and show at once.
class KitchenScreen extends ConsumerStatefulWidget {
  const new({super.key, this.refreshEvery = const Duration(seconds: 10)});

  final Duration refreshEvery;

  @override
  ConsumerState<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends ConsumerState<KitchenScreen> {
  String? _station;
  List<KitchenTicket> _tickets = const [];
  bool _loading = true;
  bool _offline = false;
  Timer? _timer;
  StreamSubscription<void>? _changes;

  /// `orderId|station` → status set here, until the server catches up.
  final _local = <String, String>{};

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
    _timer = Timer.periodic(widget.refreshEvery, (_) => unawaited(_refresh()));
    final storeId = ref.read(sessionControllerProvider).value?.device?.storeId;
    if (storeId != null) {
      try {
        _changes = ref
            .read(kitchenQueueSourceProvider)
            .changes(storeId)
            .listen((_) => unawaited(_refresh()), onError: (Object _) {});
      } on Object catch (_) {
        // Realtime is a bonus; polling keeps the screen current.
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_changes?.cancel());
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final tickets = await ref
          .read(kitchenQueueSourceProvider)
          .fetch(station: _station);
      if (!mounted) return;
      setState(() {
        _tickets = tickets;
        _loading = false;
        _offline = false;
        _local.removeWhere((key, status) {
          final t = tickets
              .where((t) => '${t.orderId}|${t.station}' == key)
              .firstOrNull;
          return t == null ||
              _order.indexOf(t.status) >= _order.indexOf(status);
        });
      });
    } on Object catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _offline = true;
        });
      }
    }
  }

  String _statusOf(KitchenTicket t) =>
      _local['${t.orderId}|${t.station}'] ?? t.status;

  Future<void> _advance(KitchenTicket t) async {
    final l10n = context.l10n;
    final staff = ref.read(sessionControllerProvider).value?.staff;
    final next = switch (_statusOf(t)) {
      'new' => 'preparing',
      'preparing' => 'ready',
      'ready' => 'served',
      _ => null,
    };
    if (staff == null || next == null) return;
    try {
      await ref
          .read(fnbServiceProvider)
          .setKitchenStatus(
            orderId: t.orderId,
            station: t.station,
            status: next,
            staff: staff,
          );
      setState(() => _local['${t.orderId}|${t.station}'] = next);
      ref.read(syncSchedulerProvider.notifier).syncNow().ignore();
    } on Exception catch (e) {
      if (mounted) AppToast.error(context, posErrorText(l10n, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final now = clock.now();
    final visible = [
      for (final t in _tickets)
        if (_statusOf(t) != 'served' &&
            (_station == null || t.station == _station))
          t,
    ];
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(AppRoutes.pos)),
        title: Text(l10n.kitchenTitle),
        actions: [
          IconButton(
            key: const Key('kitchen-refresh'),
            tooltip: l10n.kitchenRefresh,
            onPressed: () => unawaited(_refresh()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final s in const [null, 'kitchen', 'bar'])
                  ChoiceChip(
                    key: Key('kitchen-station-${s ?? 'all'}'),
                    label: Text(
                      s == null ? l10n.auditAll : stationLabel(l10n, s),
                    ),
                    selected: _station == s,
                    onSelected: (_) {
                      setState(() => _station = s);
                      unawaited(_refresh());
                    },
                  ),
              ],
            ),
          ),
          if (_offline)
            MaterialBanner(
              content: Text(l10n.kitchenOffline),
              leading: const Icon(Icons.cloud_off, color: AppColors.warning),
              actions: [
                TextButton(
                  onPressed: () => unawaited(_refresh()),
                  child: Text(l10n.kitchenRefresh),
                ),
              ],
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : visible.isEmpty
                ? EmptyState(
                    icon: Icons.soup_kitchen_outlined,
                    message: l10n.kitchenEmpty,
                  )
                : GridView.extent(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    maxCrossAxisExtent: 320,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    childAspectRatio: 0.8,
                    children: [
                      for (final t in visible)
                        _TicketCard(
                          key: Key('ticket-${t.orderNumber}-${t.station}'),
                          ticket: t,
                          status: _statusOf(t),
                          age: now.difference(t.createdAt),
                          onAdvance: () => _advance(t),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const new({
    required this.ticket,
    required this.status,
    required this.age,
    required this.onAdvance,
    super.key,
  });

  final KitchenTicket ticket;
  final String status;
  final Duration age;
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final color = ticketAgeColor(age);
    final t = ticket;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: color, width: 3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    t.tableName == null
                        ? l10n.orderTakeaway
                        : l10n.ticketTable(t.tableName!, t.guestCount ?? 0),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text(
                  l10n.kitchenAge(age.inMinutes),
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            Text(
              '${t.orderNumber.split('-').last} · '
              '${stationLabel(l10n, t.station)} · '
              '${l10n.kitchenStatus(status)}',
              style: theme.textTheme.bodySmall,
            ),
            const Divider(),
            Expanded(
              child: ListView(
                children: [
                  for (final i in t.items) ...[
                    Text(
                      '${i.quantity.toPlain()} × ${i.name}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    for (final m in i.modifiers) Text('  + $m'),
                    if (i.note != null && i.note!.isNotEmpty)
                      Text(
                        '  ! ${i.note}',
                        style: const TextStyle(color: AppColors.warning),
                      ),
                  ],
                  if (t.note != null && t.note!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(t.note!, style: theme.textTheme.bodySmall),
                    ),
                ],
              ),
            ),
            FilledButton(
              key: Key('ticket-next-${t.orderNumber}-${t.station}'),
              onPressed: onAdvance,
              child: Text(switch (status) {
                'new' => l10n.kitchenStart,
                'preparing' => l10n.kitchenReady,
                _ => l10n.kitchenServed,
              }),
            ),
          ],
        ),
      ),
    );
  }
}
