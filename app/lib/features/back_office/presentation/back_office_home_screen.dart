import 'package:cashiera/core/auth/models.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/empty_state.dart';
import 'package:cashiera/core/design_system/widgets/toasts.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/core/providers.dart';
import 'package:cashiera/features/back_office/data/back_office_backend.dart';
import 'package:cashiera/features/back_office/presentation/back_office_providers.dart';
import 'package:cashiera/features/reports/presentation/dashboard_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Back-office start page: who is signed in, their stores, and pairing codes
/// for new terminals. Catalog, staff and reports pages arrive in later phases.
class BackOfficeHomeScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final principal = ref.watch(principalProvider);

    return Scaffold(
      body: switch (principal) {
        AsyncData(:final value) when !value.isEmployee => EmptyState(
          icon: Icons.person_off_outlined,
          message: l10n.adminNotStaff,
        ),
        AsyncData(:final value) => _Stores(principal: value),
        AsyncError(:final error) => EmptyState(
          icon: Icons.cloud_off_outlined,
          message: l10n.commonError('$error'),
          action: OutlinedButton(
            onPressed: () => ref.invalidate(principalProvider),
            child: Text(l10n.commonRetry),
          ),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Stores extends ConsumerWidget {
  const new({required this.principal});

  final Principal principal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final stores = ref.watch(backOfficeStoresProvider);
    final list = stores.value ?? const <StoreSummary>[];

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          principal.fullName ?? '',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          l10n.adminRole(principal.roleName ?? '', principal.storeIds.length),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (principal.can('reports.view')) ...[
          const SizedBox(height: AppSpacing.xl),
          const DashboardPanel(),
        ],
        const SizedBox(height: AppSpacing.xl),
        Text(l10n.adminStores, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        if (stores.hasError)
          EmptyState(
            icon: Icons.cloud_off_outlined,
            message: l10n.commonError('${stores.error}'),
          )
        else if (!stores.isLoading && list.isEmpty)
          EmptyState(icon: Icons.store_outlined, message: l10n.adminNoStores)
        else
          Skeletonizer(
            enabled: stores.isLoading,
            child: Column(
              children: [
                for (final store in stores.isLoading ? _placeholders : list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Text(store.code)),
                        title: Text(store.name),
                        subtitle: store.address == null
                            ? null
                            : Text(store.address!),
                        trailing: principal.can('device.manage')
                            ? OutlinedButton.icon(
                                onPressed: () =>
                                    _createCode(context, ref, store),
                                icon: const Icon(Icons.qr_code_2),
                                label: Text(l10n.adminPairTerminal),
                              )
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  static const _placeholders = [
    StoreSummary(id: '1', code: 'PST', name: 'Nama toko contoh'),
    StoreSummary(id: '2', code: 'BKS', name: 'Nama toko contoh'),
  ];

  Future<void> _createCode(
    BuildContext context,
    WidgetRef ref,
    StoreSummary store,
  ) async {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _DeviceNameDialog(),
    );
    if (name == null || !context.mounted) return;
    try {
      final code = await ref
          .read(backOfficeBackendProvider)
          .createPairingCode(store.id, name);
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.adminCodeTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SelectableText(
                code.code,
                key: const Key('pairing-code-value'),
                style: Theme.of(context).textTheme.displaySmall
                    ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 6),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.adminCodeBody(
                  DateFormat.Hm(locale).format(code.expiresAt),
                ),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.commonClose),
            ),
          ],
        ),
      );
    } on BackendException catch (e) {
      if (context.mounted) AppToast.error(context, l10n.commonError(e.message));
    }
  }
}

class _DeviceNameDialog extends StatefulWidget {
  const new();

  @override
  State<_DeviceNameDialog> createState() => _DeviceNameDialogState();
}

class _DeviceNameDialogState extends State<_DeviceNameDialog> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _name.text.trim();
    if (value.isNotEmpty) Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.adminPairTerminal),
      content: TextField(
        controller: _name,
        autofocus: true,
        decoration: InputDecoration(
          labelText: l10n.adminDeviceName,
          hintText: l10n.adminDeviceNameHint,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.adminCreateCode)),
      ],
    );
  }
}
