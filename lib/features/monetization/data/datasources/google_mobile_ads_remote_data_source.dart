import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../analytics/domain/entities/analytics_event.dart';
import '../../../analytics/domain/repositories/analytics_repository.dart';
import '../services/ads/ad_config.dart';
import '../../../../config/ad_unit_ids.dart';
import '../services/subscription_service.dart';
import 'ads_base_remote_data_source.dart';

class GoogleMobileAdsRemoteDataSource implements AdsBaseRemoteDataSource {
  GoogleMobileAdsRemoteDataSource({
    required SubscriptionManager subscriptionManager,
    required AnalyticsBaseRepo analyticsRepo,
  }) : _subscriptionManager = subscriptionManager,
       _analyticsRepo = analyticsRepo;

  final SubscriptionManager _subscriptionManager;
  final AnalyticsBaseRepo _analyticsRepo;

  InterstitialAd? _interstitialAd;
  bool _isLoading = false;
  bool _initialDelayApplied = false;
  bool _adsDisabled = false;

  @override
  Future<void> loadInterstitial() async {
    _adsDisabled = false;
    if (_interstitialAd != null ||
        _isLoading ||
        AdUnitIds.interstitial.isEmpty) {
      return;
    }

    await _subscriptionManager.initialize();
    if (_subscriptionManager.isPremium) return;

    _isLoading = true;
    if (!_initialDelayApplied) {
      _initialDelayApplied = true;
      await Future<void>.delayed(
        Duration(seconds: AdConfig.timeBeforeFirstInterstitialAd),
      );
    }
    if (_adsDisabled || _subscriptionManager.isPremium) {
      _isLoading = false;
      return;
    }
    final completer = Completer<void>();
    try {
      await InterstitialAd.load(
        adUnitId: AdUnitIds.interstitial,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _isLoading = false;
            if (_adsDisabled || _subscriptionManager.isPremium) {
              unawaited(ad.dispose());
            } else {
              _interstitialAd = ad;
              ad.onPaidEvent = _logPaidEvent;
            }
            completer.complete();
          },
          onAdFailedToLoad: (error) {
            _isLoading = false;
            completer.completeError(error);
          },
        ),
      );
      await completer.future;
    } on Object {
      _isLoading = false;
      rethrow;
    }
  }

  @override
  Future<bool> showInterstitial() async {
    if (_adsDisabled) return false;
    await _subscriptionManager.initialize();
    if (_subscriptionManager.isPremium) {
      await dispose();
      return false;
    }

    final ad = _interstitialAd;
    if (ad == null) return false;

    _interstitialAd = null;
    final completer = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (shownAd) {
        unawaited(shownAd.dispose());
        completer.complete();
      },
      onAdFailedToShowFullScreenContent: (shownAd, error) {
        unawaited(shownAd.dispose());
        completer.completeError(error);
      },
    );
    await ad.show();
    await completer.future;
    unawaited(_reloadAfterInterval());
    return true;
  }

  Future<void> _reloadAfterInterval() async {
    await Future<void>.delayed(
      Duration(seconds: AdConfig.minInterstitialAdInterval),
    );
    try {
      await loadInterstitial();
    } on Object {
      // A later user action can retry loading without affecting the UI.
    }
  }

  void _logPaidEvent(
    Ad ad,
    double valueMicros,
    PrecisionType precision,
    String currencyCode,
  ) {
    unawaited(
      _analyticsRepo.log(
        AnalyticsEventEntity(
          name: 'ad_impression',
          parameters: <String, Object>{
            'ad_unit_id': ad.adUnitId,
            'ad_format': 'interstitial',
            'value_micros': valueMicros,
            'currency': currencyCode,
          },
        ),
      ),
    );
  }

  @override
  Future<void> dispose() async {
    _adsDisabled = true;
    await _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}
