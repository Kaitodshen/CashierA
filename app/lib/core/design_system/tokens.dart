import 'package:flutter/widgets.dart';

/// Colors from the CashierA design spec (docs/phase-0-architecture.md §4.10).
abstract final class AppColors {
  // POS (dark)
  static const posBackground = Color(0xFF0F172A);
  static const posSurface = Color(0xFF1E293B);
  static const posSurfaceRaised = Color(0xFF273449);
  static const posBorder = Color(0xFF334155);
  static const posText = Color(0xFFF8FAFC);
  static const posTextMuted = Color(0xFF94A3B8);

  // Back office (light)
  static const adminBackground = Color(0xFFF8FAFC);
  static const adminSurface = Color(0xFFFFFFFF);
  static const adminBorder = Color(0xFFE2E8F0);
  static const adminText = Color(0xFF1E293B);
  static const adminTextMuted = Color(0xFF64748B);

  // Brand and status (both themes)
  static const primary = Color(0xFF6366F1);
  static const secondary = Color(0xFF14B8A6);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

abstract final class AppRadius {
  static const card = 16.0;
  static const control = 12.0;
  static const pill = 999.0;
}

abstract final class AppMotion {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 250);
}

abstract final class AppSizes {
  /// Minimum touch target (dp).
  static const minTouch = 48.0;

  /// Widths at or above this use the split layout (65% / 35%).
  static const splitBreakpoint = 600.0;

  static const fontFamily = 'PlusJakartaSans';
}

extension BreakpointContext on BuildContext {
  bool get isWide => MediaQuery.sizeOf(this).width >= AppSizes.splitBreakpoint;
}
