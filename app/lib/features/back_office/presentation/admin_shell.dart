import 'package:cashiera/app/shell/sidebar.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/glass.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/core/session/session_controller.dart';
import 'package:cashiera/features/back_office/presentation/admin_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

IconData _icon(AdminSection s) => switch (s) {
  AdminSection.overview => Icons.space_dashboard_outlined,
  AdminSection.catalog => Icons.inventory_2_outlined,
  AdminSection.sales => Icons.sell_outlined,
  AdminSection.members => Icons.loyalty_outlined,
  AdminSection.settings => Icons.settings_outlined,
};

/// Back-office frame: the five-section sidebar (a drawer on phones), a top
/// bar with the page title and sign-out, and the section's page tabs.
class AdminShell extends ConsumerWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final location = GoRouterState.of(context).matchedLocation;
    final here = adminLocate(location);
    final tabs = adminTabs(here.section);
    final wide = context.isWide;

    void open(AdminSection s) {
      context.go(adminTabs(s).first.route);
      if (!wide) Navigator.of(context).maybePop();
    }

    List<Widget> items({required bool collapsed}) => [
      for (final s in AdminSection.values)
        SidebarItem(
          key: Key('admin-nav-${s.name}'),
          icon: _icon(s),
          label: adminSectionLabel(l10n, s),
          selected: s == here.section,
          collapsed: collapsed,
          onTap: () => open(s),
        ),
    ];

    final body = Column(
      children: [
        _AdminTopBar(
          title: tabs[here.tab].label(l10n),
          showMenu: !wide,
          onSignOut: () =>
              ref.read(sessionControllerProvider.notifier).signOut(),
        ),
        if (tabs.length > 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              0,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _Tabs(tabs: tabs, selected: here.tab),
            ),
          ),
        Expanded(child: child),
      ],
    );

    if (!wide) {
      return Scaffold(
        drawer: Drawer(
          backgroundColor: Colors.transparent,
          child: AppSidebar(collapsed: false, items: items(collapsed: false)),
        ),
        body: body,
      );
    }
    return Scaffold(
      body: Row(
        children: [
          AppSidebar(collapsed: false, items: items(collapsed: false)),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const new({required this.tabs, required this.selected});

  final List<AdminTab> tabs;
  final int selected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (i, tab) in tabs.indexed)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ChoiceChip(
                key: Key('admin-tab-${tab.route}'),
                label: Text(tab.label(l10n)),
                selected: i == selected,
                showCheckmark: false,
                onSelected: (_) => context.go(tab.route),
              ),
            ),
        ],
      ),
    );
  }
}

class _AdminTopBar extends StatelessWidget {
  const new({
    required this.title,
    required this.showMenu,
    required this.onSignOut,
  });

  final String title;
  final bool showMenu;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return GlassBlur(
      borderRadius: BorderRadius.zero,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.45),
          border: Border(
            bottom: BorderSide(color: AppColors.white.withValues(alpha: 0.7)),
          ),
        ),
        child: SafeArea(
          bottom: false,
          left: showMenu,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                if (showMenu)
                  Builder(
                    builder: (context) => IconButton(
                      key: const Key('admin-drawer-button'),
                      tooltip: l10n.shellMore,
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      icon: const Icon(Icons.menu, color: AppColors.text),
                    ),
                  ),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                GlassPill(
                  key: const Key('sign-out'),
                  onTap: onSignOut,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.logout),
                      const SizedBox(width: AppSpacing.sm),
                      Text(l10n.adminSignOut),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
