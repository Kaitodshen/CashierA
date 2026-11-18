import 'package:cashiera/core/design_system/tokens.dart';
import 'package:flutter/material.dart';

/// The rose gradient action button with a soft glow (Pay, Save, Add).
class PrimaryButton extends StatelessWidget {
  const new({
    required this.label,
    required this.onPressed,
    this.icon,
    this.shortcut,
    this.expand = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// A keyboard hint shown on the right, e.g. `F12`.
  final String? shortcut;

  /// Fill the available width.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final shape = BorderRadius.circular(AppRadius.control);
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: AppColors.white),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(
          fit: expand ? FlexFit.tight : FlexFit.loose,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: AppFonts.label,
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: AppColors.white,
            ),
          ),
        ),
        if (shortcut != null) ...[
          const SizedBox(width: AppSpacing.md),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.small - 2),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Text(
                shortcut!,
                style: const TextStyle(
                  fontFamily: AppFonts.label,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ],
    );

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: shape,
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryPressed],
          ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: shape,
            onTap: onPressed,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSizes.minTouch),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The white glass button for secondary actions (Export, Hold, Note).
class SecondaryButton extends StatelessWidget {
  const new({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon == null ? null : Icon(icon, size: 20),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}
