import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:mixpanel_flutter_session_replay/mixpanel_flutter_session_replay.dart';

import '../../domain/entities/ad_revenue_event.dart';

/// Interface for Mixpanel Analytics (events + people + session replay).
///
/// Mirrors [PostHogRemoteDataSource] so [AnalyticsRepositoryImpl] can fan out to
/// both providers with identical calls. Adds session-replay lifecycle controls
/// ([startReplay]/[stopReplay]) and exposes the live [sessionReplay] instance so
/// a root widget can mount [MixpanelSessionReplayWidget].
abstract class MixpanelRemoteDataSource {
  /// Initialize Mixpanel + Session Replay.
  ///
  /// [distinctId] seeds session replay (and Mixpanel's anonymous id). Pass the
  /// app's anonymous install UUID. Replay masks text/images by default.
  Future<void> initialize({
    required String token,
    required String distinctId,
    bool optOutTrackingDefault = false,
    bool maskAllText = true,
    bool maskAllImages = true,
    double sessionsPercent = 100.0,
    bool wifiOnly = false,
    bool enableSessionReplay = true,
  });

  Future<void> capture({
    required String eventName,
    Map<String, dynamic>? properties,
  });
  Future<void> logAdRevenue(AdRevenueEvent event);
  Future<void> screen({
    required String screenName,
    Map<String, dynamic>? properties,
  });
  Future<void> identify({
    required String userId,
    Map<String, dynamic>? userProperties,
  });
  Future<void> setUserProperty(String name, String value);
  Future<void> reset();

  /// Resume session-replay recording (e.g. on leaving a secure mini-app).
  void startReplay();

  /// Hard-stop session-replay recording (e.g. inside Vault / App Lock /
  /// App Hider / File Locker — private content regardless of masking).
  void stopReplay();

  /// The live session-replay instance, or `null` before init / on failure.
  /// Mount via `MixpanelSessionReplayWidget(instance: ..., child: ...)`.
  MixpanelSessionReplay? get sessionReplay;
}

/// Implementation of Mixpanel Analytics.
class MixpanelRemoteDataSourceImpl implements MixpanelRemoteDataSource {
  Mixpanel? _mixpanel;
  MixpanelSessionReplay? _sessionReplay;
  bool _isInitialized = false;

  @override
  MixpanelSessionReplay? get sessionReplay => _sessionReplay;

  @override
  Future<void> initialize({
    required String token,
    required String distinctId,
    bool optOutTrackingDefault = false,
    bool maskAllText = true,
    bool maskAllImages = true,
    double sessionsPercent = 100.0,
    bool wifiOnly = false,
    bool enableSessionReplay = true,
  }) async {
    if (_isInitialized) return;
    if (token.isEmpty) return;
    try {
      // Events SDK. trackAutomaticEvents:false — we instrument explicitly.
      _mixpanel = await Mixpanel.init(
        token,
        trackAutomaticEvents: false,
        optOutTrackingDefault: optOutTrackingDefault,
      );

      // Session replay. Skipped entirely when disabled (e.g. dev/debug builds),
      // so no recorder is created and [sessionReplay] stays null — the events
      // SDK above still works. autoMaskedViews drives global text/image masking.
      if (enableSessionReplay) {
        final masked = <AutoMaskedView>{
          if (maskAllText) AutoMaskedView.text,
          if (maskAllImages) AutoMaskedView.image,
        };
        final result = await MixpanelSessionReplay.initialize(
          token: token,
          distinctId: distinctId,
          options: SessionReplayOptions(
            autoMaskedViews: masked,
            autoRecordSessionsPercent: sessionsPercent,
            platformOptions: PlatformOptions(
              mobile: MobileOptions(wifiOnly: wifiOnly),
            ),
          ),
        );
        if (result.success) {
          _sessionReplay = result.instance;
        }
      }

      _isInitialized = true;
    } catch (_) {
      // Leave _isInitialized false so every method below stays a safe no-op
      // rather than throwing on each call after a failed setup.
      _isInitialized = false;
    }
  }

  @override
  Future<void> capture({
    required String eventName,
    Map<String, dynamic>? properties,
  }) async {
    if (!_isInitialized) return;
    await _mixpanel?.track(eventName, properties: properties);
  }

  @override
  Future<void> logAdRevenue(AdRevenueEvent event) async {
    if (!_isInitialized) return;
    await _mixpanel?.track('ad_revenue', properties: {
      'value': event.value,
      'currency': event.currency,
      'ad_source': event.adSource,
      'ad_unit_id': event.adUnitId,
      'ad_format': event.adFormat,
      'ad_network': event.adNetwork,
    });
  }

  @override
  Future<void> screen({
    required String screenName,
    Map<String, dynamic>? properties,
  }) async {
    if (!_isInitialized) return;
    // Mixpanel has no native screen call; model it as a normal event.
    await _mixpanel?.track('screen_view', properties: {
      'screen_name': screenName,
      ...?properties,
    });
  }

  @override
  Future<void> identify({
    required String userId,
    Map<String, dynamic>? userProperties,
  }) async {
    if (!_isInitialized) return;
    await _mixpanel?.identify(userId);
    if (userProperties != null) {
      final people = _mixpanel?.getPeople();
      userProperties.forEach((key, value) => people?.set(key, value));
    }
  }

  @override
  Future<void> setUserProperty(String name, String value) async {
    if (!_isInitialized) return;
    _mixpanel?.getPeople().set(name, value);
  }

  @override
  Future<void> reset() async {
    if (!_isInitialized) return;
    _sessionReplay?.stopRecording();
    await _mixpanel?.reset();
  }

  @override
  void startReplay() {
    if (!_isInitialized) return;
    _sessionReplay?.startRecording();
  }

  @override
  void stopReplay() {
    if (!_isInitialized) return;
    _sessionReplay?.stopRecording();
  }
}
