import '../../container_injector.dart';
import 'data/datasources/app_storage_permission.dart';
import 'data/datasources/permission_local_data_source.dart';
import 'data/repositories/permission_repository_impl.dart';
import 'domain/repositories/permission_repository.dart';
import 'domain/usecases/check_status_folder_permission_usecase.dart';
import 'domain/usecases/check_storage_permission_usecase.dart';
import 'domain/usecases/request_status_folder_permission_usecase.dart';
import 'domain/usecases/request_storage_permission_usecase.dart';
import 'presentation/bloc/permissions_bloc/permissions_bloc.dart';

void initPermissions() {
  sl.registerLazySingleton<AppStoragePermission>(AppStoragePermission.new);
  sl.registerLazySingleton<PermissionBaseLocalDataSource>(
    () => PermissionLocalDataSource(permissionApi: sl()),
  );
  sl.registerLazySingleton<PermissionBaseRepo>(
    () => PermissionRepo(localDataSource: sl()),
  );
  sl.registerLazySingleton(() => CheckStoragePermissionUseCase(repo: sl()));
  sl.registerLazySingleton(() => RequestStoragePermissionUseCase(repo: sl()));
  sl.registerLazySingleton(
    () => CheckStatusFolderPermissionUseCase(repo: sl()),
  );
  sl.registerLazySingleton(
    () => RequestStatusFolderPermissionUseCase(repo: sl()),
  );
  sl.registerFactory(
    () => PermissionsBloc(
      checkStoragePermissionUseCase: sl(),
      requestStoragePermissionUseCase: sl(),
      checkStatusFolderPermissionUseCase: sl(),
      requestStatusFolderPermissionUseCase: sl(),
    ),
  );
}
