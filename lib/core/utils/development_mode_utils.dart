import 'package:flutter/foundation.dart';

/// Resolves build-time development flags.
class DevelopmentModeUtils {
  static bool checkDevelopmentMode() {
    bool founders_version = const bool.fromEnvironment("founders_version");
    bool development_mode = const bool.fromEnvironment("development_mode");
    bool special_version_mode = const bool.fromEnvironment(
      "special_version_mode",
    );

    if (kDebugMode ||
        founders_version ||
        development_mode ||
        special_version_mode) {
      return true;
    }

    print(
      "kDebugMode -> ${kDebugMode}, founders_version -> ${founders_version}, development_mode -> ${development_mode}, special_version_mode -> ${special_version_mode}",
    );

    return false;
  }
}
