import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../domain/entities/ad_reward.dart' as domain;
import '../../domain/entities/ad_unit.dart' as domain;
import '../../domain/repositories/ads_repository.dart';
import '../../../analytics/domain/entities/ad_revenue_event.dart';
import 'ads_remote_data_source.dart';

class AdMobAdsRemoteDataSource implements AdsRemoteDataSource {
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  AppOpenAd? _appOpenAd;

  bool _initialized = false;
  bool _nativeReady = false;
  void Function(AdRevenueEvent)? _onPaidEvent;
  void Function(String adType)? _onAdClick;

  @override
  void setOnPaidEventListener(void Function(AdRevenueEvent) listener) {
    _onPaidEvent = listener;
  }

  @override
  void setOnAdClickListener(void Function(String adType) listener) {
    _onAdClick = listener;
  }

  @override
  Future<void> initialize(AdsConfig config) async {
    if (config.testDeviceIds.isNotEmpty) {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: config.testDeviceIds),
      );
    }
    await MobileAds.instance.initialize();
    _initialized = true;
  }

  void _recordAdClick(String format) {
    _onAdClick?.call(format);
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('AdMob has not been initialized');
    }
  }

  void _recordPaidEvent({
    required Ad ad,
    required double valueMicros,
    required String currencyCode,
    required String format,
  }) {
    _onPaidEvent?.call(
      AdRevenueEvent(
        value: valueMicros / 1000000.0,
        valueMicros: valueMicros,
        currency: currencyCode,
        adSource: 'AdMob',
        adNetwork: 'AdMob',
        adUnitId: ad.adUnitId,
        adFormat: format,
      ),
    );
  }

  @override
  Future<domain.AdUnit> loadBanner(String adUnitId) async {
    _ensureInitialized();
    return domain.AdUnit(id: adUnitId, type: domain.AdType.banner);
  }

  @override
  Future<domain.AdUnit> loadInterstitial(String adUnitId) {
    _ensureInitialized();
    final completer = Completer<domain.AdUnit>();
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd?.dispose();
          _interstitialAd = ad;
          ad.onPaidEvent = (ad, valueMicros, _, currencyCode) {
            _recordPaidEvent(
              ad: ad,
              valueMicros: valueMicros,
              currencyCode: currencyCode,
              format: 'interstitial',
            );
          };
          if (!completer.isCompleted) {
            completer.complete(
              domain.AdUnit(
                id: adUnitId,
                type: domain.AdType.interstitial,
                isLoaded: true,
              ),
            );
          }
        },
        onAdFailedToLoad: (error) {
          if (!completer.isCompleted) {
            completer.completeError(StateError(error.message));
          }
        },
      ),
    );
    return completer.future;
  }

  @override
  Future<bool> showInterstitial() async {
    _ensureInitialized();
    final ad = _interstitialAd;
    if (ad == null) return false;
    _interstitialAd = null;
    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdDismissedFullScreenContent: (ad) => ad.dispose(),
      onAdFailedToShowFullScreenContent: (ad, _) => ad.dispose(),
      onAdClicked: (_) => _recordAdClick('interstitial'),
    );
    await ad.show();
    return true;
  }

  @override
  Future<domain.AdUnit> loadRewarded(String adUnitId) {
    _ensureInitialized();
    final completer = Completer<domain.AdUnit>();
    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd?.dispose();
          _rewardedAd = ad;
          ad.onPaidEvent = (ad, valueMicros, _, currencyCode) {
            _recordPaidEvent(
              ad: ad,
              valueMicros: valueMicros,
              currencyCode: currencyCode,
              format: 'rewarded',
            );
          };
          if (!completer.isCompleted) {
            completer.complete(
              domain.AdUnit(
                id: adUnitId,
                type: domain.AdType.rewarded,
                isLoaded: true,
              ),
            );
          }
        },
        onAdFailedToLoad: (error) {
          if (!completer.isCompleted) {
            completer.completeError(StateError(error.message));
          }
        },
      ),
    );
    return completer.future;
  }

  @override
  Future<domain.AdReward> showRewarded() async {
    _ensureInitialized();
    final ad = _rewardedAd;
    if (ad == null) return const domain.AdReward(type: 'none', amount: 0);
    _rewardedAd = null;
    final rewardCompleter = Completer<domain.AdReward>();
    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!rewardCompleter.isCompleted) {
          rewardCompleter.complete(
            const domain.AdReward(type: 'none', amount: 0),
          );
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        if (!rewardCompleter.isCompleted) {
          rewardCompleter.completeError(StateError(error.message));
        }
      },
      onAdClicked: (_) => _recordAdClick('rewarded'),
    );
    await ad.show(
      onUserEarnedReward: (_, reward) {
        if (!rewardCompleter.isCompleted) {
          rewardCompleter.complete(
            domain.AdReward(
              type: reward.type,
              amount: reward.amount.toInt(),
            ),
          );
        }
      },
    );
    return rewardCompleter.future.timeout(
      const Duration(seconds: 60),
      onTimeout: () => const domain.AdReward(type: 'none', amount: 0),
    );
  }

  @override
  Future<bool> isInterstitialReady() async => _interstitialAd != null;

  @override
  Future<bool> isRewardedReady() async => _rewardedAd != null;

  @override
  Future<domain.AdUnit> loadAppOpen(String adUnitId) {
    _ensureInitialized();
    final completer = Completer<domain.AdUnit>();
    AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd?.dispose();
          _appOpenAd = ad;
          ad.onPaidEvent = (ad, valueMicros, _, currencyCode) {
            _recordPaidEvent(
              ad: ad,
              valueMicros: valueMicros,
              currencyCode: currencyCode,
              format: 'app_open',
            );
          };
          if (!completer.isCompleted) {
            completer.complete(
              domain.AdUnit(
                id: adUnitId,
                type: domain.AdType.appOpen,
                isLoaded: true,
              ),
            );
          }
        },
        onAdFailedToLoad: (error) {
          if (!completer.isCompleted) {
            completer.completeError(StateError(error.message));
          }
        },
      ),
    );
    return completer.future;
  }

  @override
  Future<bool> showAppOpen() async {
    _ensureInitialized();
    final ad = _appOpenAd;
    if (ad == null) return false;
    _appOpenAd = null;
    ad.fullScreenContentCallback = FullScreenContentCallback<AppOpenAd>(
      onAdDismissedFullScreenContent: (ad) => ad.dispose(),
      onAdFailedToShowFullScreenContent: (ad, _) => ad.dispose(),
      onAdClicked: (_) => _recordAdClick('app_open'),
    );
    await ad.show();
    return true;
  }

  @override
  Future<bool> isAppOpenReady() async => _appOpenAd != null;

  @override
  Future<domain.AdUnit> loadNative(String adUnitId) async {
    _ensureInitialized();
    _nativeReady = true;
    return domain.AdUnit(
      id: adUnitId,
      type: domain.AdType.native,
      isLoaded: true,
    );
  }

  @override
  Future<bool> isNativeReady() async => _nativeReady;

  @override
  Future<void> dispose() async {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _appOpenAd?.dispose();
    _interstitialAd = null;
    _rewardedAd = null;
    _appOpenAd = null;
    _nativeReady = false;
  }
}
