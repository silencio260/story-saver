import 'package:flutter/foundation.dart';

/// Utilities for Development Mode
///
/// Helps in conditional logging and feature enabling during development.
class DevModeUtils {
  /// Check if the app is complying with debug mode
  static bool get isDebugMode => kDebugMode;

  /// Check if the app is complying with release mode
  static bool get isReleaseMode => kReleaseMode;

  /// Execute code only in debug mode
  static void runInDebug(VoidCallback action) {
    if (isDebugMode) {
      action();
    }
  }
}
