import 'package:flutter/material.dart';

import '../tokens/colors.dart';

/// Base ThemeData builder that applies design tokens.
class AppTheme {
  const AppTheme._();

  static ThemeData base(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamily: '.SF Pro Text',
      fontFamilyFallback: [
        '.SF Pro Display',
        'SF Pro Text',
        'SF Pro Display',
        'San Francisco',
        'Helvetica Neue',
        'Helvetica',
        'Arial',
        'sans-serif',
      ],
      scaffoldBackgroundColor:
          isDark ? const Color(0xFF121212) : AppColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: const CardThemeData(
        elevation: 1,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}
