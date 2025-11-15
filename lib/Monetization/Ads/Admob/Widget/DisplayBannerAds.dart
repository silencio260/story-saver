import 'package:flutter/cupertino.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:storysaver/Monetization/Ads/Admob/ad_helper.dart';
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

  @override
  void initState() {
    super.initState();
    // print('init state load banner');
    _loadBannerAd();
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
    _bannerAd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
