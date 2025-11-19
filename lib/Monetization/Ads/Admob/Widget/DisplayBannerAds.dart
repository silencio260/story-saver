import 'package:flutter/cupertino.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:storysaver/Monetization/Ads/Admob/ad_helper.dart';
import 'package:storysaver/Monetization/SubscriptionManager.dart';
import 'package:storysaver/Services/analytics_service.dart';

class DisplayBannerAdWidget extends StatefulWidget {
  const DisplayBannerAdWidget({Key? key}) : super(key: key);

  @override
  _DisplayBannerAdWidgetState createState() => _DisplayBannerAdWidgetState();
}

class _DisplayBannerAdWidgetState extends State<DisplayBannerAdWidget> {
  late final BannerAd _bannerAd;
  bool _isAdLoaded = false;
  bool _shouldRetryFailedBannerAdRequest = false;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _checkSubscriptionAndLoadAd();
  }

  Future<void> _checkSubscriptionAndLoadAd() async {
    // Check if user is premium
    await SubscriptionManager().initialize();
    _isPremium = SubscriptionManager().isPremium;

    if (!_isPremium) {
      // Only load ad if user is not premium
      _loadBannerAd();
    } else {
      print('DisplayBannerAdWidget: User is premium, skipping ad load');
    }
  }

  void _resetBannerAdValues() {
    // _bannerAd.dispose();
    _isAdLoaded = false;
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onPaidEvent: (ad, valueMicros, precision, currencyCode) {
          AnalyticsService().logAdImpressions(
            adUnitId: ad.adUnitId,
            adFormat: 'banner',
            valueMicros: valueMicros,
            currency: currencyCode,
          );
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _resetBannerAdValues();
          _shouldRetryFailedBannerAdRequest = true;
          print('_loadBannerAd: Failed to load banner ads ${error}');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    // Only dispose if ad was actually loaded (not premium user)
    if (!_isPremium && _isAdLoaded) {
      _bannerAd.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Return empty widget for premium users
    if (_isPremium) {
      return const SizedBox();
    }

    // print('banner banner banner');
    if (_shouldRetryFailedBannerAdRequest == true) {
      _shouldRetryFailedBannerAdRequest = false;
      Future.delayed(Duration(seconds: 2), () {
        _loadBannerAd();
        print('_shouldRetryFailedBannerAdRequest');
      });
    }

    if (!_isAdLoaded) {
      return const SizedBox();
    }

    return SizedBox(
      width: _bannerAd.size.width.toDouble(),
      height: _bannerAd.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd),
    );
  }
}
