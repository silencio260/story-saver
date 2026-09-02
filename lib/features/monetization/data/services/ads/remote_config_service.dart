import 'package:firebase_remote_config/firebase_remote_config.dart';

import 'remote_config_keys.dart';

class FirebaseRemoteConfigService {
  FirebaseRemoteConfigService._()
    : _remoteConfig = FirebaseRemoteConfig.instance;

  static FirebaseRemoteConfigService? _instance;
  factory FirebaseRemoteConfigService() =>
      _instance ??= FirebaseRemoteConfigService._();

  final FirebaseRemoteConfig _remoteConfig;

  String getString(String key) => _remoteConfig.getString(key);
  bool getBool(String key) => _remoteConfig.getBool(key);
  int getInt(String key) => _remoteConfig.getInt(key);
  double getDouble(String key) => _remoteConfig.getDouble(key);

  Future<void> _setConfigSettings() async => _remoteConfig.setConfigSettings(
    RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 12),
    ),
  );

  Future<void> _setDefaults() async =>
      _remoteConfig.setDefaults(const <String, Object>{
        FirebaseRemoteConfigKeys.timeBeforeFirstInterstitialAd: 3,
        FirebaseRemoteConfigKeys.minBannerAdInterval: 3,
        FirebaseRemoteConfigKeys.minInterstitialAdInterval: 6,
      });

  Future<void> fetchAndActivate() async {
    await _remoteConfig.fetchAndActivate();
  }

  Future<void> initialize() async {
    await _setConfigSettings();
    await _setDefaults();
    await fetchAndActivate();
  }
}
