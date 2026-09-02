import 'package:posthog_flutter/posthog_flutter.dart';
import '../../domain/entities/ad_revenue_event.dart';

/// Interface for PostHog Analytics
abstract class PostHogRemoteDataSource {
  Future<void> initialize({required String apiKey, required String host});
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
  Future<void> reset();
}

/// Implementation of PostHog Analytics
class PostHogRemoteDataSourceImpl implements PostHogRemoteDataSource {
  final Posthog _posthog = Posthog();
  bool _isInitialized = false;

  @override
  Future<void> initialize({
    required String apiKey,
    required String host,
  }) async {
    if (_isInitialized) return;
    try {
      final config = PostHogConfig(apiKey)..host = host;
      await _posthog.setup(config);
      _isInitialized = true;
    } catch (_) {
      // Leave _isInitialized false so capture/identify/screen stay no-ops
      // rather than throwing on every call after a failed setup.
      _isInitialized = false;
    }
  }

  @override
  Future<void> capture({
    required String eventName,
    Map<String, dynamic>? properties,
  }) async {
    if (!_isInitialized) return;
    await _posthog.capture(
      eventName: eventName,
      properties: properties?.cast<String, Object>(),
    );
  }

  @override
  Future<void> logAdRevenue(AdRevenueEvent event) async {
    if (!_isInitialized) return;
    await _posthog.capture(
      eventName: 'ad_revenue',
      properties: {
        'value': event.value,
        'currency': event.currency,
        'ad_source': event.adSource,
        'ad_unit_id': event.adUnitId,
        'ad_format': event.adFormat,
        'ad_network': event.adNetwork,
      }.map((key, value) => MapEntry(key, value as Object)),
    );
  }

  @override
  Future<void> screen({
    required String screenName,
    Map<String, dynamic>? properties,
  }) async {
    if (!_isInitialized) return;
    await _posthog.screen(
      screenName: screenName,
      properties: properties?.cast<String, Object>(),
    );
  }

  @override
  Future<void> identify({
    required String userId,
    Map<String, dynamic>? userProperties,
  }) async {
    if (!_isInitialized) return;
    await _posthog.identify(
      userId: userId,
      userProperties: userProperties?.cast<String, Object>(),
    );
  }

  @override
  Future<void> reset() async {
    if (!_isInitialized) return;
    await _posthog.reset();
  }
}
