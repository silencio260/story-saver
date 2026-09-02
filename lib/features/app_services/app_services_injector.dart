import '../../container_injector.dart';
import 'data/datasources/app_services_data_source.dart';
import 'data/repositories/app_services_repository_impl.dart';
import 'domain/repositories/app_services_repository.dart';
import 'domain/usecases/initialize_app_services_usecase.dart';

void initAppServices() {
  sl.registerLazySingleton<AppServicesBaseDataSource>(
    AppServicesDataSource.new,
  );
  sl.registerLazySingleton<AppServicesBaseRepo>(
    () => AppServicesRepo(dataSource: sl()),
  );
  sl.registerLazySingleton(() => InitializeAppServicesUseCase(repo: sl()));
}
