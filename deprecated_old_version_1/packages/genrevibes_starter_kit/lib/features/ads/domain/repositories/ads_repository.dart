import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/ad_reward.dart';
import '../entities/ad_unit.dart';
import '../../../analytics/domain/entities/ad_revenue_event.dart';

/// Configuration for the ads service
class AdsConfig {
  final String? bannerAdUnitId;
  final String? interstitialAdUnitId;
  final String? rewardedAdUnitId;
  final String? nativeAdUnitId;
  final String? appOpenAdUnitId;
  final List<String> testDeviceIds;

  // Remote Controls (Time-based intervals in seconds)
  final int minInterstitialInterval;
  final int minRewardedInterval;
  final int minNativeInterval;
  final int minAppOpenInterval;
  final int minBannerInterval;
  final bool shouldShowAppOpenAd;
  final int timeBeforeFirstInstaAd;
  final int timeBeforeFirstRewardedAd;

  const AdsConfig({
    this.bannerAdUnitId,
    this.interstitialAdUnitId,
    this.rewardedAdUnitId,
    this.nativeAdUnitId,
    this.appOpenAdUnitId,
    this.testDeviceIds = const [],
    this.minInterstitialInterval = 0,
    this.minRewardedInterval = 0,
    this.minNativeInterval = 0,
    this.minAppOpenInterval = 0,
    this.minBannerInterval = 0,
    this.shouldShowAppOpenAd = true,
    this.timeBeforeFirstInstaAd = 0,
    this.timeBeforeFirstRewardedAd = 0,
  });
}

/// Abstract repository for Ad operations
///
/// Implement this with different ad mediators:
/// - AdMobRepository
/// - AppLovinRepository (MAX)
/// - IronSourceRepository
/// - UnityAdsRepository
abstract class AdsRepository {
  /// Set callback for ad revenue events
  void setOnPaidEventListener(void Function(AdRevenueEvent) listener);

  /// Set callback for ad click events.
  void setOnAdClickListener(void Function(String adType) listener);

  /// Record ad revenue from an ad
  void recordAdRevenue(AdRevenueEvent event);

  /// Record an ad click from an ad surface.
  void recordAdClick(String adType);

  /// Initialize the ads SDK
  Future<Either<Failure, void>> initialize(AdsConfig config);

  /// Load a banner ad
  Future<Either<Failure, AdUnit>> loadBanner(String adUnitId);

  /// Load an interstitial ad
  Future<Either<Failure, AdUnit>> loadInterstitial(String adUnitId);

  /// Show an interstitial ad
  Future<Either<Failure, bool>> showInterstitial();

  /// Load a rewarded ad
  Future<Either<Failure, AdUnit>> loadRewarded(String adUnitId);

  /// Show a rewarded ad and return the reward
  Future<Either<Failure, AdReward>> showRewarded();

  /// Check if interstitial is ready
  Future<Either<Failure, bool>> isInterstitialReady();

  /// Check if rewarded is ready
  Future<Either<Failure, bool>> isRewardedReady();

  /// Load an app open ad
  Future<Either<Failure, AdUnit>> loadAppOpen(String adUnitId);

  /// Show an app open ad
  Future<Either<Failure, bool>> showAppOpen();

  /// Check if app open ad is ready
  Future<Either<Failure, bool>> isAppOpenReady();

  /// Load a native ad
  Future<Either<Failure, AdUnit>> loadNative(String adUnitId);

  /// Check if native ad is ready
  Future<Either<Failure, bool>> isNativeReady();

  /// Dispose all ads
  Future<Either<Failure, void>> dispose();
}
