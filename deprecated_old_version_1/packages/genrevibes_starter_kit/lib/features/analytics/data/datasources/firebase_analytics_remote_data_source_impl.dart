import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/ad_revenue_event.dart';
import '../../domain/entities/analytics_event.dart';
import 'analytics_remote_data_source.dart';

class FirebaseAnalyticsRemoteDataSourceImpl
    implements AnalyticsRemoteDataSource {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  @override
  Future<void> initialize() async {
    // Firebase initialization is handled at the app level
  }

  @override
  Future<void> logEvent(AnalyticsEvent event) async {
    await _analytics.logEvent(
      name: event.name,
      parameters: event.parameters.cast<String, Object>(),
    );
  }

  @override
  Future<void> logAdRevenue(AdRevenueEvent event) async {
    await _analytics.logAdImpression(
      adPlatform: event.adSource,
      adSource: event.adNetwork,
      adFormat: event.adFormat,
      adUnitName: event.adUnitId,
      value: event.value,
      currency: event.currency,
    );
  }

  @override
  Future<void> setUserId(String userId) async {
    await _analytics.setUserId(id: userId);
    await _crashlytics.setUserIdentifier(userId);
  }

  @override
  Future<void> setUserProperty(String name, String value) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  @override
  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  @override
  Future<void> logRetentionEvent(
    String eventName,
    Map<String, dynamic> parameters,
  ) async {
    await _analytics.logEvent(
      name: eventName,
      parameters: parameters.cast<String, Object>(),
    );
  }

  @override
  Future<void> logUserSegmentEvent(
    String eventName,
    Map<String, dynamic> parameters,
  ) async {
    await _analytics.logEvent(
      name: eventName,
      parameters: parameters.cast<String, Object>(),
    );
  }

  @override
  Future<void> logTargetingEvent(
    String eventName,
    Map<String, dynamic> parameters,
  ) async {
    await _analytics.logEvent(
      name: eventName,
      parameters: parameters.cast<String, Object>(),
    );
  }

  @override
  Future<void> recordFlutterError(
    dynamic error,
    dynamic stack, {
    bool fatal = false,
  }) async {
    await _crashlytics.recordFlutterError(
      FlutterErrorDetails(
        exception: error,
        stack: stack is StackTrace ? stack : StackTrace.current,
      ),
      fatal: fatal,
    );
  }

  @override
  Future<void> recordError(
    dynamic error,
    dynamic stack, {
    bool fatal = false,
  }) async {
    await _crashlytics.recordError(error, stack, fatal: fatal);
  }
}
