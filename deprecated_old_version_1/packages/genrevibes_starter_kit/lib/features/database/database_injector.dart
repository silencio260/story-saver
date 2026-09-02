import 'package:get_it/get_it.dart';

import 'domain/repositories/user_profile_repository.dart';
import 'presentation/bloc/user_profile_bloc.dart';

/// Initializes database feature dependencies
void initDatabase({
  GetIt? sl,
  UserProfileRepository? userProfileRepository,
}) {
  final getIt = sl ?? GetIt.instance;

  // Repositories
  if (userProfileRepository != null) {
    getIt.registerLazySingleton<UserProfileRepository>(
        () => userProfileRepository);
  }

  // BLoCs
  if (!getIt.isRegistered<UserProfileBloc>()) {
    getIt.registerFactory<UserProfileBloc>(
      () => UserProfileBloc(repository: getIt<UserProfileRepository>()),
    );
  }
}
