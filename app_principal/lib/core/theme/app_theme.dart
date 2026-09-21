import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // ============================================================
  // PALETA PRINCIPAL
  // ============================================================

  static const Color primaryTurquoise =
      Color(0xFF00A896);

  static const Color primaryTurquoiseDark =
      Color(0xFF00897B);

  static const Color primaryTurquoiseLight =
      Color(0xFFE6F7F5);

  static const Color secondaryDark =
      Color(0xFF1E293B);

  static const Color backgroundLight =
      Color(0xFFF8F9FA);

  static const Color surfaceWhite =
      Color(0xFFFFFFFF);

  static const Color cardInactive =
      Color(0xFFE2E8F0);

  static const Color accentPurple =
      Color(0xFF6366F1);

  static const Color textMuted =
      Color(0xFF64748B);

  static const Color textLight =
      Color(0xFF94A3B8);

  static const Color borderLight =
      Color(0xFFE8EDF2);

  static const Color success =
      Color(0xFF10B981);

  static const Color warning =
      Color(0xFFF59E0B);

  static const Color danger =
      Color(0xFFEF4444);

  static const Color disabled =
      Color(0xFFCBD5E1);

  // ============================================================
  // GRADIENTES
  // ============================================================

  static const LinearGradient primaryGradient =
      LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0xFF00A896),
      Color(0xFF00B4D8),
    ],
  );

  static const LinearGradient softPrimaryGradient =
      LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0xFFE6F7F5),
      Color(0xFFE8F8FC),
    ],
  );

  // ============================================================
  // SOMBRAS
  // ============================================================

  static List<BoxShadow> get softShadow {
    return <BoxShadow>[
      BoxShadow(
        color: Colors.black.withValues(
          alpha: 0.04,
        ),
        blurRadius: 15,
        offset: const Offset(
          0,
          5,
        ),
      ),
    ];
  }

  static List<BoxShadow> get mediumShadow {
    return <BoxShadow>[
      BoxShadow(
        color: Colors.black.withValues(
          alpha: 0.07,
        ),
        blurRadius: 22,
        offset: const Offset(
          0,
          8,
        ),
      ),
    ];
  }

  static List<BoxShadow> get turquoiseShadow {
    return <BoxShadow>[
      BoxShadow(
        color: primaryTurquoise.withValues(
          alpha: 0.18,
        ),
        blurRadius: 18,
        offset: const Offset(
          0,
          7,
        ),
      ),
    ];
  }

  // ============================================================
  // BORDES
  // ============================================================

  static const double cardRadius = 20.0;

  static const double buttonRadius = 16.0;

  static const double inputRadius = 16.0;

  static BorderRadius get cardBorderRadius {
    return BorderRadius.circular(
      cardRadius,
    );
  }

  static BorderRadius get buttonBorderRadius {
    return BorderRadius.circular(
      buttonRadius,
    );
  }

  // ============================================================
  // THEME DATA
  // ============================================================

  static ThemeData get theme {
    final ColorScheme colorScheme =
        ColorScheme.fromSeed(
      seedColor: primaryTurquoise,
      brightness: Brightness.light,
      primary: primaryTurquoise,
      secondary: accentPurple,
      surface: surfaceWhite,
      error: danger,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      colorScheme: colorScheme,

      scaffoldBackgroundColor:
          backgroundLight,

      fontFamily: 'Roboto',

      splashFactory:
          InkRipple.splashFactory,

      // ========================================================
      // APP BAR
      // ========================================================

      appBarTheme: const AppBarTheme(
        backgroundColor:
            backgroundLight,
        foregroundColor:
            secondaryDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor:
            Colors.transparent,
        titleTextStyle: TextStyle(
          color: secondaryDark,
          fontSize: 22,
          fontWeight:
              FontWeight.w800,
        ),
      ),

      // ========================================================
      // CARDS
      // ========================================================

      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor:
            Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            cardRadius,
          ),
          side: const BorderSide(
            color: borderLight,
            width: 1,
          ),
        ),
      ),

      // ========================================================
      // INPUTS
      // ========================================================

      inputDecorationTheme:
          InputDecorationTheme(
        filled: true,
        fillColor: surfaceWhite,

        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),

        hintStyle: const TextStyle(
          color: textLight,
          fontSize: 14,
        ),

        labelStyle: const TextStyle(
          color: textMuted,
          fontSize: 14,
          fontWeight:
              FontWeight.w500,
        ),

        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            inputRadius,
          ),
          borderSide:
              const BorderSide(
            color: borderLight,
          ),
        ),

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            inputRadius,
          ),
          borderSide:
              const BorderSide(
            color: borderLight,
          ),
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            inputRadius,
          ),
          borderSide:
              const BorderSide(
            color:
                primaryTurquoise,
            width: 1.6,
          ),
        ),

        errorBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            inputRadius,
          ),
          borderSide:
              const BorderSide(
            color: danger,
          ),
        ),

        focusedErrorBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            inputRadius,
          ),
          borderSide:
              const BorderSide(
            color: danger,
            width: 1.6,
          ),
        ),
      ),

      // ========================================================
      // FILLED BUTTON
      // ========================================================

      filledButtonTheme:
          FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor:
              primaryTurquoise,
          foregroundColor:
              Colors.white,

          minimumSize:
              const Size(
            double.infinity,
            54,
          ),

          padding:
              const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 15,
          ),

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              buttonRadius,
            ),
          ),

          textStyle:
              const TextStyle(
            fontSize: 15,
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ),

      // ========================================================
      // OUTLINED BUTTON
      // ========================================================

      outlinedButtonTheme:
          OutlinedButtonThemeData(
        style:
            OutlinedButton.styleFrom(
          foregroundColor:
              secondaryDark,

          minimumSize:
              const Size(
            double.infinity,
            54,
          ),

          side: const BorderSide(
            color: borderLight,
          ),

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              buttonRadius,
            ),
          ),

          textStyle:
              const TextStyle(
            fontSize: 15,
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ),

      // ========================================================
      // TEXT BUTTON
      // ========================================================

      textButtonTheme:
          TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor:
              primaryTurquoise,
          textStyle:
              const TextStyle(
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ),

      // ========================================================
      // SWITCH
      // ========================================================

      switchTheme:
          SwitchThemeData(
        trackColor:
            WidgetStateProperty.resolveWith<Color?>(
          (
            Set<WidgetState> states,
          ) {
            if (states.contains(
              WidgetState.selected,
            )) {
              return primaryTurquoise
                  .withValues(
                alpha: 0.35,
              );
            }

            return cardInactive;
          },
        ),

        thumbColor:
            WidgetStateProperty.resolveWith<Color?>(
          (
            Set<WidgetState> states,
          ) {
            if (states.contains(
              WidgetState.selected,
            )) {
              return primaryTurquoise;
            }

            return textMuted;
          },
        ),
      ),

      // ========================================================
      // NAVIGATION BAR
      // ========================================================

      navigationBarTheme:
          NavigationBarThemeData(
        height: 72,

        backgroundColor:
            surfaceWhite,

        surfaceTintColor:
            Colors.transparent,

        elevation: 0,

        indicatorColor:
            primaryTurquoiseLight,

        iconTheme:
            WidgetStateProperty.resolveWith<
                IconThemeData>(
          (
            Set<WidgetState> states,
          ) {
            if (states.contains(
              WidgetState.selected,
            )) {
              return const IconThemeData(
                color:
                    primaryTurquoise,
                size: 24,
              );
            }

            return const IconThemeData(
              color: textMuted,
              size: 23,
            );
          },
        ),

        labelTextStyle:
            WidgetStateProperty.resolveWith<
                TextStyle>(
          (
            Set<WidgetState> states,
          ) {
            if (states.contains(
              WidgetState.selected,
            )) {
              return const TextStyle(
                color:
                    primaryTurquoise,
                fontSize: 11,
                fontWeight:
                    FontWeight.w700,
              );
            }

            return const TextStyle(
              color: textMuted,
              fontSize: 11,
              fontWeight:
                  FontWeight.w500,
            );
          },
        ),
      ),

      // ========================================================
      // DIALOG
      // ========================================================

      dialogTheme:
          DialogThemeData(
        backgroundColor:
            surfaceWhite,

        surfaceTintColor:
            Colors.transparent,

        elevation: 0,

        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            24,
          ),
        ),
      ),

      // ========================================================
      // DIVIDER
      // ========================================================

      dividerTheme:
          const DividerThemeData(
        color: borderLight,
        thickness: 1,
        space: 1,
      ),

      // ========================================================
      // PROGRESS INDICATOR
      // ========================================================

      progressIndicatorTheme:
          const ProgressIndicatorThemeData(
        color: primaryTurquoise,
      ),

      // ========================================================
      // TEXT
      // ========================================================

      textTheme:
          const TextTheme(
        displayLarge: TextStyle(
          color: secondaryDark,
          fontWeight:
              FontWeight.w800,
        ),

        headlineLarge: TextStyle(
          color: secondaryDark,
          fontWeight:
              FontWeight.w800,
        ),

        headlineMedium: TextStyle(
          color: secondaryDark,
          fontWeight:
              FontWeight.w800,
        ),

        headlineSmall: TextStyle(
          color: secondaryDark,
          fontWeight:
              FontWeight.w700,
        ),

        titleLarge: TextStyle(
          color: secondaryDark,
          fontWeight:
              FontWeight.w700,
        ),

        titleMedium: TextStyle(
          color: secondaryDark,
          fontWeight:
              FontWeight.w700,
        ),

        bodyLarge: TextStyle(
          color: secondaryDark,
        ),

        bodyMedium: TextStyle(
          color: secondaryDark,
        ),

        bodySmall: TextStyle(
          color: textMuted,
        ),

        labelLarge: TextStyle(
          fontWeight:
              FontWeight.w700,
        ),
      ),
    );
  }
}