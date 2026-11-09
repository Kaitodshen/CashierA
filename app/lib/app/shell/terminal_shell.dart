import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/app/shell/sidebar.dart';
import 'package:cashiera/app/shell/terminal_nav.dart';
import 'package:cashiera/app/shell/terminal_search.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/glass.dart';
import 'package:cashiera/core/design_system/widgets/inputs.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/core/providers.dart';
import 'package:cashiera/core/session/session_controller.dart';
import 'package:cashiera/features/pos_home/presentation/widgets/terminal_status_chip.dart';
import 'package:cashiera/features/sell/presentation/sell_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

IconData _icon(TerminalSection s) => switch (s) {
  TerminalSection.register => Icons.shopping_bag_outlined,
  TerminalSection.overview => Icons.space_dashboard_outlined,
  TerminalSection.catalog => Icons.inventory_2_outlined,
  TerminalSection.members => Icons.loyalty_outlined,
  TerminalSection.settings => Icons.settings_outlined,
};

String _label(AppLocalizations l10n, TerminalSection s, {bool short = false}) =>
    switch (s) {
      TerminalSection.register =>
        short ? l10n.navRegisterShort : l10n.navRegister,
      TerminalSection.overview => l10n.sectionOverview,
      TerminalSection.catalog => l10n.sectionCatalog,
      TerminalSection.members => l10n.sectionMembers,
      TerminalSection.settings => l10n.sectionSettings,
    };

/// The frame of every terminal screen after PIN login: the five-item
/// sidebar (bottom bar on phones) and the top bar with Tables, Held Orders,
/// Kitchen, Lock and the sync status.
class TerminalShell extends StatefulWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  State<TerminalShell> createState() => _TerminalShellState();
}

class _TerminalShellState extends State<TerminalShell> {
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final section = terminalSectionFor(location);
    final wide = context.isWide;

    if (!wide) {
      return Scaffold(
        body: Column(
          children: [
            _TopBar(location: location, compact: true),
            Expanded(child: _withoutTopPadding(context, widget.child)),
          ],
        ),
        bottomNavigationBar: _BottomBar(section: section),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          _TerminalSidebar(
            section: section,
            collapsed: _collapsed,
            onToggle: () => setState(() => _collapsed = !_collapsed),
          ),
          Expanded(
            child: Column(
              children: [
                _TopBar(location: location, compact: false),
                Expanded(
                  child: _withoutTopPadding(context, widget.child, left: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The top bar already pads for the status bar (and the sidebar for the
/// left inset); screens inside must not add it again.
Widget _withoutTopPadding(
  BuildContext context,
  Widget child, {
  bool left = false,
}) => MediaQuery.removePadding(
  context: context,
  removeTop: true,
  removeLeft: left,
  child: child,
);

class _TerminalSidebar extends ConsumerWidget {
  const new({
    required this.section,
    required this.collapsed,
    required this.onToggle,
  });

  final TerminalSection? section;
  final bool collapsed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final session = ref.watch(sessionControllerProvider).value;
    final config = ref.watch(posConfigProvider).value;
    final online = ref.watch(onlineProvider).value ?? false;
    final device = session?.device;

    return AppSidebar(
      collapsed: collapsed,
      toggle: IconButton(
        key: const Key('terminal-sidebar-toggle'),
        tooltip: collapsed ? l10n.shellExpand : l10n.shellCollapse,
        onPressed: onToggle,
        icon: Icon(
          collapsed
              ? Icons.keyboard_double_arrow_right
              : Icons.view_sidebar_outlined,
          color: AppColors.textSecondary,
        ),
      ),
      items: [
        for (final s in TerminalSection.values)
          SidebarItem(
            key: Key('terminal-nav-${s.name}'),
            icon: _icon(s),
            label: _label(l10n, s),
            selected: s == section,
            collapsed: collapsed,
            onTap: () => context.go(s.route),
          ),
      ],
      footer: SidebarFooterCard(
        online: online,
        title: [
          if (device != null) l10n.posTerminal(device.deviceCode),
          if (session?.staff != null) session!.staff!.fullName,
        ].join(' · '),
        subtitle: [
          config?.storeName ?? session?.store?.store.name ?? '',
          if (online) l10n.statusOnline else l10n.statusOffline,
        ].where((s) => s.isNotEmpty).join(' · '),
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const new({required this.location, required this.compact});

  final String location;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final session = ref.watch(sessionControllerProvider).value;
    final config = ref.watch(posConfigProvider).value;
    final held = ref.watch(heldOrdersProvider).value?.length ?? 0;
    final staff = session?.staff;
    final fnb = config?.fnbMode ?? false;
    final kitchen = fnb && (staff?.can('kitchen.view') ?? false);
    final storeName = config?.storeName ?? session?.store?.store.name;
    final badge = heldBadge(held);

    void lock() => ref.read(sessionControllerProvider.notifier).lock();

    final heldPill = GlassPill(
      key: const Key('terminal-held-orders'),
      onTap: () => context.go(AppRoutes.orders),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.pause_circle_outline, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(l10n.shellHeldOrders),
          if (badge.isNotEmpty) ...[
            const SizedBox(width: AppSpacing.sm),
            _CountBadge(badge),
          ],
        ],
      ),
    );
    final kitchenPill = GlassPill(
      key: const Key('terminal-kitchen'),
      onTap: () => context.go(AppRoutes.kitchen),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.soup_kitchen_outlined),
          const SizedBox(width: AppSpacing.sm),
          Text(l10n.shellKitchen),
        ],
      ),
    );
    final tablesPill = GlassPill(
      key: const Key('terminal-tables'),
      onTap: () => context.go(AppRoutes.tables),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.table_restaurant_outlined),
          const SizedBox(width: AppSpacing.sm),
          Text(l10n.navTables),
        ],
      ),
    );
    final lockPill = GlassPill(
      key: const Key('terminal-lock'),
      onTap: lock,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline),
          const SizedBox(width: AppSpacing.sm),
          Text(l10n.shellLock),
        ],
      ),
    );

    // One search-and-scan field for Register and Catalog; keyed per screen
    // so each starts empty.
    final searchKey = !showsSearch(location)
        ? null
        : location == AppRoutes.sell
        ? 'sell-search'
        : 'catalog-search';

    return GlassBlur(
      borderRadius: BorderRadius.zero,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.18),
          border: Border(
            bottom: BorderSide(color: AppColors.white.withValues(alpha: 0.7)),
          ),
        ),
        child: SafeArea(
          bottom: false,
          left: compact,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: LayoutBuilder(
              builder: (context, c) {
                // Under 900 px the pills fold into one menu.
                final roomy = c.maxWidth >= 900;
                return Row(
                  children: [
                    if (!(compact && searchKey != null))
                      Expanded(
                        child: Text(
                          [
                            l10n.shellRetailPos.toUpperCase(),
                            ?storeName,
                          ].join(' • '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: AppFonts.label,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            letterSpacing: 0.6,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                    if (searchKey != null) ...[
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 440),
                            child: _TopSearchField(
                              key: ValueKey('top-$searchKey'),
                              fieldKey: Key(searchKey),
                              autofocus: location == AppRoutes.sell,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: AppSpacing.md),
                    if (roomy) ...[
                      if (fnb) ...[
                        tablesPill,
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      heldPill,
                      if (kitchen) ...[
                        const SizedBox(width: AppSpacing.sm),
                        kitchenPill,
                      ],
                      const SizedBox(width: AppSpacing.sm),
                      lockPill,
                      const SizedBox(width: AppSpacing.sm),
                    ] else
                      _OverflowMenu(
                        heldLabel: [
                          l10n.shellHeldOrders,
                          if (badge.isNotEmpty) '($badge)',
                        ].join(' '),
                        tables: fnb,
                        kitchen: kitchen,
                        onLock: lock,
                      ),
                    // Always shown: it also keeps the outbox draining.
                    const Flexible(child: TerminalStatusChip()),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: AppFonts.label,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          color: AppColors.white,
        ),
      ),
    );
  }
}

class _OverflowMenu extends StatelessWidget {
  const new({
    required this.heldLabel,
    required this.tables,
    required this.kitchen,
    required this.onLock,
  });

  final String heldLabel;
  final bool tables;
  final bool kitchen;
  final VoidCallback onLock;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopupMenuButton<String>(
      key: const Key('terminal-more'),
      tooltip: l10n.shellMore,
      icon: const Icon(Icons.more_vert, color: AppColors.text),
      onSelected: (v) => switch (v) {
        'held' => context.go(AppRoutes.orders),
        'tables' => context.go(AppRoutes.tables),
        'kitchen' => context.go(AppRoutes.kitchen),
        'sync' => context.go(AppRoutes.sync),
        _ => onLock(),
      },
      itemBuilder: (_) => [
        if (tables)
          PopupMenuItem(
            key: const Key('terminal-tables'),
            value: 'tables',
            child: Text(l10n.navTables),
          ),
        PopupMenuItem(
          key: const Key('terminal-held-orders'),
          value: 'held',
          child: Text(heldLabel),
        ),
        if (kitchen)
          PopupMenuItem(
            key: const Key('terminal-kitchen'),
            value: 'kitchen',
            child: Text(l10n.shellKitchen),
          ),
        PopupMenuItem(value: 'sync', child: Text(l10n.posOpenSync)),
        PopupMenuItem(
          key: const Key('terminal-lock'),
          value: 'lock',
          child: Text(l10n.shellLock),
        ),
      ],
    );
  }
}

class _BottomBar extends ConsumerWidget {
  const new({required this.section});

  final TerminalSection? section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return NavigationBar(
      key: const Key('terminal-bottom-bar'),
      selectedIndex: section?.index ?? 0,
      onDestinationSelected: (i) => context.go(TerminalSection.values[i].route),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: [
        for (final s in TerminalSection.values)
          NavigationDestination(
            key: Key('terminal-nav-${s.name}'),
            icon: Icon(_icon(s)),
            label: _label(l10n, s, short: true),
          ),
      ],
    );
  }
}

/// The top-bar field. Typing updates [terminalSearchProvider]; Enter (a
/// scanner) submits and keeps focus for the next scan. Clears itself when
/// the screen clears the query, and starts empty on every screen.
class _TopSearchField extends ConsumerStatefulWidget {
  const new({required this.fieldKey, required this.autofocus, super.key});

  final Key fieldKey;
  final bool autofocus;

  @override
  ConsumerState<_TopSearchField> createState() => _TopSearchFieldState();
}

class _TopSearchFieldState extends ConsumerState<_TopSearchField> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    // A new screen never inherits the previous screen's query.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(terminalSearchProvider.notifier).clear();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(terminalSearchProvider, (_, next) {
      if (next.query.isEmpty && _controller.text.isNotEmpty) {
        _controller.clear();
      }
    });
    final notifier = ref.read(terminalSearchProvider.notifier);
    return SearchScanField(
      key: widget.fieldKey,
      controller: _controller,
      focusNode: _focus,
      autofocus: widget.autofocus,
      hint: context.l10n.shellSearchHint,
      onChanged: notifier.type,
      onSubmitted: (text) {
        notifier.submit(text);
        _focus.requestFocus();
      },
    );
  }
}
