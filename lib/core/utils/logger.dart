import 'dart:developer' as developer;

/// Simple debug logger to replace print() statements.
class Logger {
  /// Log an info message
  static void info(String message, [String name = 'MirrorCam']) {
    developer.log('INFO: $message', name: name);
  }

  /// Log a warning message
  static void warning(String message, [String name = 'MirrorCam']) {
    developer.log('WARN: $message', name: name);
  }

  /// Log an error message
  static void error(
    String message, [
    Object? error,
    StackTrace? stackTrace,
    String name = 'MirrorCam',
  ]) {
    developer.log(
      'ERROR: $message',
      error: error,
      stackTrace: stackTrace,
      name: name,
    );
  }
}
