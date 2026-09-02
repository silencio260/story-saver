import 'dart:io';

class AdUnitIds {
  const AdUnitIds._();

  static String get banner {
    if (Platform.isAndroid) {
      return const String.fromEnvironment('banner_ad_id');
    }
    if (Platform.isIOS) return '<YOUR_IOS_BANNER_ID_ID>';
    return '';
  }

  static String get interstitial {
    if (Platform.isAndroid) {
      return const String.fromEnvironment('interstitial_ad_id');
    }
    if (Platform.isIOS) return '<YOUR_IOS_BANNER_ID_ID>';
    return '';
  }
}
