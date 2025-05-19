import 'dart:io';

import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdHelper {
  static String get bannerAdUnitId {
    if(Platform.isAndroid)
      return  const String.fromEnvironment("banner_ad_id");
    else if (Platform.isIOS)
      return '<YOUR_IOS_BANNER_ID_ID>';
    else
      throw UnsupportedError("Unsupported platform");
  }

  static String get InterstitialAdUnitId {
    if(Platform.isAndroid)
      return  const String.fromEnvironment("interstitial_ad_id");
    else if (Platform.isIOS)
      return '<YOUR_IOS_BANNER_ID_ID>';
    else
      throw UnsupportedError("Unsupported platform");
  }

}

class AdmobWrapper {
  static BannerAd? _bannerAd;
  static InterstitialAd? _interstitialAd;

  static void LoadBannerAd() {
    BannerAd(
        adUnitId: AdHelper.bannerAdUnitId,
        request: AdRequest(),
        size: AdSize.banner,
        listener: BannerAdListener(
            onAdLoaded: (ad) {
              _bannerAd = ad as BannerAd;
              // setState(() {
              //   _bannerAd = ad as BannerAd;
              // });
            },
            onAdFailedToLoad: (ad, err){
              print('Failed to load a banner ad: ${err.message}');
              ad.dispose();
            }
        )
    )..load();
  }

  static void loadInterstitialAd() {
    InterstitialAd.load(
        adUnitId: AdHelper.InterstitialAdUnitId,
        request: AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
            onAdLoaded: (ad) {
              ad.fullScreenContentCallback = FullScreenContentCallback(
                  onAdDismissedFullScreenContent: (ad){}
              );

              _interstitialAd = ad;

              // setState(() {
              //   _interstitialAd = ad;
              // });
            },
            onAdFailedToLoad: (err){
              print('Failed to load a InterstitialAd  ad: ${err.message}');
              // ad.dispose();
            }
        )
    );
  }

  static void _showInterstitialAd() {
    if(_interstitialAd != null){
      _interstitialAd!.show();
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad){
            ad.dispose();

            ////////////
            InterstitialAd.load(
              adUnitId: AdHelper.InterstitialAdUnitId,
              request: AdRequest(),

              adLoadCallback: InterstitialAdLoadCallback(
                  onAdLoaded: (ad) {
                    ad.fullScreenContentCallback = FullScreenContentCallback(
                        onAdFailedToShowFullScreenContent: (ad, err){
                          ad.dispose();

                        },
                        onAdDismissedFullScreenContent: (ad){}
                    );

                    _interstitialAd = ad;
                    // setState(() {
                    //   _interstitialAd = ad;
                    //
                    // });
                  },
                  onAdFailedToLoad: (err){
                    print('Failed to load a InterstitialAd  ad: ${err.message}');
                    // ad.dispose();
                  }
              ),

            );

          }
      );

    }
  }


}

