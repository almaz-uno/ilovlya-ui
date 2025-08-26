import 'package:flutter/material.dart';

/// Тёплые цвета для медиа-плеера
class MediaPlayerTheme {
  // Цвета для светлой темы
  static const Color lightProgressBarColor = Color(0xFFD2691E); // Шоколадный
  static const Color lightProgressBarBackground = Color(0xFFF5F5DC); // Беж
  static const Color lightControlButtonColor = Color(0xFFFF7F50); // Коралловый
  static const Color lightControlButtonText = Colors.white;
  static const Color lightPlayerBackground = Color(0xFFFFFBF5); // Тёплый кремовый
  static const Color lightPlayerText = Color(0xFF5D4037); // Тёплый коричневый
  static const Color lightSeekBarThumb = Color(0xFFCD853F); // Песочно-коричневый

  // Цвета для тёмной темы
  static const Color darkProgressBarColor = Color(0xFFFF8C00); // Тёмный оранжевый
  static const Color darkProgressBarBackground = Color(0xFF3E2723); // Тёмно-коричневый
  static const Color darkControlButtonColor = Color(0xFFDEB887); // Пшеничный
  static const Color darkControlButtonText = Color(0xFF2D2D2D);
  static const Color darkPlayerBackground = Color(0xFF2D1B0E); // Тёплый тёмно-коричневый
  static const Color darkPlayerText = Color(0xFFF5DEB3); // Тёплый светлый
  static const Color darkSeekBarThumb = Color(0xFFCD853F); // Песочно-коричневый

  /// Получить цвет прогресс-бара в зависимости от темы
  static Color getProgressBarColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? lightProgressBarColor
        : darkProgressBarColor;
  }

  /// Получить цвет фона прогресс-бара в зависимости от темы
  static Color getProgressBarBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? lightProgressBarBackground
        : darkProgressBarBackground;
  }

  /// Получить цвет кнопок управления в зависимости от темы
  static Color getControlButtonColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? lightControlButtonColor
        : darkControlButtonColor;
  }

  /// Получить цвет текста на кнопках управления в зависимости от темы
  static Color getControlButtonTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? lightControlButtonText
        : darkControlButtonText;
  }

  /// Получить цвет фона плеера в зависимости от темы
  static Color getPlayerBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? lightPlayerBackground
        : darkPlayerBackground;
  }

  /// Получить цвет текста плеера в зависимости от темы
  static Color getPlayerTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? lightPlayerText
        : darkPlayerText;
  }

  /// Получить цвет ползунка прогресс-бара в зависимости от темы
  static Color getSeekBarThumbColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? lightSeekBarThumb
        : darkSeekBarThumb;
  }

  /// Создать тёплый стиль для кнопок медиа-плеера
  static ButtonStyle getWarmButtonStyle(BuildContext context) {
    return TextButton.styleFrom(
      backgroundColor: getControlButtonColor(context),
      foregroundColor: getControlButtonTextColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  /// Создать тёплый стиль для IconButton в медиа-плеере
  static ButtonStyle getWarmIconButtonStyle(BuildContext context) {
    return IconButton.styleFrom(
      backgroundColor: getControlButtonColor(context).withValues(alpha: 0.1),
      foregroundColor: getControlButtonColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
