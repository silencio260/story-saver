import '../../container_injector.dart';
import 'data/datasources/analytics_remote_data_source.dart';
import 'data/repositories/analytics_repository_impl.dart';
import 'domain/repositories/analytics_repository.dart';
import 'domain/usecases/initialize_analytics_usecase.dart';
import 'domain/usecases/log_analytics_event_usecase.dart';
import 'presentation/bloc/analytics_bloc/analytics_bloc.dart';

void initAnalytics() {
  sl.registerLazySingleton<AnalyticsBaseRemoteDataSource>(
    FirebaseAnalyticsRemoteDataSource.new,
  );
  sl.registerLazySingleton<AnalyticsBaseRepo>(
    () => AnalyticsRepo(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => InitializeAnalyticsUseCase(repo: sl()));
  sl.registerLazySingleton(() => LogAnalyticsEventUseCase(repo: sl()));
  sl.registerFactory(
    () => AnalyticsBloc(
      initializeAnalyticsUseCase: sl(),
      logAnalyticsEventUseCase: sl(),
    ),
  );
}
