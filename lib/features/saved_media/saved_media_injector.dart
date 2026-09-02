import '../../container_injector.dart';
import 'data/datasources/local/saved_media_cache.dart';
import 'data/datasources/local/saved_media_local_data_source.dart';
import 'data/repositories/saved_media_repository_impl.dart';
import 'domain/repositories/saved_media_repository.dart';
import 'domain/usecases/delete_all_saved_media_usecase.dart';
import 'domain/usecases/delete_saved_media_usecase.dart';
import 'domain/usecases/load_saved_media_thumbnail_usecase.dart';
import 'domain/usecases/load_saved_media_usecase.dart';
import 'domain/usecases/is_status_saved_usecase.dart';
import 'domain/usecases/resolve_saved_media_usecase.dart';
import 'domain/usecases/save_status_usecase.dart';
import 'domain/usecases/share_media_usecase.dart';
import 'presentation/bloc/saved_media_bloc/saved_media_bloc.dart';

void initSavedMedia() {
  sl.registerLazySingleton<SavedMediaManager>(SavedMediaManager.new);
  sl.registerLazySingleton<SavedMediaBaseLocalDataSource>(
    () => SavedMediaLocalDataSource(cacheManager: sl()),
  );
  sl.registerLazySingleton<SavedMediaBaseRepo>(
    () => SavedMediaRepo(localDataSource: sl()),
  );
  sl.registerLazySingleton(() => LoadSavedMediaUseCase(repo: sl()));
  sl.registerLazySingleton(() => DeleteSavedMediaUseCase(repo: sl()));
  sl.registerLazySingleton(() => DeleteAllSavedMediaUseCase(repo: sl()));
  sl.registerLazySingleton(() => ResolveSavedMediaPathUseCase(repo: sl()));
  sl.registerLazySingleton(() => LoadSavedMediaThumbnailUseCase(repo: sl()));
  sl.registerLazySingleton(() => SaveStatusUseCase(repo: sl()));
  sl.registerLazySingleton(() => IsStatusSavedUseCase(repo: sl()));
  sl.registerLazySingleton(() => ShareMediaUseCase(repo: sl()));
  sl.registerFactory(
    () => SavedMediaBloc(
      loadSavedMediaUseCase: sl(),
      deleteSavedMediaUseCase: sl(),
      deleteAllSavedMediaUseCase: sl(),
      saveStatusUseCase: sl(),
      isStatusSavedUseCase: sl(),
      resolveSavedMediaPathUseCase: sl(),
      loadSavedMediaThumbnailUseCase: sl(),
      shareMediaUseCase: sl(),
    ),
  );
}
