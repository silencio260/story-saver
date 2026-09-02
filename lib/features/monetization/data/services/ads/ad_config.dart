import 'remote_config_service.dart';
import 'remote_config_keys.dart';

class AdConfig {
  static final FirebaseRemoteConfigService _remoteConfigService =
      FirebaseRemoteConfigService();

  static int timeBeforeFirstInterstitialAd = 3;
  static int minBannerAdInterval = 3;
  static int minInterstitialAdInterval = 5;

  static bool _isInitializing = false;
  static bool _isInitialized = false;

  const AdConfig._();

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
    if (_isInitialized || _isInitializing) {
      return;
    }
    _isInitializing = true;
    try {
      await _remoteConfigService.initialize();
      timeBeforeFirstInterstitialAd = _remoteConfigService.getInt(
        FirebaseRemoteConfigKeys.timeBeforeFirstInterstitialAd,
      );
      minBannerAdInterval = _remoteConfigService.getInt(
        FirebaseRemoteConfigKeys.minBannerAdInterval,
      );
      minInterstitialAdInterval = _remoteConfigService.getInt(
        FirebaseRemoteConfigKeys.minInterstitialAdInterval,
      );

      _isInitialized = true;
    } on Object {
      timeBeforeFirstInterstitialAd = 3;
      minBannerAdInterval = 3;
      minInterstitialAdInterval = 5;
      _isInitialized = true;
    } finally {
      _isInitializing = false;
    }
  }
}
