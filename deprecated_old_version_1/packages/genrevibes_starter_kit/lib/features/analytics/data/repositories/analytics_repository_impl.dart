import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/ad_revenue_event.dart';
import '../../domain/entities/analytics_event.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../datasources/analytics_remote_data_source.dart';
import '../datasources/posthog_remote_data_source.dart';
import '../datasources/mixpanel_remote_data_source.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final AnalyticsRemoteDataSource remoteDataSource;
  final PostHogRemoteDataSource? postHogDataSource;
  final MixpanelRemoteDataSource? mixpanelDataSource;

  AnalyticsRepositoryImpl({
    required this.remoteDataSource,
    this.postHogDataSource,
    this.mixpanelDataSource,
  });

  @override
  Future<Either<Failure, void>> initialize() async {
    try {
      await remoteDataSource.initialize();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logEvent(AnalyticsEvent event) async {
    try {
      await remoteDataSource.logEvent(event);
      await postHogDataSource?.capture(
        eventName: event.name,
        properties: event.parameters,
      );
      await mixpanelDataSource?.capture(
        eventName: event.name,
        properties: event.parameters,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logAdRevenue(AdRevenueEvent event) async {
    try {
      // Firebase stays the canonical ad-revenue path (logAdImpression). PostHog
      // is intentionally skipped, but Mixpanel gets it as an `ad_revenue` event
      // so revenue shows up in Mixpanel funnels.
      await remoteDataSource.logAdRevenue(event);
      await mixpanelDataSource?.logAdRevenue(event);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setUserId(String userId) async {
    try {
      await remoteDataSource.setUserId(userId);
      await postHogDataSource?.identify(userId: userId);
      await mixpanelDataSource?.identify(userId: userId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setUserProperty(
    String name,
    String value,
  ) async {
    try {
      await remoteDataSource.setUserProperty(name, value);
      // Intentionally NOT forwarding to PostHog here: identify() with an empty
      // distinct-id is invalid and can mis-merge users. PostHog user properties
      // are attached via the real identify() call in setUserId().
      // Mixpanel is safe: getPeople().set() targets the current distinct-id, so
      // forward profile properties for Mixpanel cohorts.
      await mixpanelDataSource?.setUserProperty(name, value);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logScreenView(String screenName) async {
    try {
      await remoteDataSource.logScreenView(screenName);
      await postHogDataSource?.screen(screenName: screenName);
      await mixpanelDataSource?.screen(screenName: screenName);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logRetentionEvent(
    String eventName,
    Map<String, dynamic> parameters,
  ) async {
    try {
      await remoteDataSource.logRetentionEvent(eventName, parameters);
      await postHogDataSource?.capture(
        eventName: eventName,
        properties: parameters,
      );
      await mixpanelDataSource?.capture(
        eventName: eventName,
        properties: parameters,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logUserSegmentEvent(
    String eventName,
    Map<String, dynamic> parameters,
  ) async {
    try {
      await remoteDataSource.logUserSegmentEvent(eventName, parameters);
      await postHogDataSource?.capture(
        eventName: eventName,
        properties: parameters,
      );
      await mixpanelDataSource?.capture(
        eventName: eventName,
        properties: parameters,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logTargetingEvent(
    String eventName,
    Map<String, dynamic> parameters,
  ) async {
    try {
      await remoteDataSource.logTargetingEvent(eventName, parameters);
      await postHogDataSource?.capture(
        eventName: eventName,
        properties: parameters,
      );
      await mixpanelDataSource?.capture(
        eventName: eventName,
        properties: parameters,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> recordFlutterError(
    dynamic error,
    dynamic stack, {
    bool fatal = false,
  }) async {
    try {
      await remoteDataSource.recordFlutterError(error, stack, fatal: fatal);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> recordError(
    dynamic error,
    dynamic stack, {
    bool fatal = false,
  }) async {
    try {
      await remoteDataSource.recordError(error, stack, fatal: fatal);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
