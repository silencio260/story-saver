import 'dart:io';

class AdHelper {
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return const String.fromEnvironment('banner_ad_id');
    }
    if (Platform.isIOS) return '<YOUR_IOS_BANNER_ID_ID>';
    throw UnsupportedError('Unsupported platform');
  }

  static String get InterstitialAdUnitId {
    if (Platform.isAndroid) {
      return const String.fromEnvironment('interstitial_ad_id');
    }
    if (Platform.isIOS) return '<YOUR_IOS_BANNER_ID_ID>';
    throw UnsupportedError('Unsupported platform');
  }
}
