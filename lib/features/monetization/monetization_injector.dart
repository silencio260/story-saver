import '../../container_injector.dart';
import 'data/datasources/ads_base_remote_data_source.dart';
import 'data/datasources/google_mobile_ads_remote_data_source.dart';
import 'data/datasources/iap_remote_data_source.dart';
import 'data/repositories/ads_repository_impl.dart';
import 'data/repositories/iap_repository_impl.dart';
import 'data/services/revenue_cat_service.dart';
import 'data/services/subscription_service.dart';
import 'domain/repositories/ads_repository.dart';
import 'domain/repositories/iap_repository.dart';
import 'domain/usecases/dispose_ads_usecase.dart';
import 'domain/usecases/initialize_iap_usecase.dart';
import 'domain/usecases/load_interstitial_ad_usecase.dart';
import 'domain/usecases/refresh_subscription_usecase.dart';
import 'domain/usecases/restore_purchases_usecase.dart';
import 'domain/usecases/show_customer_center_usecase.dart';
import 'domain/usecases/show_interstitial_ad_usecase.dart';
import 'domain/usecases/show_paywall_usecase.dart';
import 'presentation/bloc/ads_bloc/ads_bloc.dart';
import 'presentation/bloc/iap_bloc/iap_bloc.dart';
import 'presentation/controllers/legacy/ad_suppression_manager.dart';

void initMonetization() {
  sl.registerLazySingleton<RevenueCatService>(RevenueCatService.new);
  sl.registerLazySingleton<SubscriptionManager>(SubscriptionManager.new);
  sl.registerLazySingleton<AdSuppressionManager>(AdSuppressionManager.new);
  sl.registerLazySingleton<AdsBaseRemoteDataSource>(
    () => GoogleMobileAdsRemoteDataSource(
      subscriptionManager: sl(),
      analyticsRepo: sl(),
    ),
  );
  sl.registerLazySingleton<AdsBaseRepo>(() => AdsRepo(remoteDataSource: sl()));
  sl.registerLazySingleton(() => LoadInterstitialAdUseCase(repo: sl()));
  sl.registerLazySingleton(() => ShowInterstitialAdUseCase(repo: sl()));
  sl.registerLazySingleton(() => DisposeAdsUseCase(repo: sl()));
  sl.registerLazySingleton<IapBaseRemoteDataSource>(
    () => RevenueCatIapRemoteDataSource(
      revenueCat: sl(),
      subscriptionManager: sl(),
    ),
  );
  sl.registerLazySingleton<IapBaseRepo>(() => IapRepo(remoteDataSource: sl()));
  sl.registerLazySingleton(() => InitializeIapUseCase(repo: sl()));
  sl.registerLazySingleton(() => RefreshSubscriptionUseCase(repo: sl()));
  sl.registerLazySingleton(() => ShowPaywallUseCase(repo: sl()));
  sl.registerLazySingleton(() => ShowCustomerCenterUseCase(repo: sl()));
  sl.registerLazySingleton(() => RestorePurchasesUseCase(repo: sl()));
  sl.registerFactory(
    () => AdsBloc(
      loadInterstitialAdUseCase: sl(),
      showInterstitialAdUseCase: sl(),
      disposeAdsUseCase: sl(),
      adSuppressionManager: sl(),
    ),
  );
  sl.registerFactory(
    () => IapBloc(
      initializeIapUseCase: sl(),
      refreshSubscriptionUseCase: sl(),
      showPaywallUseCase: sl(),
      showCustomerCenterUseCase: sl(),
      restorePurchasesUseCase: sl(),
    ),
  );
}
