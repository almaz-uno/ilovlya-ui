import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

/// Провайдер для основного логгера приложения
final loggerProvider = Provider<Logger>((ref) {
  return Logger(
    printer: kDebugMode
        ? PrettyPrinter(
            methodCount: 2,
            errorMethodCount: 8,
            lineLength: 120,
            colors: true,
            printEmojis: true,
          )
        : SimplePrinter(colors: false),
    level: kDebugMode ? Level.debug : Level.warning,
    filter: kDebugMode ? DevelopmentFilter() : ProductionFilter(),
  );
});

/// Фабрика для создания именованных логгеров
class LoggerFactory {
  /// Создает логгер с указанным префиксом
  static Logger create(String name) {
    return Logger(
      printer: PrefixPrinter(
        kDebugMode
            ? PrettyPrinter(
                methodCount: 2,
                errorMethodCount: 8,
                lineLength: 120,
                colors: true,
                printEmojis: true,
              )
            : SimplePrinter(colors: false),
        debug: '[$name]',
        trace: '[$name]',
        info: '[$name]',
        warning: '[$name]',
        error: '[$name]',
        fatal: '[$name]',
      ),
      level: kDebugMode ? Level.debug : Level.warning,
      filter: kDebugMode ? DevelopmentFilter() : ProductionFilter(),
    );
  }
}

/// Предопределенные логгеры для разных модулей
class AppLoggers {
  static final api = LoggerFactory.create('API');
  static final media = LoggerFactory.create('Media');
  static final player = LoggerFactory.create('Player');
  static final settings = LoggerFactory.create('Settings');
  static final download = LoggerFactory.create('Download');
  static final ui = LoggerFactory.create('UI');
}
