import '../../domain/entities/analytics_event.dart';
import '../../domain/entities/ad_revenue_event.dart';

/// Abstract data source for analytics providers
abstract class AnalyticsRemoteDataSource {
  Future<void> initialize();
  Future<void> logEvent(AnalyticsEvent event);
  Future<void> logAdRevenue(AdRevenueEvent event);
  Future<void> setUserId(String userId);
  Future<void> setUserProperty(String name, String value);
  Future<void> logScreenView(String screenName);

  // Status Saver Specialized Events
  Future<void> logRetentionEvent(
    String eventName,
    Map<String, dynamic> parameters,
  );
  Future<void> logUserSegmentEvent(
    String eventName,
    Map<String, dynamic> parameters,
  );
  Future<void> logTargetingEvent(
    String eventName,
    Map<String, dynamic> parameters,
  );

  // Crashlytics
  Future<void> recordFlutterError(
    dynamic error,
    dynamic stack, {
    bool fatal = false,
  });
  Future<void> recordError(dynamic error, dynamic stack, {bool fatal = false});
}
