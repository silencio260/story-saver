import '../../domain/entities/analytics_event.dart';

abstract class AnalyticsBaseRemoteDataSource {
  Future<void> initialize();

  Future<void> log(AnalyticsEventEntity event);
}
