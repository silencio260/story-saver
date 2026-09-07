import 'package:genrevibes_analytics/genrevibes_analytics.dart';

import '../../container_injector.dart';
import 'presentation/bloc/analytics_bloc/analytics_bloc.dart';

/// Registers the analytics presentation layer.
///
/// The data source, repository and use cases are gone: the starter kit's
/// pipeline is the analytics implementation now, and it is composed and
/// started by `bootstrapApp` before this runs. `registerRuntime` publishes it,
/// so the bloc resolves it here like any other dependency.
void initAnalytics() {
  sl.registerFactory(() => AnalyticsBloc(pipeline: sl<AnalyticsPipeline>()));
}
