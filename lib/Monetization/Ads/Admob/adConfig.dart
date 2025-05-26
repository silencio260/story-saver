import 'package:storysaver/Services/firebaseRemoteConfig.dart';
//
class AdConfig {
  static final remoteConfig = FirebaseRemoteConfigService();
//   remoteConfig.getString(FirebaseRemoteConfigKeys.welcomeMessage),

//   final int time_before_firs_insta_ad = 5;
//   final int min_banner_ad_interval = 30;
//   final int min_insta_ad_interval = 10;

  final int time_before_firs_insta_ad = remoteConfig.getInt(FirebaseRemoteConfigKeys.time_before_firs_insta_ad);
  final int min_banner_ad_interval = remoteConfig
      .getInt(FirebaseRemoteConfigKeys.time_before_firs_insta_ad);
  final int min_insta_ad_interval = remoteConfig
      .getInt(FirebaseRemoteConfigKeys.time_before_firs_insta_ad);
}