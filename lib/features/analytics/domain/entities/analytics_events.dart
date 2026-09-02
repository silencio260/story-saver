import 'analytics_event.dart';

class AnalyticsEvents {
  const AnalyticsEvents._();

  static const AnalyticsEventEntity appOpen = AnalyticsEventEntity(
    name: 'app_open',
  );
  static const AnalyticsEventEntity splashViewed = AnalyticsEventEntity(
    name: 'splash_viewed',
  );
  static const AnalyticsEventEntity homeViewed = AnalyticsEventEntity(
    name: 'home_viewed',
  );
}
