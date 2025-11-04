import 'package:flutter/foundation.dart';

class Log {
  static void d(String message) {
    debugPrint(message);
  }

  static void e(String message, [Object? error, StackTrace? stackTrace]) {
    debugPrint('ERROR: $message');
    if (error != null) debugPrint(' • $error');
    if (stackTrace != null) debugPrint(stackTrace.toString());
  }
}
