import 'dart:async';

import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/buttons.dart';
import 'package:cashiera/core/design_system/widgets/data_display.dart';
import 'package:cashiera/core/design_system/widgets/empty_state.dart';
import 'package:cashiera/core/design_system/widgets/flow.dart';
import 'package:cashiera/core/design_system/widgets/glass.dart';
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
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          FlowHeader(
            title: l10n.kitchenTitle,
            onBack: () => context.go(AppRoutes.pos),
            backKey: const Key('kitchen-back'),
            actions: [
              SecondaryButton(
                key: const Key('kitchen-refresh'),
                onPressed: () => unawaited(_refresh()),
                icon: Icons.refresh,
                label: l10n.kitchenRefresh,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          GlassCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final s in const [null, 'kitchen', 'bar'])
                  ChoiceChip(
                    key: Key('kitchen-station-${s ?? 'all'}'),
                    label: Text(
                      s == null ? l10n.auditAll : stationLabel(l10n, s),
                    ),
                    selected: _station == s,
                    showCheckmark: false,
                    onSelected: (_) {
                      setState(() => _station = s);
                      unawaited(_refresh());
                    },
                  ),
              ],
            ),
          ),
          if (_offline) ...[
            const SizedBox(height: AppSpacing.md),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.warningSoft,
                borderRadius: BorderRadius.circular(AppRadius.control),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.cloud_off,
                  color: AppColors.warningText,
                ),
                title: Text(l10n.kitchenOffline),
                trailing: TextButton(
                  onPressed: () => unawaited(_refresh()),
                  child: Text(l10n.kitchenRefresh),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (visible.isEmpty)
            GlassCard(
              child: EmptyState(
                icon: Icons.soup_kitchen_outlined,
                message: l10n.kitchenEmpty,
              ),
            )
          else
            LayoutBuilder(
              builder: (context, c) {
                final width = c.maxWidth < 320 ? c.maxWidth : 320.0;
                return Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    for (final t in visible)
                      SizedBox(
                        width: width,
                        child: _TicketCard(
                          key: Key('ticket-${t.orderNumber}-${t.station}'),
                          ticket: t,
                          status: _statusOf(t),
                          age: now.difference(t.createdAt),
                          onAdvance: () => _advance(t),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

StatusTone ticketAgeTone(Duration age) => age.inMinutes >= 20
    ? StatusTone.error
    : age.inMinutes >= 10
    ? StatusTone.warning
    : StatusTone.success;

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
    final t = ticket;
    return GlassCard(
      level: GlassLevel.solid,
      radius: AppRadius.tile,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  t.tableName == null
                      ? l10n.orderTakeaway
                      : l10n.ticketTable(t.tableName!, t.guestCount ?? 0),
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusChip(
                label: l10n.kitchenAge(age.inMinutes),
                tone: ticketAgeTone(age),
              ),
            ],
          ),
          Text(
            '${t.orderNumber.split('-').last} · '
            '${stationLabel(l10n, t.station)} · '
            '${l10n.kitchenStatus(status)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const Divider(height: AppSpacing.xl),
          for (final i in t.items) ...[
            Text(
              '${i.quantity.toPlain()} × ${i.name}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            for (final m in i.modifiers) Text('  + $m'),
            if (i.note != null && i.note!.isNotEmpty)
              Text(
                '  ! ${i.note}',
                style: const TextStyle(color: AppColors.warningText),
              ),
          ],
          if (t.note != null && t.note!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(t.note!, style: theme.textTheme.bodySmall),
            ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            key: Key('ticket-next-${t.orderNumber}-${t.station}'),
            expand: true,
            onPressed: onAdvance,
            label: switch (status) {
              'new' => l10n.kitchenStart,
              'preparing' => l10n.kitchenReady,
              _ => l10n.kitchenServed,
            },
          ),
        ],
      ),
    );
  }
}
