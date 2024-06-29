import 'dart:developer' as developer;

class Log {
  static void d(String message, {String? name, Object? error, StackTrace? stackTrace}) {
    developer.log(message, name: name ?? 'DEBUG', error: error, stackTrace: stackTrace, level: 500);
  }

  static void i(String message, {String? name, Object? error, StackTrace? stackTrace}) {
    developer.log(message, name: name ?? 'INFO', error: error, stackTrace: stackTrace, level: 800);
  }

  static void w(String message, {String? name, Object? error, StackTrace? stackTrace}) {
    developer.log(message, name: name ?? 'WARN', error: error, stackTrace: stackTrace, level: 900);
  }

  static void e(String message, {String? name, Object? error, StackTrace? stackTrace}) {
    developer.log(message, name: name ?? 'ERROR', error: error, stackTrace: stackTrace, level: 1000);
  }

  static void v(String message, {String? name, Object? error, StackTrace? stackTrace}) {
    developer.log(message, name: name ?? 'VERBOSE', error: error, stackTrace: stackTrace, level: 300);
  }
}
