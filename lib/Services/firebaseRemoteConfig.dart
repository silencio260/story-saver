import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/cupertino.dart';

class FirebaseRemoteConfigKeys {
  // static const String welcomeMessage = 'welcome_message';
  static const String time_before_firs_insta_ad = 'time_before_firs_insta_ad';
  static const String min_banner_ad_interval = 'min_banner_ad_interval';
  static const String min_insta_ad_interval = 'min_insta_ad_interval';
}

class FirebaseRemoteConfigService {
  FirebaseRemoteConfigService._() : _remoteConfig = FirebaseRemoteConfig.instance; // MODIFIED

  static FirebaseRemoteConfigService? _instance; // NEW
  factory FirebaseRemoteConfigService() => _instance ??= FirebaseRemoteConfigService._(); // NEW

  final FirebaseRemoteConfig _remoteConfig;

  String getString(String key) => _remoteConfig.getString(key); // NEW
  bool getBool(String key) =>_remoteConfig.getBool(key); // NEW
  int getInt(String key) =>_remoteConfig.getInt(key); // NEW
  double getDouble(String key) =>_remoteConfig.getDouble(key); // NEW

  ///////
  // String get welcomeMessage => _remoteConfig.getString(FirebaseRemoteConfigKeys.welcomeMessage);


  Future<void> _setConfigSettings() async => _remoteConfig.setConfigSettings(
    RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 12),
    ),
  );

  Future<void> _setDefaults() async => _remoteConfig.setDefaults(
    const {
      // FirebaseRemoteConfigKeys.welcomeMessage: 'Hey there, this message is coming from local defaults.',
      FirebaseRemoteConfigKeys.time_before_firs_insta_ad: 15,
      FirebaseRemoteConfigKeys.min_banner_ad_interval: 10,
      FirebaseRemoteConfigKeys.min_insta_ad_interval: 15
    },
  );

  Future<void> fetchAndActivate() async {
    bool updated = await _remoteConfig.fetchAndActivate();

    if (updated) {
      debugPrint('The config has been updated.');
    } else {
      debugPrint('The config is not updated..');
    }
  }

  Future<void> initialize() async {
    await _setConfigSettings();
    await _setDefaults();
    await fetchAndActivate();
  }

}