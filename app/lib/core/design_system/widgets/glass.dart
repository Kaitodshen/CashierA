import 'dart:ui' show ImageFilter;

import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/visual_effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How much white a glass surface adds over the background. Stitch uses
/// 9–18 %; text-heavy surfaces (cart, tables, forms) use [solid] so they stay
/// readable under bright store lighting.
enum GlassLevel {
  subtle(0.12),
  regular(0.22),
  solid(0.55);

  new(this.alpha);
  final double alpha;
}

/// Frosted glass: a translucent white gradient (brighter at the top left),
/// a bright edge, a 1 px top highlight and a rose-tinted shadow painted only
/// outside the card. No blur filter: over the soft background it looks the
/// same and costs nothing per frame.
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
    return CustomPaint(
      painter: GlassShadowPainter(radius: radius),
      child: DecoratedBox(
        decoration: glassDecoration(level: level, radius: radius),
        child: ClipRRect(
          borderRadius: shape,
          child: Stack(
            children: [
              content,
              // The 1 px highlight along the top edge (CSS: inset 0 1px 1px).
              Positioned(
                left: radius / 2,
                right: radius / 2,
                top: 0,
                height: 1,
                child: ColoredBox(
                  color: AppColors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The frosted fill and bright edge of glass, for widgets that draw their own
/// box. Carries no shadow: a BoxShadow would show through the glass.
BoxDecoration glassDecoration({
  GlassLevel level = GlassLevel.regular,
  double radius = AppRadius.card,
}) => BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.white.withValues(alpha: (level.alpha * 1.8).clamp(0, 0.85)),
      AppColors.white.withValues(alpha: level.alpha * 0.6),
    ],
  ),
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: AppColors.white.withValues(alpha: 0.55)),
);

/// A soft rose shadow around a rounded rectangle, with the rectangle itself
/// cut out, as a CSS box-shadow behaves. Nothing is drawn under the glass.
class GlassShadowPainter extends CustomPainter {
  const new({required this.radius, this.blur = 28, this.dy = 10});

  final double radius;
  final double blur;
  final double dy;

  /// Stitch's `shadow-rose-950`, faint.
  static const color = Color(0x14881337);

  @override
  void paint(Canvas canvas, Size size) {
    final box = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final outside = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(box.outerRect.inflate(blur * 3))
      ..addRRect(box);
    canvas
      ..save()
      ..clipPath(outside)
      ..drawRRect(
        box.shift(Offset(0, dy)),
        Paint()
          ..color = color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur / 2),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(GlassShadowPainter old) =>
      old.radius != radius || old.blur != blur || old.dy != dy;
}

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
    final pill = CustomPaint(
      painter: const GlassShadowPainter(radius: 20, blur: 14, dy: 4),
      child: DecoratedBox(
        decoration: glassDecoration(radius: 20),
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
