import '../../container_injector.dart';
import 'data/datasources/local/status_file_system_data_source_engine.dart';
import 'data/datasources/local/status_local_data_source.dart';
import 'data/repositories/status_repository_impl.dart';
import 'domain/repositories/status_repository.dart';
import 'domain/usecases/clear_status_cache_usecase.dart';
import 'domain/usecases/generate_status_thumbnail_usecase.dart';
import 'domain/usecases/get_business_mode_usecase.dart';
import 'domain/usecases/load_statuses_usecase.dart';
import 'domain/usecases/set_business_mode_usecase.dart';
import 'presentation/bloc/status_bloc/status_bloc.dart';

void initStatuses() {
  sl.registerLazySingleton<StatusFileSystemDataSourceEngine>(
    () => StatusFileSystemDataSourceEngine(permissionRepo: sl()),
  );
  sl.registerLazySingleton<StatusBaseLocalDataSource>(
    () => StatusLocalDataSource(statusEngine: sl()),
  );
  sl.registerLazySingleton<StatusBaseRepo>(
    () => StatusRepo(localDataSource: sl()),
  );
  sl.registerLazySingleton(() => LoadStatusesUseCase(statusRepo: sl()));
  sl.registerLazySingleton(() => GetBusinessModeUseCase(statusRepo: sl()));
  sl.registerLazySingleton(() => SetBusinessModeUseCase(statusRepo: sl()));
  sl.registerLazySingleton(() => ClearStatusCacheUseCase(statusRepo: sl()));
  sl.registerLazySingleton(
    () => GenerateStatusThumbnailUseCase(statusRepo: sl()),
  );
  sl.registerFactory(
    () => StatusBloc(
      loadStatusesUseCase: sl(),
      getBusinessModeUseCase: sl(),
      setBusinessModeUseCase: sl(),
      clearStatusCacheUseCase: sl(),
      generateStatusThumbnailUseCase: sl(),
    ),
  );
}
