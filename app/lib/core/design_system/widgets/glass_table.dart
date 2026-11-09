import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/glass.dart';
import 'package:flutter/material.dart';

/// One column of a [GlassTable].
class GlassColumn<T> {
  const new({
    required this.label,
    required this.cell,
    this.flex = 1,
    this.numeric = false,
  });

  final String label;
  final Widget Function(T row) cell;
  final int flex;

  /// Right-aligned (money, quantities).
  final bool numeric;
}

/// The Stitch table: uppercase headers, 64 dp rows, hairline rules. Below
/// 600 px each row becomes a card listing `label: value`.
class GlassTable<T> extends StatelessWidget {
  const new({
    required this.columns,
    required this.rows,
    this.onRowTap,
    super.key,
  });

  final List<GlassColumn<T>> columns;
  final List<T> rows;
  final void Function(T row)? onRowTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) => c.maxWidth < AppSizes.splitBreakpoint
          ? _cards(context)
          : _table(context),
    );
  }

  Widget _table(BuildContext context) {
    final header = Theme.of(context).textTheme.labelMedium
        ?.copyWith(color: AppColors.textMuted, letterSpacing: 1.2);
    Widget cellBox(GlassColumn<T> col, Widget child) => Expanded(
      flex: col.flex,
      child: Align(
        alignment: col.numeric ? Alignment.centerRight : Alignment.centerLeft,
        child: child,
      ),
    );
    return GlassCard(
      level: GlassLevel.solid,
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.lg,
            ),
            child: Row(
              children: [
                for (final col in columns)
                  cellBox(col, Text(col.label.toUpperCase(), style: header)),
              ],
            ),
          ),
          for (final row in rows) ...[
            const Divider(height: 1),
            InkWell(
              onTap: onRowTap == null ? null : () => onRowTap!(row),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 64),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      for (final col in columns) cellBox(col, col.cell(row)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _cards(BuildContext context) {
    final label = Theme.of(context).textTheme.labelSmall
        ?.copyWith(color: AppColors.textMuted);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: GlassCard(
              level: GlassLevel.solid,
              padding: const EdgeInsets.all(AppSpacing.lg),
              onTap: onRowTap == null ? null : () => onRowTap!(row),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, col) in columns.indexed)
                    if (i == 0)
                      col.cell(row)
                    else
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Row(
                          children: [
                            Text(col.label, style: label),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: col.cell(row),
                              ),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
