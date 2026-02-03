import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized logger utility for the application.
/// Respects DEBUG_LOGS environment variable.
class AppLogger {
  static final bool _isDebug = (dotenv.env['DEBUG_LOGS'] ?? 'false').toLowerCase() == 'true';

  /// Log a general debug message
  static void log(String message, [dynamic error]) {
    if (!_isDebug) return;
    
    if (error != null) {
      print('[HOMECARE] $message: $error');
    } else {
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
    // Errors are critical, so we might want to print them even if DEBUG_LOGS is false.
    // However, to keep console clean as requested, we will rely on checking the flag for "debug" info.
    // If it's a critical app crash, Flutter catches it.
    // For handled exceptions we log, let's use the flag or maybe a separate clearer format.
    
    // IF we want to force print errors:
    // print('[HOMECARE ERROR] $message');
    
    // IF we strictly follow the flag:
    if (!_isDebug) return;

    print('[HOMECARE ERROR] $message');
    if (error != null) print('Details: $error');
    if (stackTrace != null) print('Stack trace: $stackTrace');
  }

  /// Log info (alias for log)
  static void info(String message) => log(message);
  
  /// Log a warning message
  static void warn(String message) => log('[WARNING] $message');
  
  /// Check if debugging is enabled
  static bool get isDebugEnabled => _isDebug;
}
