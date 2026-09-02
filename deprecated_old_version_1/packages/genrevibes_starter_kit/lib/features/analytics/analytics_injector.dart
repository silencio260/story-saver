import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import 'domain/repositories/analytics_repository.dart';
import 'data/datasources/posthog_remote_data_source.dart';
import 'data/datasources/mixpanel_remote_data_source.dart';
import 'domain/usecases/log_event_usecase.dart';
import 'domain/usecases/log_ad_revenue_usecase.dart';
import 'presentation/bloc/analytics_bloc.dart';

import 'data/datasources/firebase_analytics_remote_data_source_impl.dart';
import 'data/datasources/analytics_remote_data_source.dart';
import 'data/repositories/analytics_repository_impl.dart';

void initAnalyticsFeature(
  GetIt sl, {
  AnalyticsRepository? analyticsRepository,
  PostHogRemoteDataSource? postHogRemoteDataSource,
  MixpanelRemoteDataSource? mixpanelRemoteDataSource,
}) {
  if (kDebugMode) {
    print('[AnalyticsInjector] Initializing for sl: ${sl.hashCode}');
  }
  // PostHog (Standalone datasource first)
  if (postHogRemoteDataSource != null) {
    if (!sl.isRegistered<PostHogRemoteDataSource>()) {
      sl.registerLazySingleton<PostHogRemoteDataSource>(
        () => postHogRemoteDataSource,
      );
    }
  } else {
    // We register it anyway but it might not be initialized with an API key
    if (!sl.isRegistered<PostHogRemoteDataSource>()) {
      sl.registerLazySingleton<PostHogRemoteDataSource>(
        () => PostHogRemoteDataSourceImpl(),
      );
    }
  }

  // Mixpanel (events + session replay). Registered like PostHog; stays a safe
  // no-op until initialize() runs with a token (via MixpanelWrapper).
  if (mixpanelRemoteDataSource != null) {
    if (!sl.isRegistered<MixpanelRemoteDataSource>()) {
      sl.registerLazySingleton<MixpanelRemoteDataSource>(
        () => mixpanelRemoteDataSource,
      );
    }
  } else {
    if (!sl.isRegistered<MixpanelRemoteDataSource>()) {
      sl.registerLazySingleton<MixpanelRemoteDataSource>(
        () => MixpanelRemoteDataSourceImpl(),
      );
    }
  }

  // Repository
  if (analyticsRepository != null) {
    if (!sl.isRegistered<AnalyticsRepository>()) {
      sl.registerLazySingleton<AnalyticsRepository>(() => analyticsRepository);
    }
  } else if (!sl.isRegistered<AnalyticsRepository>()) {
    if (!sl.isRegistered<AnalyticsRemoteDataSource>()) {
      sl.registerLazySingleton<AnalyticsRemoteDataSource>(
        () => FirebaseAnalyticsRemoteDataSourceImpl(),
      );
    }
    sl.registerLazySingleton<AnalyticsRepository>(
      () => AnalyticsRepositoryImpl(
        remoteDataSource: sl(),
        postHogDataSource: sl<PostHogRemoteDataSource>(),
        mixpanelDataSource: sl<MixpanelRemoteDataSource>(),
      ),
    );
  }

  // Use Cases
  if (!sl.isRegistered<LogEventUseCase>()) {
    sl.registerLazySingleton<LogEventUseCase>(
      () => LogEventUseCase(repository: sl()),
    );
  }
  if (!sl.isRegistered<LogAdRevenueUseCase>()) {
    sl.registerLazySingleton<LogAdRevenueUseCase>(
      () => LogAdRevenueUseCase(repository: sl()),
    );
  }

  // Bloc
  if (!sl.isRegistered<AnalyticsBloc>()) {
    sl.registerLazySingleton<AnalyticsBloc>(
      () => AnalyticsBloc(
        repository: sl(),
        logEventUseCase: sl(),
        logAdRevenueUseCase: sl(),
      ),
    );
  }
}
