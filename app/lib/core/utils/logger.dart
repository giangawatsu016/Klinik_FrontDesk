import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized logger utility for the application.
/// Respects DEBUG_LOGS environment variable.
class AppLogger {
  static final bool _isDebug =
      (dotenv.env['DEBUG_LOGS'] ?? 'false').toLowerCase() == 'true';

  /// Log a general debug message
  static void log(String message, [dynamic error]) {
    if (!_isDebug) return;

    if (error != null) {
      // ignore: avoid_print
      print('[HOMECARE] $message: $error');
    } else {
      // ignore: avoid_print
      print('[HOMECARE] $message');
    }
  }

  /// Log an error message (always printed unless specifically desired to hide)
  /// Currently we print errors even if debug logs are off, but we can change this policy.
  /// For now, let's treat "Error" as something that should usually be visible,
  /// but we'll respect the flag if we want strict silence.
  /// Actually, standard practice: Errors should usually be visible.
  /// Let's make error logging always visible OR controlled by a separate flag?
  /// For this request "handle DEBUG_LOGS=false or true", we'll stick to the flag
  /// but maybe allow critical errors.
  /// Let's assume DEBUG_LOGS controls "verbose" logging. Errors might be critical exception traces.
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    // Errors are critical, so we print them even if DEBUG_LOGS is false.

    // ignore: avoid_print
    print('[HOMECARE ERROR] $message');

    if (!_isDebug) return;

    // ignore: avoid_print
    if (error != null) print('Details: $error');
    // ignore: avoid_print
    if (stackTrace != null) print('Stack trace: $stackTrace');
  }

  /// Log info (alias for log)
  static void info(String message) => log(message);

  /// Log a warning message
  static void warn(String message) => log('[WARNING] $message');

  /// Check if debugging is enabled
  static bool get isDebugEnabled => _isDebug;
}
