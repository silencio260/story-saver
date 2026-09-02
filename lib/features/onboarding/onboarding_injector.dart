import '../../container_injector.dart';
import '../splash/presentation/bloc/splash_bloc/splash_bloc.dart';
import 'data/datasources/onboarding_local_data_source.dart';
import 'data/repositories/onboarding_repository_impl.dart';
import 'domain/repositories/onboarding_repository.dart';
import 'domain/usecases/complete_onboarding_usecase.dart';
import 'domain/usecases/get_onboarding_status_usecase.dart';
import 'domain/usecases/reset_onboarding_usecase.dart';
import 'presentation/bloc/onboarding_bloc/onboarding_bloc.dart';

void initOnboarding() {
  sl.registerLazySingleton<OnboardingBaseLocalDataSource>(
    OnboardingLocalDataSource.new,
  );
  sl.registerLazySingleton<OnboardingBaseRepo>(
    () => OnboardingRepo(localDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetOnboardingStatusUseCase(repo: sl()));
  sl.registerLazySingleton(() => CompleteOnboardingUseCase(repo: sl()));
  sl.registerLazySingleton(() => ResetOnboardingUseCase(repo: sl()));
  sl.registerFactory(
    () => OnboardingBloc(
      completeOnboardingUseCase: sl(),
      resetOnboardingUseCase: sl(),
    ),
  );
  sl.registerFactory(() => SplashBloc(getOnboardingStatusUseCase: sl()));
}
