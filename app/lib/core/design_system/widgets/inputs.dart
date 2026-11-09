import 'package:cashiera/core/design_system/tokens.dart';
import 'package:flutter/material.dart';

/// Search field with a barcode hint: typing filters, a scanner's Enter submits.
class SearchScanField extends StatelessWidget {
  const new({
    required this.onChanged,
    this.onSubmitted,
    this.hint,
    this.shortcut,
    this.controller,
    super.key,
  });

  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? hint;

  /// A keyboard hint shown at the end, e.g. `F2`.
  final String? shortcut;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.minTouch,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hint,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (shortcut != null)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: Text(
                    shortcut!,
                    style: const TextStyle(
                      fontFamily: AppFonts.label,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              const Padding(
                padding: EdgeInsets.only(right: AppSpacing.md),
                child: Icon(
                  Icons.qr_code_scanner,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontally scrolling pill chips: category filters and page tabs.
class ChipTabs<T> extends StatelessWidget {
  const new({
    required this.items,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<(T, String)> items;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (value, label) in items)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ChoiceChip(
                key: ValueKey('chip-$value'),
                label: Text(label),
                selected: value == selected,
                showCheckmark: false,
                onSelected: (_) => onSelected(value),
              ),
            ),
        ],
      ),
    );
  }
}

/// A glass track of segments, e.g. Today / Yesterday / This week.
class SegmentedTabs<T> extends StatelessWidget {
  const new({
    required this.items,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<(T, String)> items;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.pill);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.5),
        borderRadius: radius,
        border: Border.all(color: AppColors.white.withValues(alpha: 0.7)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (value, label) in items)
              _Segment(
                label: label,
                selected: value == selected,
                onTap: () => onSelected(value),
              ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const new({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.pill);
    return AnimatedContainer(
      duration: AppMotion.fast,
      decoration: BoxDecoration(
        color: selected ? AppColors.white : null,
        borderRadius: radius,
        boxShadow: selected
            ? [
                BoxShadow(
                  color: AppColors.text.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: AppFonts.label,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.text : AppColors.textMuted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
