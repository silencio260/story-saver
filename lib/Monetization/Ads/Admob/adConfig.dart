import 'package:storysaver/Services/firebaseRemoteConfig.dart';
// Assuming FirebaseRemoteConfigKeys is available from an import or defined elsewhere.
// If it's part of firebaseRemoteConfig.dart, ensure the import covers it.
// For example, if it's in a different file:
// import 'package:storysaver/path/to/firebase_remote_config_keys.dart';

class AdConfig {
  static final FirebaseRemoteConfigService _remoteConfigService =
      FirebaseRemoteConfigService();

  static late final int time_before_first_insta_ad;
  static late final int min_banner_ad_interval;
  static late final int min_insta_ad_interval;

  static bool _isInitializing = false;
  static bool _isInitialized = false;

  /// Constructor for AdConfig.
  /// Note: For static configuration values to be ready,
  /// `AdConfig.ensureInitialized()` must be called and awaited during app startup.
  AdConfig() {
    if (!_isInitialized && !_isInitializing) {
      print(
          "Warning: AdConfig instance created, but AdConfig.ensureInitialized() has not completed. Static ad config values may not be ready.");
    }
  }

  /// Initializes the remote config service and fetches ad configuration values.
  /// This method should be called once during app startup.
  ///
  /// Example usage in your main.dart:
  /// ```dart
  /// Future<void> main() async {
  ///   WidgetsFlutterBinding.ensureInitialized(); // If not already called
  ///   await AdConfig.ensureInitialized();
  ///   runApp(MyApp());
  /// }
  /// ```
  static Future<void> ensureInitialized() async {
    // Prevent re-initialization or concurrent initialization
    if (_isInitialized || _isInitializing) {
      return;
    }
    _isInitializing = true;
    print('init remote config 1');
    try {
      await _remoteConfigService.initialize(); // Ensure this is awaited

      // Ensure FirebaseRemoteConfigKeys is accessible here
      // For example, FirebaseRemoteConfigKeys.time_before_first_insta_ad
      time_before_first_insta_ad = _remoteConfigService
          .getInt(FirebaseRemoteConfigKeys.time_before_first_insta_ad);
      min_banner_ad_interval = _remoteConfigService
          .getInt(FirebaseRemoteConfigKeys.min_banner_ad_interval);
      min_insta_ad_interval = _remoteConfigService
          .getInt(FirebaseRemoteConfigKeys.min_insta_ad_interval);

      _isInitialized = true;
    } catch (e) {
      print('Error initializing AdConfig: $e. Using default ad config values.');
      // Set default values in case of an error
      time_before_first_insta_ad = 3; // Default fallback
      min_banner_ad_interval = 3; // Default fallback
      min_insta_ad_interval = 5; // Default fallback
      _isInitialized =
          true; // Mark as initialized (with defaults) to prevent repeated attempts
    } finally {
      _isInitializing = false;
    }
  }
}

// Ensure FirebaseRemoteConfigKeys is defined or imported.
// If it's not available through the existing import, you might need to add its definition,
// for example, if it's a simple class like this:
/*
class FirebaseRemoteConfigKeys {
  static const String time_before_first_insta_ad = "time_before_first_insta_ad";
  static const String min_banner_ad_interval = "min_banner_ad_interval";
  static const String min_insta_ad_interval = "min_insta_ad_interval";
  // Add other keys if needed
}
*/
