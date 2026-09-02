import 'package:get_it/get_it.dart';

import 'data/repositories/noop_iap_repository.dart';
import 'domain/repositories/iap_repository.dart';
import 'domain/usecases/get_products_usecase.dart';
import 'domain/usecases/get_subscription_status_usecase.dart';
import 'domain/usecases/initialize_iap_usecase.dart';
import 'domain/usecases/purchase_product_usecase.dart';
import 'domain/usecases/restore_purchases_usecase.dart';
import 'presentation/bloc/iap_bloc.dart';

/// Initialize IAP feature dependencies
void initIapFeature(GetIt sl, {IapRepository? iapRepository}) {
  // Repository
  if (iapRepository != null) {
    sl.registerLazySingleton<IapRepository>(() => iapRepository);
  } else if (!sl.isRegistered<IapRepository>()) {
    sl.registerLazySingleton<IapRepository>(() => const NoopIapRepository());
  }

  // Use cases
  if (!sl.isRegistered<GetSubscriptionStatusUseCase>()) {
    sl.registerLazySingleton<GetSubscriptionStatusUseCase>(
      () => GetSubscriptionStatusUseCase(repository: sl()),
    );
  }
  if (!sl.isRegistered<InitializeIapUseCase>()) {
    sl.registerLazySingleton<InitializeIapUseCase>(
      () => InitializeIapUseCase(repository: sl()),
    );
  }
  if (!sl.isRegistered<GetProductsUseCase>()) {
    sl.registerLazySingleton<GetProductsUseCase>(
      () => GetProductsUseCase(repository: sl()),
    );
  }
  if (!sl.isRegistered<PurchaseProductUseCase>()) {
    sl.registerLazySingleton<PurchaseProductUseCase>(
      () => PurchaseProductUseCase(repository: sl()),
    );
  }
  if (!sl.isRegistered<RestorePurchasesUseCase>()) {
    sl.registerLazySingleton<RestorePurchasesUseCase>(
      () => RestorePurchasesUseCase(repository: sl()),
    );
  }

  // Bloc
  if (!sl.isRegistered<IapBloc>()) {
    sl.registerLazySingleton<IapBloc>(
      () => IapBloc(
        initializeIapUseCase: sl(),
        getSubscriptionStatusUseCase: sl(),
        getProductsUseCase: sl(),
        purchaseProductUseCase: sl(),
        restorePurchasesUseCase: sl(),
      ),
    );
  }
}
