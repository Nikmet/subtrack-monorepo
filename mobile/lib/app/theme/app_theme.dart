import 'package:flutter/material.dart';

import '../ui_kit/tokens.dart';

class AppTheme {
  static ThemeData build() {
    const colorScheme = ColorScheme.light(
      primary: UiTokens.primary,
      secondary: Color(0xFF0F5F96),
      surface: UiTokens.card,
      onPrimary: Colors.white,
      onSurface: UiTokens.foreground,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: UiTokens.background,
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        bodyMedium: TextStyle(
          color: UiTokens.foreground,
          fontSize: 15,
          height: 1.4,
          fontWeight: FontWeight.w400,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: UiTokens.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: UiTokens.foreground,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: UiTokens.foreground,
        ),
      ),
      cardTheme: const CardThemeData(
        color: UiTokens.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: UiTokens.radius14,
          side: BorderSide(color: UiTokens.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: UiTokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: UiTokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: UiTokens.primary),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
