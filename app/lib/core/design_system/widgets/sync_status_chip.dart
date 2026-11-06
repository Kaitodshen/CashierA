import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:flutter/material.dart';

/// Header indicator: Online/Offline plus the number of queue items not yet
/// confirmed by the server (PENDING + SYNCING + FAILED).
class SyncStatusChip extends StatelessWidget {
  const new({
    required this.online,
    required this.pending,
    this.onTap,
    super.key,
  });

  final bool online;
  final int pending;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = !online
        ? AppColors.error
        : pending > 0
        ? AppColors.warning
        : AppColors.success;
    final label = [
      if (online) l10n.statusOnline else l10n.statusOffline,
      if (pending > 0) l10n.statusPending(pending),
    ].join(' · ');

    return Semantics(
      button: onTap != null,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSizes.minTouch - 8),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                online ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                size: 18,
                color: color,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
