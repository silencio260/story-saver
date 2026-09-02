import 'package:flutter/cupertino.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:storysaver/Monetization/AdSuppressionManager.dart';
import 'package:storysaver/Monetization/Ads/Admob/adConfig.dart';
import 'package:storysaver/Monetization/Ads/Admob/ad_helper.dart';
import 'package:storysaver/Monetization/SubscriptionManager.dart';
import 'package:storysaver/Services/analytics_service.dart';
import 'package:storysaver/Utils/loggerUtil.dart';

class AdmobWrapper extends ChangeNotifier {
  // Singleton pattern
  static final AdmobWrapper _instance = AdmobWrapper._internal();
  factory AdmobWrapper() => _instance;
  AdmobWrapper._internal() {
    SubscriptionManager().addListener(_onSubscriptionChanged);
  }

  void _onSubscriptionChanged() {
    if (SubscriptionManager().isPremium) {
      print('AdmobWrapper: Premium activated, disposing interstitial ads');
      _interstitialAd?.dispose();
      _interstitialAd = null;
      _isInterstitialAdReady = false;
      notifyListeners();
    }
  }

  // BannerAd? _bannerAd;
  static InterstitialAd? _interstitialAd;
  static bool _isBannerAdReady = false;
  // static

  static bool _isInterstitialAdReady = true;
  static bool _hasShownInstaAd = false;
  static bool _shouldRetryFailedInterstitialAdRequest = false;

  // BannerAd? get bannerAd => _bannerAd;

  // Set banner ad and notify listeners
  // set bannerAd(BannerAd? ad) {
  //   _bannerAd = ad;
  //   notifyListeners();
  // }
  //
  // void disposeBanner() {
  //   _bannerAd!.dispose();
  // }

  static void disposeAds() {
    // _bannerAd!.dispose();
    // disposeAds();
    _interstitialAd?.dispose();
  }
  //
  //  void loadBannerAd() async {
  //
  //   // await _bannerAd!.dispose();
  //   // _bannerAd = null;
  //
  //   BannerAd(
  //       adUnitId: AdHelper.bannerAdUnitId,
  //       request: AdRequest(),
  //       size: AdSize.banner,
  //       listener: BannerAdListener(
  //           onAdLoaded: (ad) {
  //             _bannerAd = ad as BannerAd;
  //             notifyListeners();
  //           },
  //           onAdFailedToLoad: (ad, err){
  //             print('Failed to load a banner ad: ${err.message}');
  //             ad.dispose();
  //           }
  //       )
  //   )..load();
  // }

  void resetInterstitialAdValues() {
    _interstitialAd = null;
    _isInterstitialAdReady = false;
    _hasShownInstaAd = false;
    // _shouldRetryFailedInterstitialAdRequest = false;
    notifyListeners();
  }

  void loadInterstitialAd() async {
    // Check if ads are suppressed
    if (AdSuppressionManager().areAdsSuppressed) {
      print(
          'loadInterstitialAd - Ads are suppressed, skipping interstitial ad load');
      print(
          'loadInterstitialAd - Suppression reasons: ${AdSuppressionManager().activeSuppressionReasons}');
      return;
    }

    // Check if user is premium before loading ad
    await SubscriptionManager().initialize();
    if (SubscriptionManager().isPremium) {
      print(
          'loadInterstitialAd - User is premium, skipping interstitial ad load');
      return;
    }

    print(
        'in loadInterstitialAd -- AdConfig().time_before_first_insta_ad - ${AdConfig.time_before_first_insta_ad} --- '
        'AdConfig().min_insta_ad_interval ${AdConfig.min_insta_ad_interval}');
    InterstitialAd.load(
        adUnitId: AdHelper.InterstitialAdUnitId,
        request: AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {});

          // _isInterstitialAdReady = false;

          // _interstitialAd = ad;
          // notifyListeners();

          Future.delayed(Duration(seconds: AdConfig.time_before_first_insta_ad),
              () {
            // _isInterstitialAdReady = true;
            _interstitialAd = ad;
            notifyListeners();
            print('loadInterstitialAd - Successfully loaded interstitial ad');
            // print('This runs after 3 seconds');
          });
        }, onAdFailedToLoad: (err) {
          resetInterstitialAdValues();
          _shouldRetryFailedInterstitialAdRequest = true;

          print(
              'loadInterstitialAd - Failed to load a InterstitialAd ad: ${err.message}');
          // ad.dispose();
        }));
  }

  void showInterstitialAd() async {
    // Check if ads are suppressed
    if (AdSuppressionManager().areAdsSuppressed) {
      print(
          'showInterstitialAd - Ads are suppressed, skipping interstitial ad display');
      print(
          'showInterstitialAd - Suppression reasons: ${AdSuppressionManager().activeSuppressionReasons}');
      return;
    }

    // Check if user is premium before showing ad
    await SubscriptionManager().initialize();
    if (SubscriptionManager().isPremium) {
      print(
          'showInterstitialAd - User is premium, skipping interstitial ad display');
      return;
    }

    if (_interstitialAd != null && _isInterstitialAdReady == true) {
      _interstitialAd!.show();

      _interstitialAd!.onPaidEvent =
          (ad, valueMicros, precision, currencyCode) {
        AnalyticsService().logAdImpressions(
          adUnitId: ad.adUnitId,
          adFormat: 'interstitial',
          valueMicros: valueMicros,
          currency: currencyCode,
        );

        printLogAdImpression(
            ad: 'Insta', valueMicros: valueMicros, currencyCode: currencyCode);
      };

      _interstitialAd!.fullScreenContentCallback =
          FullScreenContentCallback(onAdDismissedFullScreenContent: (ad) {
        // ad.dispose();

        print('onAdDismissedFullScreenContent');

        _isInterstitialAdReady = false;
        _hasShownInstaAd = true;

        Future.delayed(Duration(seconds: AdConfig.min_insta_ad_interval), () {
          _isInterstitialAdReady = true;
          _interstitialAd = ad;
          notifyListeners();
          // print('This runs after 3 seconds');
          loadInterstitialAd();
          print(
              'showInterstitialAd - successfully reload interstitial ad after ${AdConfig.min_insta_ad_interval}');
        });
        ////////////
        //   InterstitialAd.load(
        //     adUnitId: AdHelper.InterstitialAdUnitId,
        //     request: AdRequest(),
        //     adLoadCallback: InterstitialAdLoadCallback(onAdLoaded: (ad) {
        //       ad.fullScreenContentCallback = FullScreenContentCallback(
        //           onAdFailedToShowFullScreenContent: (ad, err) {
        //         ad.dispose();
        //       });
        //
        //       // _interstitialAd = ad;
        //       // notifyListeners();
        //
        //
        //       // FirebaseAnalytics.instance.logAdImpression(value: ad.)
        //     }, onAdFailedToLoad: (err) {
        //       resetInterstitialAdValues();
        //
        //       print(
        //           'showInterstitialAd - Failed to load a InterstitialAd ad: ${err.message}');
        //       // ad.dispose();
        //     }),
        //   ).timeout(
        //       Duration(
        //           seconds: _hasShownInstaAd == true
        //               ? 0
        //               : AdConfig.time_before_first_insta_ad), onTimeout: () {
        //     _hasShownInstaAd = true;
        //     // print('Operation timed out');
        //     return 'fallback result'; // optional return value
        //   });
      });
    } else {
      if (_shouldRetryFailedInterstitialAdRequest == true) {
        _shouldRetryFailedInterstitialAdRequest = false;
        Future.delayed(Duration(seconds: 2), () {
          loadInterstitialAd();
          print('_shouldRetryFailedInterstitialAdRequest');
          // _shouldRetryFailedInterstitialAdRequest = false;
        });
      }
    }
  }
}

// class DisplayBannerAdWidget extends StatelessWidget {
//
//   @override
//   Widget build(BuildContext context) {
//     // Use AnimatedBuilder to listen for changes
//     return AnimatedBuilder(
//       animation: AdmobWrapper(),
//       builder: (context, child) {
//         final bannerAd = AdmobWrapper().bannerAd;
//         print('bannerAd --> $bannerAd'); // Debug print
//
//         if (bannerAd == null) {
//           return SizedBox(); // Return empty SizedBox instead of null
//         }
//
//         return SizedBox(
//           width: bannerAd.size.width.toDouble(),
//           height: bannerAd.size.height.toDouble(),
//           child: AdWidget(ad: bannerAd),
//         );
//       },
//     );
//   }
// }
