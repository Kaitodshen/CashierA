import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/core/session/session_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class _Destination {
  const new(this.route, this.icon, this.label);

  final String route;
  final IconData icon;
  final String Function(AppLocalizations) label;
}

final _destinations = <_Destination>[
  _Destination(AppRoutes.admin, Icons.dashboard_outlined, (l) => l.navHome),
  _Destination(
    AppRoutes.adminProducts,
    Icons.inventory_2_outlined,
    (l) => l.navProducts,
  ),
  _Destination(
    AppRoutes.adminCategories,
    Icons.category_outlined,
    (l) => l.navCategories,
  ),
  _Destination(
    AppRoutes.adminSuppliers,
    Icons.local_shipping_outlined,
    (l) => l.navSuppliers,
  ),
  _Destination(
    AppRoutes.adminStock,
    Icons.warehouse_outlined,
    (l) => l.navStock,
  ),
  _Destination(AppRoutes.adminImport, Icons.import_export, (l) => l.navImport),
  _Destination(
    AppRoutes.adminPromotions,
    Icons.sell_outlined,
    (l) => l.navPromotions,
  ),
  _Destination(
    AppRoutes.adminVouchers,
    Icons.confirmation_number_outlined,
    (l) => l.navVouchers,
  ),
  _Destination(
    AppRoutes.adminShifts,
    Icons.lock_clock_outlined,
    (l) => l.navShifts,
  ),
  _Destination(AppRoutes.adminAudit, Icons.policy_outlined, (l) => l.navAudit),
  _Destination(
    AppRoutes.adminCustomers,
    Icons.people_outline,
    (l) => l.navCustomers,
  ),
  _Destination(
    AppRoutes.adminKasbon,
    Icons.request_quote_outlined,
    (l) => l.navKasbon,
  ),
  _Destination(
    AppRoutes.adminLoyalty,
    Icons.stars_outlined,
    (l) => l.navLoyalty,
  ),
  _Destination(
    AppRoutes.adminSettings,
    Icons.settings_outlined,
    (l) => l.navSettings,
  ),
];

/// Back-office frame: navigation rail on wide screens, drawer on phones,
/// one app bar with the page title and sign-out.
class AdminShell extends ConsumerWidget {
  const new({required this.child, super.key});

  final Widget child;

  int _selected(String location) {
    for (var i = _destinations.length - 1; i > 0; i--) {
      if (location.startsWith(_destinations[i].route)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final location = GoRouterState.of(context).matchedLocation;
    final selected = _selected(location);
    final wide = context.isWide;

    void go(int i) {
      context.go(_destinations[i].route);
      if (!wide) Navigator.of(context).maybePop();
    }

    final signOut = TextButton.icon(
      key: const Key('sign-out'),
      onPressed: () => ref.read(sessionControllerProvider.notifier).signOut(),
      icon: const Icon(Icons.logout),
      label: Text(l10n.adminSignOut),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_destinations[selected].label(l10n)),
        actions: [
          signOut,
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      drawer: wide
          ? null
          : NavigationDrawer(
              selectedIndex: selected,
              onDestinationSelected: go,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text(
                    l10n.appTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                for (final d in _destinations)
                  NavigationDrawerDestination(
                    icon: Icon(d.icon),
                    label: Text(d.label(l10n)),
                  ),
              ],
            ),
      body: wide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: selected,
                  onDestinationSelected: go,
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final d in _destinations)
                      NavigationRailDestination(
                        icon: Icon(d.icon),
                        label: Text(d.label(l10n)),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: child),
              ],
            )
          : child,
    );
  }
}
