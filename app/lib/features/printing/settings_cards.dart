import 'dart:async';

import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/visual_effects.dart';
import 'package:cashiera/core/design_system/widgets/buttons.dart';
import 'package:cashiera/core/design_system/widgets/glass.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/core/providers.dart';
import 'package:cashiera/core/session/session_controller.dart';
import 'package:cashiera/features/sell/presentation/sell_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// A titled glass card used on the terminal's Settings page.
class SettingsCard extends StatelessWidget {
  const new({required this.title, required this.child, super.key});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      level: GlassLevel.solid,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const new(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: AppColors.textMuted);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 96, child: Text(label, style: muted)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

/// The store this terminal sells for, read-only (edited in the back office).
class StoreProfileCard extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final config = ref.watch(posConfigProvider).value;
    return SettingsCard(
      key: const Key('settings-store'),
      title: l10n.settingsStoreProfile,
      child: config == null
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  config.storeName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (config.storeAddress case final a?) Text(a),
                if (config.storePhone case final p?) Text(p),
                const SizedBox(height: AppSpacing.sm),
                _InfoRow(
                  l10n.settingsTax,
                  config.taxEnabled ? config.taxName : l10n.settingsTaxOff,
                ),
                _InfoRow(
                  l10n.settingsReceipt,
                  l10n.settingsPaper(config.paperMm),
                ),
              ],
            ),
    );
  }
}

/// The "Visual effects" switch: real blur on the top bar, dialogs, sheets.
class VisualEffectsCard extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final enabled = ref.watch(visualEffectsProvider).value ?? true;
    return GlassCard(
      level: GlassLevel.solid,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: SwitchListTile(
        key: const Key('settings-visual-effects'),
        contentPadding: EdgeInsets.zero,
        value: enabled,
        onChanged: (v) => unawaited(
          ref.read(visualEffectsRepositoryProvider).set(enabled: v),
        ),
        title: Text(l10n.settingsVisualEffects),
        subtitle: Text(l10n.settingsVisualEffectsHint),
      ),
    );
  }
}

/// This terminal, its connection and what still waits to be sent.
class TerminalSyncCard extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final device = ref.watch(sessionControllerProvider).value?.device;
    final online = ref.watch(onlineProvider).value ?? false;
    final pending = ref.watch(syncOutstandingProvider).value ?? 0;
    return SettingsCard(
      title: l10n.settingsTerminal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (device != null)
            _InfoRow(
              l10n.reportTerminal,
              [device.deviceCode, device.name].join(' · '),
            ),
          _InfoRow(
            l10n.syncTitle,
            [
              if (online) l10n.statusOnline else l10n.statusOffline,
              if (pending > 0) l10n.statusPending(pending),
            ].join(' · '),
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: SecondaryButton(
              key: const Key('settings-open-sync'),
              label: l10n.settingsOpenSync,
              icon: Icons.sync,
              onPressed: () => context.go(AppRoutes.sync),
            ),
          ),
        ],
      ),
    );
  }
}
