import 'dart:async';

import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/admin.dart';
import 'package:cashiera/core/design_system/widgets/buttons.dart';
import 'package:cashiera/core/design_system/widgets/glass_table.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/features/back_office/data/shift_audit_repository.dart';
import 'package:cashiera/features/back_office/presentation/admin_shifts_screen.dart';
import 'package:cashiera/features/back_office/presentation/back_office_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Audit log kinds offered as a filter: (action prefix, label).
List<(String?, String)> auditKinds(AppLocalizations l10n) => [
  (null, l10n.auditAll),
  ('order.', l10n.auditKindOrders),
  ('shift.', l10n.auditKindShifts),
  ('cash.', l10n.auditKindCash),
  ('pos.', l10n.auditKindPos),
  ('receipt.', l10n.auditKindReceipts),
  ('device.', l10n.auditKindDevices),
  ('data.', l10n.auditKindData),
];

/// `order.voided` → its name in the back office's language.
String auditActionText(AppLocalizations l10n, AuditEntry e) {
  final name = l10n.auditActionName(e.action.replaceAll('.', '_'));
  if (name != e.action.replaceAll('.', '_')) return name;
  return e.entityType == null ? e.action : '${e.action} · ${e.entityType}';
}

/// `reason: Salah input · grand_total: 7000`.
String auditDetailsText(Map<String, dynamic> details) => [
  for (final MapEntry(:key, :value) in details.entries)
    if (value != null && value is! Map && value is! List) '$key: $value',
].join(' · ');

class AuditScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends ConsumerState<AuditScreen> {
  static const _page = 50;
  String? _storeId;
  DateTimeRange _period = lastDays(7);
  bool _onlyApprovals = false;
  String? _prefix;

  final _entries = <AuditEntry>[];
  bool _loading = false;
  bool _more = false;
  Object? _error;

  /// Bumped on every new query so late pages of an old one are dropped.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_reload());
  }

  AuditQuery get _query => AuditQuery(
    storeId: _storeId,
    from: _period.start,
    to: _period.end.add(const Duration(days: 1)),
    onlyApprovals: _onlyApprovals,
    actionPrefix: _prefix,
  );

  Future<void> _reload() async {
    _generation++;
    setState(() {
      _entries.clear();
      _more = false;
      _error = null;
    });
    await _load();
  }

  Future<void> _load() async {
    final generation = _generation;
    setState(() => _loading = true);
    try {
      final page = await ref
          .read(shiftAuditProvider)
          .audit(_query, after: _entries.isEmpty ? null : _entries.last);
      if (!mounted || generation != _generation) return;
      setState(() {
        _entries.addAll(page);
        _more = page.length == _page;
      });
    } on Object catch (e) {
      if (mounted && generation == _generation) setState(() => _error = e);
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  void _change(VoidCallback update) {
    setState(update);
    unawaited(_reload());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final time = DateFormat('dd/MM/yyyy HH:mm');

    final muted = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: AppColors.textMuted);

    return AdminPage(
      toolbar: AdminToolbar(
        filters: [
          StoreFilter(
            value: _storeId,
            onChanged: (v) => _change(() => _storeId = v),
          ),
          PeriodFilter(
            value: _period,
            onChanged: (v) => _change(() => _period = v),
          ),
          DropdownButton<String?>(
            key: const Key('audit-kind'),
            value: _prefix,
            hint: Text(l10n.auditKind),
            items: [
              for (final (prefix, label) in auditKinds(l10n))
                DropdownMenuItem(value: prefix, child: Text(label)),
            ],
            onChanged: (v) => _change(() => _prefix = v),
          ),
          FilterChip(
            key: const Key('audit-approvals'),
            label: Text(l10n.auditOnlyApprovals),
            selected: _onlyApprovals,
            onSelected: (v) => _change(() => _onlyApprovals = v),
          ),
        ],
      ),
      children: [
        if (_error != null)
          adminMessage(
            icon: Icons.cloud_off_outlined,
            message: l10n.commonError('$_error'),
          )
        else if (_entries.isEmpty && _loading)
          const Center(child: CircularProgressIndicator())
        else if (_entries.isEmpty)
          adminMessage(icon: Icons.policy_outlined, message: l10n.auditEmpty)
        else ...[
          GlassTable<AuditEntry>(
            rows: _entries,
            columns: [
              GlassColumn(
                label: l10n.auditKind,
                flex: 3,
                cell: (e) => Row(
                  key: Key('audit-${e.id}'),
                  children: [
                    Icon(
                      e.approverName != null
                          ? Icons.verified_user_outlined
                          : Icons.history,
                      color: e.approverName != null
                          ? AppColors.warning
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            auditActionText(l10n, e),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            [
                              time.format(e.occurredAt.toLocal()),
                              ?e.storeName,
                              ?e.deviceCode,
                            ].join(' · '),
                            style: muted,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              GlassColumn(
                label: l10n.auditWho,
                flex: 2,
                cell: (e) => Text(
                  [
                    e.actorName ?? l10n.auditSystem,
                    if (e.approverName != null)
                      l10n.auditApprovedBy(e.approverName!),
                  ].join(' · '),
                ),
              ),
              GlassColumn(
                label: l10n.auditDetail,
                flex: 3,
                cell: (e) => Text(auditDetailsText(e.details), style: muted),
              ),
            ],
          ),
          if (_more)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Center(
                child: SecondaryButton(
                  key: const Key('audit-more'),
                  onPressed: _loading ? null : _load,
                  label: l10n.auditLoadMore,
                ),
              ),
            ),
        ],
      ],
    );
  }
}
