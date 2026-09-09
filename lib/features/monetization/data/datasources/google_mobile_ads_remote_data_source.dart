import 'dart:async';

import 'package:genrevibes_ads/genrevibes_ads.dart';
import 'package:genrevibes_analytics/genrevibes_analytics.dart';
import 'package:genrevibes_remote_config/genrevibes_remote_config.dart';
import 'package:genrevibes_remote_policy/genrevibes_remote_policy.dart';
import 'package:genrevibes_starter_kit/genrevibes_starter_kit.dart';

import '../../../../bootstrap/app_env.dart';
import '../../../../container_injector.dart';
import '../services/subscription_service.dart';
import 'ads_base_remote_data_source.dart';

/// Interstitials, over the kit's [AdProvider].
///
/// Loading, the show lifecycle, paid callbacks and disposal are the provider's
/// job. What stays here is the part the kit deliberately has no opinion on:
/// when this app wants an interstitial, how long it waits before the first one,
/// and that a premium user never sees any.
///
/// The class name is kept because it names a role in this app's DI, not a
/// vendor — nothing in this file mentions Google any more, and swapping AdMob
/// for a mediation SDK is now a change at the composition root alone.
class GoogleMobileAdsRemoteDataSource implements AdsBaseRemoteDataSource {
  GoogleMobileAdsRemoteDataSource({
    required SubscriptionManager subscriptionManager,
    required AnalyticsPipeline analyticsRepo,
  })  : _subscriptionManager = subscriptionManager,
        _analyticsRepo = analyticsRepo;

  final SubscriptionManager _subscriptionManager;
  final AnalyticsPipeline _analyticsRepo;

  /// Ad pacing, from remote configuration with schema defaults as the floor.
  ///
  /// Read per use rather than cached, so a remote change takes effect without
  /// a restart. This replaces AdConfig, which snapshotted three values once at
  /// startup and never looked again.
  RemoteConfigSnapshot get _config => sl<RemoteConfigCoordinator>().current;

  AdProvider get _ads => sl<AdProvider>();

  StreamSubscription<AdEvent>? _events;
  bool _isLoading = false;
  bool _initialDelayApplied = false;
  bool _adsDisabled = false;

  @override
  Future<void> loadInterstitial() async {
    _adsDisabled = false;
    if (_isLoading || _ads.isReady(AppPlacements.interstitial)) return;

    // Consent and MobileAds.initialize() run after the first frame. An ad may
    // not be requested before consent has been gathered, so this waits for
    // them rather than the application waiting at launch.
    await sl<GenRevibesStarterKit>().deferredStartupComplete;

    await _subscriptionManager.initialize();
    if (_subscriptionManager.isPremium) return;

    _listenForPaidEvents();

    _isLoading = true;
    if (!_initialDelayApplied) {
      _initialDelayApplied = true;
      await Future<void>.delayed(
        Duration(
          seconds: _config.read(AdsPolicyKeys.timeBeforeFirstInterstitial),
        ),
      );
    }
    if (_adsDisabled || _subscriptionManager.isPremium) {
      _isLoading = false;
      return;
    }

    final result = await _ads.load(AppPlacements.interstitial);
    _isLoading = false;
    if (_adsDisabled || _subscriptionManager.isPremium) {
      await _ads.discard(AppPlacements.interstitial);
      return;
    }
    // The repository above still signals failure by throwing.
    result.fold(
      onSuccess: (_) {},
      onFailure: (error) => throw StateError(error.message),
    );
  }

  @override
  Future<bool> showInterstitial() async {
    if (_adsDisabled) return false;
    await _subscriptionManager.initialize();
    if (_subscriptionManager.isPremium) {
      await dispose();
      return false;
    }
    if (!_ads.isReady(AppPlacements.interstitial)) return false;

    final shown = await _ads.show(AppPlacements.interstitial);
    final displayed = shown.fold(
      onSuccess: (value) => value.wasShown,
      onFailure: (_) => false,
    );
    if (displayed) unawaited(_reloadAfterInterval());
    return displayed;
  }

  /// Mirrors provider paid events into analytics.
  ///
  /// Subscribed once and filtered by placement, because the provider reports
  /// every format on one stream.
  void _listenForPaidEvents() {
    _events ??= _ads.events.listen((event) {
      if (event.type != AdEventType.paid) return;
      if (event.placement != AppPlacements.interstitial) return;
      final revenue = event.revenue;
      if (revenue == null) return;
      unawaited(
        _analyticsRepo.track(
          AnalyticsEvent(
            name: 'ad_impression',
            properties: <String, Object>{
              'ad_unit_id': sl<AppEnv>().interstitialAdUnitId,
              'ad_format': event.placement.format.name,
              'value_micros': revenue.valueMicros,
              'currency': revenue.currencyCode,
            },
          ),
        ),
      );
    });
  }

  Future<void> _reloadAfterInterval() async {
    await Future<void>.delayed(
      Duration(seconds: _config.read(AdsPolicyKeys.minInterstitialInterval)),
    );
    try {
      await loadInterstitial();
    } on Object {
      // A later user action can retry loading without affecting the UI.
    }
  }

  @override
  Future<void> dispose() async {
    _adsDisabled = true;
    await _events?.cancel();
    _events = null;
    await _ads.discard(AppPlacements.interstitial);
  }
}
