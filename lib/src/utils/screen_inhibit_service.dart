import 'package:flutter/services.dart';
import 'package:universal_platform/universal_platform.dart';

/// A service to prevent screen lock on Linux using D-Bus.
/// On other platforms, this is a no-op.
class ScreenInhibitService {
  static const MethodChannel _channel = MethodChannel('screen_inhibit');
  static bool _isInhibited = false;

  /// Prevents the screen from locking.
  /// This is only effective on Linux. On other platforms, it does nothing.
  static Future<void> inhibit() async {
    if (!UniversalPlatform.isLinux || _isInhibited) {
      return;
    }

    try {
      await _channel.invokeMethod('inhibit');
      _isInhibited = true;
    } catch (e) {
      // Ignore errors - screen lock inhibit is not critical
      print('Failed to inhibit screen lock: $e');
    }
  }

  /// Allows the screen to lock again.
  /// This is only effective on Linux. On other platforms, it does nothing.
  static Future<void> uninhibit() async {
    if (!UniversalPlatform.isLinux || !_isInhibited) {
      return;
    }

    try {
      await _channel.invokeMethod('uninhibit');
      _isInhibited = false;
    } catch (e) {
      // Ignore errors
      print('Failed to uninhibit screen lock: $e');
    }
  }
}
