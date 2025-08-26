import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Тёплые цветовые схемы для приложения
class WarmTheme {
  // Тёплая светлая тема с золотистыми и персиковыми оттенками
  static final ColorScheme _lightColorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFFD2691E), // Шоколадный/кирпичный цвет
    brightness: Brightness.light,
    primary: const Color(0xFFD2691E), // Шоколадный
    onPrimary: Colors.white,
    secondary: const Color(0xFFFF7F50), // Коралловый
    onSecondary: Colors.white,
    tertiary: const Color(0xFFCD853F), // Песочно-коричневый
    surface: const Color(0xFFFFFBF5), // Тёплый кремовый
    onSurface: const Color(0xFF5D4037), // Тёплый коричневый для текста
    surfaceContainerHighest: const Color(0xFFF5F5DC), // Беж
    outline: const Color(0xFFBC8F8F), // Розово-коричневый
  );

  // Тёплая тёмная тема с янтарными и медными оттенками
  static final ColorScheme _darkColorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFFFF8C00), // Тёмный оранжевый
    brightness: Brightness.dark,
    primary: const Color(0xFFFF8C00), // Тёмный оранжевый
    onPrimary: const Color(0xFF1A1A1A),
    secondary: const Color(0xFFDEB887), // Пшеничный
    onSecondary: const Color(0xFF2D2D2D),
    tertiary: const Color(0xFFCD853F), // Песочно-коричневый
    surface: const Color(0xFF2D1B0E), // Тёплый тёмно-коричневый
    onSurface: const Color(0xFFF5DEB3), // Тёплый светлый для текста
    surfaceContainerHighest: const Color(0xFF3E2723), // Тёмно-коричневый
    outline: const Color(0xFF8D6E63), // Коричневый
  );

  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: _lightColorScheme,
      textTheme: GoogleFonts.ptSansCaptionTextTheme(
        ThemeData.light().textTheme,
      ).apply(
        bodyColor: _lightColorScheme.onSurface,
        displayColor: _lightColorScheme.onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _lightColorScheme.surface,
        foregroundColor: _lightColorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        color: _lightColorScheme.surfaceContainerHighest,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _lightColorScheme.primary,
          foregroundColor: _lightColorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _lightColorScheme.secondary,
        foregroundColor: _lightColorScheme.onSecondary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _lightColorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _lightColorScheme.primary, width: 2),
        ),
      ),
      useMaterial3: true,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: _darkColorScheme,
      textTheme: GoogleFonts.ptSansTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: _darkColorScheme.onSurface,
        displayColor: _darkColorScheme.onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _darkColorScheme.surface,
        foregroundColor: _darkColorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        color: _darkColorScheme.surfaceContainerHighest,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkColorScheme.primary,
          foregroundColor: _darkColorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _darkColorScheme.secondary,
        foregroundColor: _darkColorScheme.onSecondary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _darkColorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _darkColorScheme.primary, width: 2),
        ),
      ),
      useMaterial3: true,
    );
  }
}
