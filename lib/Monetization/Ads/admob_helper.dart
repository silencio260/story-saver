import 'dart:io';

import 'package:flutter/cupertino.dart';
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


class AdmobWrapper extends ChangeNotifier {
  // Singleton pattern
  static final AdmobWrapper _instance = AdmobWrapper._internal();
  factory AdmobWrapper() => _instance;
  AdmobWrapper._internal();

  static BannerAd? _bannerAd;
  static InterstitialAd? _interstitialAd;

  BannerAd? get bannerAd => _bannerAd;

  // Set banner ad and notify listeners
  set bannerAd(BannerAd? ad) {
    _bannerAd = ad;
    notifyListeners();
  }

  static void disposeAds() {
    _bannerAd!.dispose();
    _interstitialAd?.dispose();
  }

   void loadBannerAd() async {
    BannerAd(
        adUnitId: AdHelper.bannerAdUnitId,
        request: AdRequest(),
        size: AdSize.banner,
        listener: BannerAdListener(
            onAdLoaded: (ad) {
              _bannerAd = ad as BannerAd;
              notifyListeners();
            },
            onAdFailedToLoad: (ad, err){
              print('Failed to load a banner ad: ${err.message}');
              ad.dispose();
            }
        )
    )..load();
  }

   void loadInterstitialAd() {
    InterstitialAd.load(
        adUnitId: AdHelper.InterstitialAdUnitId,
        request: AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
            onAdLoaded: (ad) {
              ad.fullScreenContentCallback = FullScreenContentCallback(
                  onAdDismissedFullScreenContent: (ad){}
              );

              _interstitialAd = ad;
              notifyListeners();

            },
            onAdFailedToLoad: (err){
              print('Failed to load a InterstitialAd  ad: ${err.message}');
              // ad.dispose();
            }
        )
    );
  }

  // void showInterstitialAd() {
  //   _showInterstitialAd();
  // }

   void showInterstitialAd() {
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
                    notifyListeners();

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

   Widget? DisplayBannerAdWidget() {
    print('bannerAd $_bannerAd ');
    return _bannerAd != null ?
    SizedBox(
      // padding: EdgeInsets.only(top: 50),
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: _bannerAd != null? AdWidget(ad: _bannerAd!) : Container(),
    ) : null;
  }

}

class DisplayBannerAdWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Use AnimatedBuilder to listen for changes
    return AnimatedBuilder(
      animation: AdmobWrapper(),
      builder: (context, child) {
        final bannerAd = AdmobWrapper().bannerAd;
        print('bannerAd $bannerAd'); // Debug print

        if (bannerAd == null) {
          return SizedBox(); // Return empty SizedBox instead of null
        }

        return SizedBox(
          width: bannerAd.size.width.toDouble(),
          height: bannerAd.size.height.toDouble(),
          child: AdWidget(ad: bannerAd),
        );
      },
    );
  }
}

