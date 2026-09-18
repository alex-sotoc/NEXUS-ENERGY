import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color background =
      Color(0xFF080B12);

  static const Color surface =
      Color(0xFF111620);

  static const Color surfaceLight =
      Color(0xFF171D29);

  static const Color emerald =
      Color(0xFF10B981);

  static const Color blue =
      Color(0xFF60A5FA);

  static const Color turquoise =
      Color(0xFF14B8A6);

  static const Color textPrimary =
      Color(0xFFF8FAFC);

  static const Color textSecondary =
      Color(0xFF94A3B8);

  static const Color border =
      Color(0xFF202938);

  static ThemeData theme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: emerald,
      secondary: turquoise,
      surface: surface,
    ),
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(
          color: border,
          width: 1,
        ),
      ),
    ),
    navigationBarTheme:
        const NavigationBarThemeData(
      backgroundColor: surface,
      indicatorColor: Color(0xFF17372E),
      elevation: 0,
      height: 72,
      labelTextStyle:
          WidgetStatePropertyAll(
        TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}