import 'package:firebase_analytics/firebase_analytics.dart';

import '../../domain/entities/analytics_event.dart';
import '../services/firebase_analytics_service.dart';
import 'analytics_base_remote_data_source.dart';

export 'analytics_base_remote_data_source.dart';

class FirebaseAnalyticsRemoteDataSource
    implements AnalyticsBaseRemoteDataSource {
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    await AnalyticsService.init();
    _initialized = true;
  }

  @override
  Future<void> log(AnalyticsEventEntity event) => FirebaseAnalytics.instance
      .logEvent(name: event.name, parameters: event.parameters);
}
