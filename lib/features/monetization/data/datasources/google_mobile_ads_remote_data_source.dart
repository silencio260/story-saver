import 'dart:async';

import 'package:genrevibes_ads/genrevibes_ads.dart';
import 'package:genrevibes_developer_access/genrevibes_developer_access.dart';
import 'package:genrevibes_remote_config/genrevibes_remote_config.dart';
import 'package:genrevibes_remote_policy/genrevibes_remote_policy.dart';
import 'package:genrevibes_starter_kit/genrevibes_starter_kit.dart';

import '../../../../bootstrap/app_env.dart';
import '../../../../container_injector.dart';
import '../services/subscription_service.dart';
import 'ads_base_remote_data_source.dart';

/// Interstitials, over the kit's [AdProvider].
///
/// Loading, the show lifecycle and revenue events are the provider's job, and
/// revenue reaches analytics from its event stream in bootstrap. What stays
/// here is the part the kit deliberately has no opinion on: when this app
/// wants an interstitial, how long it waits before the first one, and that a
/// premium user never sees any.
///
/// The class name is kept because it names a role in this app's DI, not a
/// vendor — nothing in this file mentions one, and the move from AdMob to
/// Appodeal changed only the composition root.
class GoogleMobileAdsRemoteDataSource implements AdsBaseRemoteDataSource {
  GoogleMobileAdsRemoteDataSource({
    required SubscriptionManager subscriptionManager,
  }) : _subscriptionManager = subscriptionManager;

  final SubscriptionManager _subscriptionManager;

  /// Ad pacing, from remote configuration with schema defaults as the floor.
  ///
  /// Read per use rather than cached, so a remote change takes effect without
  /// a restart. This replaces AdConfig, which snapshotted three values once at
  /// startup and never looked again.
  RemoteConfigSnapshot get _config => sl<RemoteConfigCoordinator>().current;

  AdProvider get _ads => sl<AdProvider>();

  /// False when a developer turned interstitials off in the Starter Kit Lab.
  bool get _developerAllows =>
      sl<DeveloperAdSwitches>().allows(AdFormat.interstitial);

  bool _isLoading = false;
  bool _initialDelayApplied = false;
  bool _adsDisabled = false;

  Timer? _retryTimer;
  int _loadGeneration = 0;

  bool get _mayLoad =>
      !_adsDisabled &&
      _developerAllows &&
      _subscriptionManager.adsAllowed &&
      _config.read(AdsPolicyKeys.adsEnabled);

  void _scheduleRetry() {
    if (!_mayLoad || _retryTimer != null) return;
    _retryTimer = Timer(Duration.zero, () {
      _retryTimer = null;
      if (!_mayLoad || _ads.isReady(AppPlacements.interstitial)) return;
      unawaited(_retryLoad());
    });
  }

  Future<void> _retryLoad() async {
    try {
      await loadInterstitial();
    } on Object {
      // loadInterstitial has scheduled the next eligible attempt.
    }
  }

  @override
  Future<void> loadInterstitial() async {
    if (!_developerAllows || _isLoading) return;
    _isLoading = true;
    _adsDisabled = false;
    _retryTimer?.cancel();
    _retryTimer = null;
    final generation = _loadGeneration;
    try {
      await _subscriptionManager.initialize();
      if (generation != _loadGeneration || !_mayLoad) return;
      if (_ads.isReady(AppPlacements.interstitial)) return;

      // Consent and SDK startup must finish before requesting inventory.
      await sl<GenRevibesStarterKit>().deferredStartupComplete;
      if (generation != _loadGeneration || !_mayLoad) return;
      if (!_initialDelayApplied) {
        _initialDelayApplied = true;
        await Future<void>.delayed(
          Duration(
            seconds: _config.read(AdsPolicyKeys.timeBeforeFirstInterstitial),
          ),
        );
      }
      if (generation != _loadGeneration || !_mayLoad) return;
      final result = await _ads.load(AppPlacements.interstitial);
      if (generation != _loadGeneration || !_mayLoad) {
        await _ads.discard(AppPlacements.interstitial);
        return;
      }
      result.fold(
        onSuccess: (_) {
          if (!_ads.isReady(AppPlacements.interstitial)) _scheduleRetry();
        },
        onFailure: (error) => throw StateError(error.message),
      );
    } on Object {
      if (generation == _loadGeneration) _scheduleRetry();
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  @override
  Future<bool> showInterstitial() async {
    if (_adsDisabled || !_developerAllows) return false;
    await _subscriptionManager.initialize();
    if (!_subscriptionManager.adsAllowed) {
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

  Future<void> _reloadAfterInterval() async {
    await Future<void>.delayed(
      Duration(seconds: _config.read(AdsPolicyKeys.minInterstitialInterval)),
    );
    if (_adsDisabled || !_subscriptionManager.adsAllowed) return;
    try {
      await loadInterstitial();
    } on Object {
      // Failed loads schedule their next eligible attempt automatically.
    }
  }

  @override
  Future<void> dispose() async {
    _adsDisabled = true;
    _loadGeneration++;
    _retryTimer?.cancel();
    _retryTimer = null;
    await _ads.discard(AppPlacements.interstitial);
  }
}
