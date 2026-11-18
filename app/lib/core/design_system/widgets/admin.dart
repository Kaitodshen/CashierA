import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/empty_state.dart';
import 'package:cashiera/core/design_system/widgets/glass.dart';
import 'package:flutter/material.dart';

/// A back-office page inside the shell: the toolbar, then the content, in
/// one scroll view at most [maxWidth] wide. The shell's top bar holds the
/// title, so pages add none.
class AdminPage extends StatelessWidget {
  const new({
    required this.children,
    this.toolbar,
    this.maxWidth = 1200,
    super.key,
  });

  final List<Widget> children;
  final Widget? toolbar;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              if (toolbar case final t?) ...[
                t,
                const SizedBox(height: AppSpacing.lg),
              ],
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

/// Search and filters on the left, the page's actions on the right (under
/// the filters below 720 px). Replaces floating action buttons.
class AdminToolbar extends StatelessWidget {
  const new({this.filters = const [], this.actions = const [], super.key});

  final List<Widget> filters;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    if (filters.isEmpty && actions.isEmpty) return const SizedBox.shrink();
    Widget wrap(List<Widget> items, {WrapAlignment? alignment}) => Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      alignment: alignment ?? WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: items,
    );
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: LayoutBuilder(
        builder: (context, c) {
          if (filters.isEmpty) {
            return Align(
              alignment: Alignment.centerRight,
              child: wrap(actions, alignment: WrapAlignment.end),
            );
          }
          if (actions.isEmpty) return wrap(filters);
          if (c.maxWidth < 720) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                wrap(filters),
                const SizedBox(height: AppSpacing.md),
                wrap(actions),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: wrap(filters)),
              const SizedBox(width: AppSpacing.md),
              wrap(actions, alignment: WrapAlignment.end),
            ],
          );
        },
      ),
    );
  }
}

/// A field of a [FormSection] that always takes the whole row (tables,
/// long text, lists of switches).
class FormFullWidth extends StatelessWidget {
  const new(this.child, {super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

/// A titled glass card of form fields: two per row when the card is at
/// least 720 px wide, one per row below.
class FormSection extends StatelessWidget {
  const new({
    required this.title,
    required this.children,
    this.subtitle,
    super.key,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      level: GlassLevel.solid,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          if (subtitle case final s?) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              s,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, c) {
              final two = c.maxWidth >= 720;
              final half = (c.maxWidth - AppSpacing.lg) / 2;
              return Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.md,
                children: [
                  for (final child in children)
                    SizedBox(
                      width: two && child is! FormFullWidth ? half : c.maxWidth,
                      child: child,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// An empty, loading-failed or not-allowed message on a glass card.
Widget adminMessage({
  required IconData icon,
  required String message,
  Widget? action,
}) => GlassCard(
  child: EmptyState(icon: icon, message: message, action: action),
);
