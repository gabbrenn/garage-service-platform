import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.navy,
      onPrimary: Colors.white,
      secondary: AppColors.darkOrange,
      onSecondary: Colors.white,
      error: Colors.red.shade700,
      onError: Colors.white,
      background: Colors.white,
      onBackground: AppColors.textPrimary,
      surface: Colors.white,
      onSurface: AppColors.textPrimary,
    );
    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkOrange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.darkOrange),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.darkOrange,
        foregroundColor: Colors.white,
      ),
      useMaterial3: true,
    );
  }

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.navy,
      onPrimary: Colors.white,
      secondary: AppColors.darkOrange,
      onSecondary: Colors.black,
      error: Colors.red.shade400,
      onError: Colors.black,
      background: const Color(0xFF101418),
      onBackground: Colors.white,
      surface: const Color(0xFF1C2228),
      onSurface: Colors.white,
    );
    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkOrange,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.darkOrange),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.darkOrange,
        foregroundColor: Colors.black,
      ),
      cardColor: colorScheme.surface,
      dialogBackgroundColor: colorScheme.surface,
    );
  }
}
