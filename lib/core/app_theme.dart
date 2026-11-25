import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF08111E);
  static const surface = Color(0xFF111D2D);
  static const surfaceRaised = Color(0xFF172538);
  static const accent = Color(0xFF50E3C2);
  static const blue = Color(0xFF64B5F6);
  static const warning = Color(0xFFFFC857);
  static const danger = Color(0xFFFF5D68);
  static const muted = Color(0xFF95A4B8);
}

ThemeData buildAppTheme() {
  const scheme = ColorScheme.dark(
    primary: AppColors.accent,
    secondary: AppColors.blue,
    error: AppColors.danger,
    surface: AppColors.surface,
    onPrimary: AppColors.background,
    onSecondary: AppColors.background,
    onSurface: Color(0xFFF3F7FB),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    cardColor: AppColors.surface,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.accent.withValues(alpha: 0.18),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return TextStyle(
          color: states.contains(WidgetState.selected)
              ? AppColors.accent
              : AppColors.muted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        );
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceRaised,
      hintStyle: const TextStyle(color: AppColors.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0x223C526A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.3),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surfaceRaised,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      titleLarge: TextStyle(fontWeight: FontWeight.w700),
      titleMedium: TextStyle(fontWeight: FontWeight.w700),
      bodyMedium: TextStyle(color: Color(0xFFD5DFEA), height: 1.4),
      bodySmall: TextStyle(color: AppColors.muted),
    ),
  );
}
