import 'package:cashiera/core/design_system/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final theme = AppTheme.light();

  test('palette and fonts follow the Stitch design', () {
    expect(theme.brightness, Brightness.light);
    expect(theme.colorScheme.primary, const Color(0xFFE11D48));
    expect(theme.colorScheme.secondary, const Color(0xFF10B981));
    expect(theme.colorScheme.error, const Color(0xFFEF4444));
    expect(theme.colorScheme.onSurface, const Color(0xFF0F172A));
    expect(theme.textTheme.bodyMedium!.fontFamily, 'PlusJakartaSans');
    expect(theme.textTheme.labelLarge!.fontFamily, 'Inter');
    // The page background is painted by AppBackground, not the scaffold.
    expect(theme.scaffoldBackgroundColor, Colors.transparent);
  });

  test('controls keep 48 dp touch targets and 14 px corners', () {
    final style = theme.filledButtonTheme.style!;
    expect(style.minimumSize!.resolve({}), const Size(48, 48));
    final shape = style.shape!.resolve({})! as RoundedRectangleBorder;
    expect(shape.borderRadius, BorderRadius.circular(14));
  });
}
