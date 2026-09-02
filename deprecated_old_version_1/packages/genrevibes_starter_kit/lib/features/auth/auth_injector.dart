import 'package:get_it/get_it.dart';

import '../database/domain/repositories/user_profile_repository.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/usecases/auth_usecases.dart';
import 'presentation/bloc/auth_bloc.dart';

/// Initializes authentication feature dependencies
void initAuth({
  GetIt? sl,
  AuthRepository? authRepository,
  Future<void> Function(String, String)? onAccountMerge,
}) {
  final getIt = sl ?? GetIt.instance;

  // Repository
  if (authRepository != null) {
    getIt.registerLazySingleton<AuthRepository>(() => authRepository);
  }

  // Use Cases
  if (!getIt.isRegistered<SignInAnonymouslyUseCase>()) {
    getIt.registerLazySingleton<SignInAnonymouslyUseCase>(
      () => SignInAnonymouslyUseCase(repository: getIt<AuthRepository>()),
    );
  }

  if (!getIt.isRegistered<SignInWithEmailUseCase>()) {
    getIt.registerLazySingleton<SignInWithEmailUseCase>(
      () => SignInWithEmailUseCase(repository: getIt<AuthRepository>()),
    );
  }

  if (!getIt.isRegistered<SignInWithGoogleUseCase>()) {
    getIt.registerLazySingleton<SignInWithGoogleUseCase>(
      () => SignInWithGoogleUseCase(repository: getIt<AuthRepository>()),
    );
  }

  if (!getIt.isRegistered<SignInWithAppleUseCase>()) {
    getIt.registerLazySingleton<SignInWithAppleUseCase>(
      () => SignInWithAppleUseCase(repository: getIt<AuthRepository>()),
    );
  }

  if (!getIt.isRegistered<SignUpWithEmailUseCase>()) {
    getIt.registerLazySingleton<SignUpWithEmailUseCase>(
      () => SignUpWithEmailUseCase(repository: getIt<AuthRepository>()),
    );
  }

  if (!getIt.isRegistered<SignOutUseCase>()) {
    getIt.registerLazySingleton<SignOutUseCase>(
      () => SignOutUseCase(repository: getIt<AuthRepository>()),
    );
  }

  if (!getIt.isRegistered<GetCurrentUserUseCase>()) {
    getIt.registerLazySingleton<GetCurrentUserUseCase>(
      () => GetCurrentUserUseCase(repository: getIt<AuthRepository>()),
    );
  }

  if (!getIt.isRegistered<GetIdTokenUseCase>()) {
    getIt.registerLazySingleton<GetIdTokenUseCase>(
      () => GetIdTokenUseCase(repository: getIt<AuthRepository>()),
    );
  }

  if (!getIt.isRegistered<LinkWithEmailUseCase>()) {
    getIt.registerLazySingleton<LinkWithEmailUseCase>(
      () => LinkWithEmailUseCase(repository: getIt<AuthRepository>()),
    );
  }

  if (!getIt.isRegistered<LinkWithGoogleUseCase>()) {
    getIt.registerLazySingleton<LinkWithGoogleUseCase>(
      () => LinkWithGoogleUseCase(repository: getIt<AuthRepository>()),
    );
  }

  if (!getIt.isRegistered<LinkWithAppleUseCase>()) {
    getIt.registerLazySingleton<LinkWithAppleUseCase>(
      () => LinkWithAppleUseCase(repository: getIt<AuthRepository>()),
    );
  }

  // BLoC (Factory for stateful instances)
  if (!getIt.isRegistered<AuthBloc>()) {
    getIt.registerFactory<AuthBloc>(
      () => AuthBloc(
        repository: getIt<AuthRepository>(),
        userProfileRepository: getIt.isRegistered<UserProfileRepository>()
            ? getIt<UserProfileRepository>()
            : null,
        onAccountMerge: onAccountMerge,
      ),
    );
  }
}
