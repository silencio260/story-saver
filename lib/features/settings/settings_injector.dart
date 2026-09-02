import '../../container_injector.dart';
import 'data/datasources/settings_local_data_source.dart';
import 'data/repositories/settings_repository_impl.dart';
import 'domain/repositories/settings_repository.dart';
import 'domain/usecases/contact_support_usecase.dart';
import 'domain/usecases/load_settings_usecase.dart';
import 'domain/usecases/rate_app_usecase.dart';
import 'domain/usecases/set_auto_save_usecase.dart';
import 'domain/usecases/share_app_usecase.dart';
import 'presentation/bloc/settings_bloc/settings_bloc.dart';

void initSettings() {
  sl.registerLazySingleton<SettingsBaseLocalDataSource>(
    SettingsLocalDataSource.new,
  );
  sl.registerLazySingleton<SettingsBaseRepo>(
    () => SettingsRepo(localDataSource: sl()),
  );
  sl.registerLazySingleton(() => LoadSettingsUseCase(repo: sl()));
  sl.registerLazySingleton(() => SetAutoSaveUseCase(repo: sl()));
  sl.registerLazySingleton(() => ShareAppUseCase(repo: sl()));
  sl.registerLazySingleton(() => RateAppUseCase(repo: sl()));
  sl.registerLazySingleton(() => ContactSupportUseCase(repo: sl()));
  sl.registerFactory(
    () => SettingsBloc(
      loadSettingsUseCase: sl(),
      setAutoSaveUseCase: sl(),
      shareAppUseCase: sl(),
      rateAppUseCase: sl(),
      contactSupportUseCase: sl(),
    ),
  );
}
