import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/analytics_event.dart';
import '../entities/ad_revenue_event.dart';

/// Abstract repository for analytics operations
abstract class AnalyticsRepository {
  /// Initialize analytics services
  Future<Either<Failure, void>> initialize();

  /// Log a custom event
  Future<Either<Failure, void>> logEvent(AnalyticsEvent event);

  /// Log ad revenue
  Future<Either<Failure, void>> logAdRevenue(AdRevenueEvent event);

  /// Set user ID
  Future<Either<Failure, void>> setUserId(String userId);

  /// Set user property
  Future<Either<Failure, void>> setUserProperty(String name, String value);

  /// Track screen view
  Future<Either<Failure, void>> logScreenView(String screenName);

  // Status Saver Specialized Events
  Future<Either<Failure, void>> logRetentionEvent(
    String eventName,
    Map<String, dynamic> parameters,
  );
  Future<Either<Failure, void>> logUserSegmentEvent(
    String eventName,
    Map<String, dynamic> parameters,
  );
  Future<Either<Failure, void>> logTargetingEvent(
    String eventName,
    Map<String, dynamic> parameters,
  );

  // Crashlytics
  Future<Either<Failure, void>> recordFlutterError(
    dynamic error,
    dynamic stack, {
    bool fatal = false,
  });
  Future<Either<Failure, void>> recordError(
    dynamic error,
    dynamic stack, {
    bool fatal = false,
  });
}
