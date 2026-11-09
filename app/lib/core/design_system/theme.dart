import 'package:cashiera/core/design_system/tokens.dart';
import 'package:flutter/material.dart';

/// The one light theme for terminals and back office. The page background is
/// painted by `AppBackground`, so scaffolds are transparent. Widgets read
/// colors from the theme or [AppColors], never literals.
abstract final class AppTheme {
  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.white,
      primaryContainer: AppColors.primarySoft,
      onPrimaryContainer: AppColors.primaryPressed,
      secondary: AppColors.success,
      onSecondary: AppColors.white,
      tertiary: AppColors.warning,
      onTertiary: AppColors.white,
      error: AppColors.error,
      onError: AppColors.white,
      surface: AppColors.white,
      onSurface: AppColors.text,
      onSurfaceVariant: AppColors.textMuted,
      surfaceContainerLowest: AppColors.white,
      surfaceContainerLow: Color(0xFFFFF7F8),
      surfaceContainer: Color(0xFFFFF7F8),
      surfaceContainerHigh: AppColors.primarySoft,
      surfaceContainerHighest: AppColors.primarySoft,
      outline: AppColors.hairline,
      outlineVariant: AppColors.hairline,
    );

    final control = BorderRadius.circular(AppRadius.control);
    final controlShape = RoundedRectangleBorder(borderRadius: control);
    const minSize = Size(AppSizes.minTouch, AppSizes.minTouch);
    const labelStyle = TextStyle(
      fontFamily: AppFonts.label,
      fontWeight: FontWeight.w600,
      fontSize: 14,
    );
    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: control,
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: AppFonts.body,
      textTheme: _textTheme,
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: AppColors.white,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 20,
          height: 28 / 20,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white.withValues(alpha: 0.72),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: AppColors.white.withValues(alpha: 0.6)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: minSize,
          shape: controlShape,
          textStyle: labelStyle,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: minSize,
          shape: controlShape,
          textStyle: labelStyle,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: minSize,
          shape: controlShape,
          backgroundColor: AppColors.white.withValues(alpha: 0.8),
          side: const BorderSide(color: AppColors.hairline),
          foregroundColor: AppColors.textSecondary,
          textStyle: labelStyle,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: minSize,
          shape: controlShape,
          textStyle: labelStyle,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: minSize),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        border: inputBorder(AppColors.hairline),
        enabledBorder: inputBorder(AppColors.hairline),
        focusedBorder: inputBorder(AppColors.primary, 2),
        errorBorder: inputBorder(AppColors.error),
        focusedErrorBorder: inputBorder(AppColors.error, 2),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.hairline, space: 1),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.white.withValues(alpha: 0.8),
        selectedColor: AppColors.primary,
        secondarySelectedColor: AppColors.primary,
        labelStyle: const TextStyle(
          fontFamily: AppFonts.label,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: AppFonts.label,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
        side: const BorderSide(color: AppColors.hairline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white.withValues(alpha: 0.92),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.white.withValues(alpha: 0.92),
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.card),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.text,
        shape: RoundedRectangleBorder(borderRadius: control),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.hairline,
        ),
        thumbColor: const WidgetStatePropertyAll(AppColors.white),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textMuted,
        textColor: AppColors.text,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.white.withValues(alpha: 0.92),
        indicatorColor: AppColors.primarySoft,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(
            fontFamily: AppFonts.label,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.primary,
        dividerColor: AppColors.hairline,
        labelStyle: labelStyle,
      ),
    );
  }

  /// The Stitch type scale (spec §2.4).
  static const _textTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 32,
      height: 40 / 32,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.64,
    ),
    displayMedium: TextStyle(
      fontSize: 28,
      height: 32 / 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.56,
    ),
    displaySmall: TextStyle(
      fontSize: 24,
      height: 32 / 24,
      fontWeight: FontWeight.w700,
    ),
    headlineLarge: TextStyle(
      fontSize: 24,
      height: 32 / 24,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.24,
    ),
    headlineMedium: TextStyle(
      fontSize: 20,
      height: 28 / 20,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
    ),
    headlineSmall: TextStyle(
      fontSize: 18,
      height: 24 / 18,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      height: 28 / 20,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      height: 24 / 16,
      fontWeight: FontWeight.w600,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: TextStyle(fontSize: 16, height: 24 / 16),
    bodyMedium: TextStyle(fontSize: 14, height: 20 / 14),
    bodySmall: TextStyle(fontSize: 12, height: 16 / 12),
    labelLarge: TextStyle(
      fontFamily: AppFonts.label,
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.14,
    ),
    labelMedium: TextStyle(
      fontFamily: AppFonts.label,
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.24,
    ),
    labelSmall: TextStyle(
      fontFamily: AppFonts.label,
      fontSize: 11,
      height: 14 / 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.33,
    ),
  );
}
