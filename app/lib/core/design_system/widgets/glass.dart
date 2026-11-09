import 'dart:ui' show ImageFilter;

import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/visual_effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How opaque a glass surface is. Text-heavy surfaces use [solid].
enum GlassLevel {
  subtle(0.45),
  regular(0.72),
  solid(0.92);

  new(this.alpha);
  final double alpha;
}

/// A translucent white card with a bright edge, a top highlight and a soft
/// shadow. No blur: over the soft background it looks the same and costs
/// nothing per frame.
class GlassCard extends StatelessWidget {
  const new({
    required this.child,
    this.level = GlassLevel.regular,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.radius = AppRadius.card,
    this.onTap,
    super.key,
  });

  final Widget child;
  final GlassLevel level;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    Widget content = Padding(padding: padding, child: child);
    if (onTap != null) {
      content = Material(
        type: MaterialType.transparency,
        child: InkWell(borderRadius: shape, onTap: onTap, child: content),
      );
    }
    return DecoratedBox(
      decoration: glassDecoration(level: level, radius: radius),
      child: ClipRRect(
        borderRadius: shape,
        child: Stack(
          children: [
            content,
            // The 1 px highlight along the top edge.
            Positioned(
              left: radius / 2,
              right: radius / 2,
              top: 0,
              height: 1,
              child: ColoredBox(color: AppColors.white.withValues(alpha: 0.9)),
            ),
          ],
        ),
      ),
    );
  }
}

/// The glass look as a decoration, for widgets that draw their own box.
BoxDecoration glassDecoration({
  GlassLevel level = GlassLevel.regular,
  double radius = AppRadius.card,
}) => BoxDecoration(
  color: AppColors.white.withValues(alpha: level.alpha),
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: AppColors.white.withValues(alpha: 0.6)),
  boxShadow: [
    BoxShadow(
      color: AppColors.text.withValues(alpha: 0.08),
      blurRadius: 30,
      offset: const Offset(0, 10),
    ),
  ],
);

/// A small glass pill for status and quick actions (Held Orders, Lock, …).
class GlassPill extends StatelessWidget {
  const new({required this.child, this.tint, this.onTap, super.key});

  final Widget child;

  /// Text and icon colour; defaults to the body text colour.
  final Color? tint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(AppRadius.pill);
    final color = tint ?? AppColors.text;
    final pill = DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.8),
        borderRadius: shape,
        border: Border.all(color: AppColors.white.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: AppColors.text.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SizedBox(
        height: 40,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: IconTheme.merge(
            data: IconThemeData(color: color, size: 18),
            child: DefaultTextStyle.merge(
              style: TextStyle(
                fontFamily: AppFonts.label,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: color,
              ),
              child: Center(widthFactor: 1, child: child),
            ),
          ),
        ),
      ),
    );
    if (onTap == null) return pill;
    // 40 dp pill inside a 48 dp hit area.
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: shape,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTouch),
          child: Center(widthFactor: 1, child: pill),
        ),
      ),
    );
  }
}

/// Real blur behind [child] while visual effects are on; otherwise [child]
/// unchanged. Used only for the top bar, dialogs and sheets.
class GlassBlur extends ConsumerWidget {
  const new({required this.child, required this.borderRadius, super.key});

  final Widget child;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(visualEffectsProvider).value ?? true;
    if (!on) return child;
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: child,
      ),
    );
  }
}

/// A dialog on frosted glass.
class GlassDialog extends StatelessWidget {
  const new({
    required this.title,
    required this.content,
    this.actions = const [],
    super.key,
  });

  final Widget title;
  final Widget content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.card);
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: GlassBlur(
        borderRadius: radius,
        child: DecoratedBox(
          decoration: glassDecoration(level: GlassLevel.solid),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DefaultTextStyle.merge(
                  style: Theme.of(context).textTheme.headlineMedium,
                  child: title,
                ),
                const SizedBox(height: AppSpacing.lg),
                Flexible(child: content),
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: actions,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A bottom sheet on frosted glass.
Future<T?> showGlassSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  const radius = BorderRadius.vertical(top: Radius.circular(AppRadius.card));
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    builder: (context) => GlassBlur(
      borderRadius: radius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: GlassLevel.solid.alpha),
          borderRadius: radius,
          border: Border.all(color: AppColors.white.withValues(alpha: 0.6)),
        ),
        child: SafeArea(top: false, child: builder(context)),
      ),
    ),
  );
}
