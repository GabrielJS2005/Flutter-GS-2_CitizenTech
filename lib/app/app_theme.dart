import 'package:flutter/material.dart';

/// Tema Material Design 3 de Alto Contraste (WCAG 2.2 AA/AAA) para o Caminho Livre.
/// Garante alvos de toque mínimos de 48x48dp e contraste cromático para baixa visão.
class AppTheme {
  AppTheme._();

  // Paleta de alto contraste institucional CitizenTech
  static const Color primaryNavy = Color(0xFF0B3D91);
  static const Color secondaryTeal = Color(0xFF00796B);
  static const Color accentAmber = Color(0xFFE65100);
  static const Color criticalRed = Color(0xFFB71C1C);
  static const Color surfaceBackground = Color(0xFFF6F8FC);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color highContrastText = Color(0xFF101828);
  static const Color secondaryText = Color(0xFF344054);

  static ThemeData get lightHighContrastTheme {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: primaryNavy,
      primary: primaryNavy,
      onPrimary: Colors.white,
      secondary: secondaryTeal,
      onSecondary: Colors.white,
      tertiary: accentAmber,
      error: criticalRed,
      onError: Colors.white,
      surface: cardSurface,
      onSurface: highContrastText,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surfaceBackground,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryNavy,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardSurface,
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFD0D5DD), width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryNavy,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryNavy,
          minimumSize: const Size(48, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: const BorderSide(color: primaryNavy, width: 1.8),
          textStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: primaryNavy,
        secondarySelectedColor: primaryNavy,
        labelStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: highContrastText,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        side: const BorderSide(color: Color(0xFF98A2B3), width: 1.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF98A2B3), width: 1.4),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF98A2B3), width: 1.4),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryNavy, width: 2.2),
        ),
      ),
    );
  }
}

