import '../../domain/entities/ad_reward.dart';
import '../../domain/entities/ad_unit.dart';
import '../../domain/repositories/ads_repository.dart';
import '../../../analytics/domain/entities/ad_revenue_event.dart';

/// Abstract data source for Ad operations
///
/// Implement this interface for different ad mediators:
/// - AdMobDataSource
/// - AppLovinMaxDataSource
/// - IronSourceDataSource
abstract class AdsRemoteDataSource {
  /// Set callback for ad revenue events
  void setOnPaidEventListener(void Function(AdRevenueEvent) listener);

  /// Set callback for ad click events.
  void setOnAdClickListener(void Function(String adType) listener);

  /// Initialize the ads SDK
  Future<void> initialize(AdsConfig config);

  /// Load a banner ad
  Future<AdUnit> loadBanner(String adUnitId);

  /// Load an interstitial ad
  Future<AdUnit> loadInterstitial(String adUnitId);

  /// Show an interstitial ad
  Future<bool> showInterstitial();

  /// Load a rewarded ad
  Future<AdUnit> loadRewarded(String adUnitId);

  /// Show a rewarded ad
  Future<AdReward> showRewarded();

  /// Check if interstitial is ready
  Future<bool> isInterstitialReady();

  /// Check if rewarded is ready
  Future<bool> isRewardedReady();

  /// Load an app open ad
  Future<AdUnit> loadAppOpen(String adUnitId);

  /// Show an app open ad
  Future<bool> showAppOpen();

  /// Check if app open ad is ready
  Future<bool> isAppOpenReady();

  /// Load a native ad
  Future<AdUnit> loadNative(String adUnitId);

  /// Check if native ad is ready
  Future<bool> isNativeReady();

  /// Dispose all ads
  Future<void> dispose();
}
