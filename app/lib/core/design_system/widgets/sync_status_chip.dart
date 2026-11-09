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
          // A white glass pill with a coloured status dot, as in Stitch's
          // "● Terminal #01 · Online".
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.white.withValues(alpha: 0.7)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
