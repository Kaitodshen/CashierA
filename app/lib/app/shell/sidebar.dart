import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/glass.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:flutter/material.dart';

/// Sidebar widths of both shells.
abstract final class SidebarWidth {
  static const expanded = 240.0;
  static const collapsed = 72.0;
}

/// The CashierA logo tile at the top of a sidebar.
class LogoTile extends StatelessWidget {
  const new({required this.collapsed, this.trailing, super.key});

  final bool collapsed;

  /// The collapse toggle, shown to the right when expanded.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tile = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.control),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF43F5E), AppColors.primaryPressed],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(Icons.storefront, color: AppColors.white),
    );
    if (collapsed) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [tile, ?trailing],
      );
    }
    return Row(
      children: [
        tile,
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.appTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppColors.textStrong,
                ),
              ),
              Text(
                l10n.shellTagline,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: AppFonts.label,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// One sidebar destination. Selected: rose gradient pill, white text.
class SidebarItem extends StatelessWidget {
  const new({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.collapsed,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.white : AppColors.textSecondary;
    final radius = BorderRadius.circular(AppRadius.control);
    final item = AnimatedContainer(
      duration: AppMotion.fast,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: selected
            ? const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryPressed],
              )
            : null,
        boxShadow: selected
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.28),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: SizedBox(
            height: AppSizes.minTouch,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: collapsed ? 0 : AppSpacing.lg,
              ),
              child: Row(
                mainAxisAlignment: collapsed
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  Icon(icon, color: color, size: 22),
                  if (!collapsed) ...[
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppFonts.label,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          fontSize: 15,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: collapsed ? Tooltip(message: label, child: item) : item,
    );
  }
}

/// The sidebar frame: logo, destinations, and a footer card.
class AppSidebar extends StatelessWidget {
  const new({
    required this.collapsed,
    required this.items,
    this.toggle,
    this.footer,
    super.key,
  });

  final bool collapsed;
  final List<Widget> items;
  final Widget? toggle;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.normal,
      width: collapsed ? SidebarWidth.collapsed : SidebarWidth.expanded,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.35),
        border: Border(
          right: BorderSide(color: AppColors.white.withValues(alpha: 0.7)),
        ),
      ),
      child: SafeArea(
        right: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: collapsed ? AppSpacing.sm : AppSpacing.md,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LogoTile(collapsed: collapsed, trailing: toggle),
              const SizedBox(height: AppSpacing.xl),
              Expanded(child: ListView(children: items)),
              if (footer != null && !collapsed) footer!,
            ],
          ),
        ),
      ),
    );
  }
}

/// The footer card of a sidebar: status dot, a title and a subtitle.
class SidebarFooterCard extends StatelessWidget {
  const new({
    required this.title,
    required this.subtitle,
    required this.online,
    super.key,
  });

  final String title;
  final String subtitle;
  final bool online;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      level: GlassLevel.solid,
      radius: AppRadius.control,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: online ? AppColors.success : AppColors.error,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppFonts.label,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppFonts.label,
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            online ? Icons.wifi : Icons.wifi_off,
            size: 18,
            color: online ? AppColors.success : AppColors.error,
          ),
        ],
      ),
    );
  }
}
