import 'package:flutter/widgets.dart';

/// The blush page background: a soft gradient with five colour glows at the
/// Stitch positions. Painted once (RepaintBoundary, no blur filter), so
/// scrolling content on top never repaints it.
class AppBackground extends StatelessWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const RepaintBoundary(
          child: CustomPaint(painter: _BackgroundPainter()),
        ),
        child,
      ],
    );
  }
}

class _Glow {
  const new(this.center, this.radius, this.colors, this.opacity);

  /// Centre as a fraction of the canvas.
  final Offset center;

  /// Radius as a fraction of the canvas's shortest side.
  final double radius;
  final List<Color> colors;
  final double opacity;
}

class _BackgroundPainter extends CustomPainter {
  const new();

  static const _glows = [
    _Glow(Offset(0.12, 0.08), 0.75, [
      Color(0xFFFBCFE8),
      Color(0xFFF472B6),
    ], 0.45),
    _Glow(Offset(0.95, 0.3), 0.8, [Color(0xFFFDA4AF), Color(0xFFE0E7FF)], 0.45),
    _Glow(Offset(0.45, 1), 0.85, [Color(0xFFDDD6FE), Color(0xFFFED7AA)], 0.40),
    _Glow(Offset(0.5, 0.6), 0.6, [Color(0xFFFECDD3), Color(0xFFFEE2E2)], 0.35),
    _Glow(Offset(0.8, 0.95), 0.65, [
      Color(0xFFFDA4AF),
      Color(0xFFC4B5FD),
    ], 0.35),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF1F2), Color(0xFFFDF2F8), Color(0xFFF5F3FF)],
        ).createShader(rect),
    );
    final side = size.shortestSide;
    for (final glow in _glows) {
      final center = Offset(
        glow.center.dx * size.width,
        glow.center.dy * size.height,
      );
      final radius = glow.radius * side;
      final circle = Rect.fromCircle(center: center, radius: radius);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              glow.colors[0].withValues(
                alpha: (glow.opacity * 1.5).clamp(0, 1),
              ),
              glow.colors[1].withValues(alpha: glow.opacity),
              glow.colors[1].withValues(alpha: 0),
            ],
            stops: const [0, 0.5, 1],
          ).createShader(circle),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
