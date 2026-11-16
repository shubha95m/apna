import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class ApnaTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: ApnaColors.primary,
      scaffoldBackgroundColor: ApnaColors.background,
      colorScheme: const ColorScheme.light(
        primary: ApnaColors.primary,
        secondary: ApnaColors.accent,
        surface: ApnaColors.surface,
        error: ApnaColors.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: ApnaColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        iconTheme: IconThemeData(color: ApnaColors.textPrimary),
        titleTextStyle: ApnaTypography.headingSmall,
      ),
      cardTheme: CardThemeData(
        color: ApnaColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: ApnaColors.border, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: ApnaColors.border,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
