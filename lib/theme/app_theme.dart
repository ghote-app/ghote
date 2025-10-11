import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'dart:io';

class AppColors {
  AppColors._();
  static const Color primary = Color(0xFF2A2A2A);
  static const Color secondary = Color(0xFFF8F9FA);
  static const Color bgLight = Color(0xFFFFFFFF);
  static const Color bgDark = Color(0xFF0B0B0C);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6C757D);
}

ThemeData _base(ThemeData src, {required bool dark}) {
  final textTheme = GoogleFonts.interTextTheme(src.textTheme);
  // final bool isAndroid = Platform.isAndroid;
  
  return src.copyWith(
    textTheme: textTheme.copyWith(
      // Unified text sizes/spacing across platforms; avoid layout divergence
      bodyLarge: textTheme.bodyLarge?.copyWith(fontSize: 17, letterSpacing: 0.1),
      bodyMedium: textTheme.bodyMedium?.copyWith(fontSize: 15, letterSpacing: 0.15),
      bodySmall: textTheme.bodySmall?.copyWith(fontSize: 13, letterSpacing: 0.2),
    ),
    cardTheme: src.cardTheme.copyWith(
      color: src.colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      shadowColor: Colors.black.withValues(alpha: dark ? 0.3 : 0.1),
    ),
    appBarTheme: src.appBarTheme.copyWith(
      elevation: 0,
      backgroundColor: dark ? Colors.transparent : Colors.white,
      foregroundColor: dark ? Colors.white : AppColors.textPrimary,
      titleTextStyle: textTheme.titleLarge?.copyWith(fontSize: 21, fontWeight: FontWeight.w600),
    ),
    scaffoldBackgroundColor: dark ? AppColors.bgDark : AppColors.bgLight,
    // Unified input decoration (responsive paddings handled in widgets)
    inputDecorationTheme: InputDecorationTheme(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: dark ? Colors.white.withValues(alpha: 0.5) : AppColors.primary, width: 2),
      ),
    ),
  );
}

ThemeData buildLightTheme() {
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
  ).copyWith(
    surface: AppColors.bgLight,
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    onPrimary: Colors.white,
  );
  return _base(ThemeData(colorScheme: scheme), dark: false);
}

ThemeData buildDarkTheme() {
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.dark,
  ).copyWith(
    surface: const Color(0xFF111316),
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    onPrimary: Colors.white,
  );
  return _base(ThemeData(colorScheme: scheme), dark: true);
}
