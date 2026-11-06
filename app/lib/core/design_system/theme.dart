import 'package:cashiera/core/design_system/tokens.dart';
import 'package:flutter/material.dart';

/// Central ThemeData. POS terminals use [pos] (dark); the back office uses
/// [backOffice] (light). Widgets read colors from the theme, never literals.
abstract final class AppTheme {
  static ThemeData pos() => _build(
    brightness: Brightness.dark,
    background: AppColors.posBackground,
    surface: AppColors.posSurface,
    surfaceRaised: AppColors.posSurfaceRaised,
    border: AppColors.posBorder,
    text: AppColors.posText,
    muted: AppColors.posTextMuted,
  );

  static ThemeData backOffice() => _build(
    brightness: Brightness.light,
    background: AppColors.adminBackground,
    surface: AppColors.adminSurface,
    surfaceRaised: AppColors.adminBackground,
    border: AppColors.adminBorder,
    text: AppColors.adminText,
    muted: AppColors.adminTextMuted,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color surfaceRaised,
    required Color border,
    required Color text,
    required Color muted,
  }) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: surface,
      onSurface: text,
      onSurfaceVariant: muted,
      surfaceContainerHighest: surfaceRaised,
      outline: border,
      outlineVariant: border,
    );
    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.control),
    );
    const minSize = Size(AppSizes.minTouch, AppSizes.minTouch);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: AppSizes.fontFamily,
      scaffoldBackgroundColor: background,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 1,
        shape: Border(bottom: BorderSide(color: border)),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: minSize,
          shape: controlShape,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: minSize,
          shape: controlShape,
          side: BorderSide(color: border),
          foregroundColor: text,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: minSize, shape: controlShape),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: minSize),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceRaised,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      dividerTheme: DividerThemeData(color: border, space: 1),
      chipTheme: ChipThemeData(
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
    );
  }
}
