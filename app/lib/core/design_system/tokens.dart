import 'package:flutter/widgets.dart';

/// Colors of the Stitch "Radiant Light White Glass" design
/// (docs/superpowers/specs/2026-11-09-stitch-redesign-design.md §2.1).
abstract final class AppColors {
  static const primary = Color(0xFFE11D48);
  static const primaryPressed = Color(0xFFBE123C);
  static const primarySoft = Color(0xFFFFF1F2);

  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const warningSoft = Color(0xFFFEF3C7);
  static const warningText = Color(0xFFD97706);
  static const error = Color(0xFFEF4444);

  /// In-between states (in transit, ordered, cleaning).
  static const info = Color(0xFF0D9488);

  static const text = Color(0xFF0F172A);
  static const textStrong = Color(0xFF020617);
  static const textSecondary = Color(0xFF334155);

  /// Darker than Stitch's #64748B so it reads on 22 % glass (≈ 4.5:1).
  static const textMuted = Color(0xFF475569);
  static const hairline = Color(0xFFE2E8F0);

  static const white = Color(0xFFFFFFFF);
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
  static const card = 24.0;
  static const tile = 20.0;
  static const control = 14.0;
  static const small = 8.0;
  static const pill = 999.0;
}

abstract final class AppMotion {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 250);
}

abstract final class AppFonts {
  /// Headings, body text and big numbers.
  static const body = 'PlusJakartaSans';

  /// Labels, chips, table headers and buttons.
  static const label = 'Inter';
}

abstract final class AppTypography {
  /// Money, quantities and codes line up in columns.
  static const tabular = [FontFeature.tabularFigures()];
}

abstract final class AppSizes {
  /// Minimum touch target (dp).
  static const minTouch = 48.0;

  /// Widths at or above this use the wide layouts (sidebar, split views).
  static const splitBreakpoint = 600.0;
}

extension BreakpointContext on BuildContext {
  bool get isWide => MediaQuery.sizeOf(this).width >= AppSizes.splitBreakpoint;
}
