

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

  @override
  void initState() {
    super.initState();

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
