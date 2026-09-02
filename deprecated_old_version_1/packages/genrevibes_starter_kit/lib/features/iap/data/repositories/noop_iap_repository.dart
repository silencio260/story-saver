import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/entitlement.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/subscription_status.dart';
import '../../domain/repositories/iap_repository.dart';

class NoopIapRepository implements IapRepository {
  const NoopIapRepository();

  @override
  Future<Either<Failure, void>> initialize(String apiKey) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, SubscriptionStatus>> getSubscriptionStatus() async {
    return const Right(SubscriptionStatus.free());
  }

  @override
  Future<Either<Failure, List<Product>>> getProducts(
    List<String> productIds,
  ) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, SubscriptionStatus>> purchaseProduct(
    String productId,
  ) async {
    return const Left(
      ConfigurationFailure(message: 'IAP provider is not configured'),
    );
  }

  @override
  Future<Either<Failure, SubscriptionStatus>> restorePurchases() async {
    return const Right(SubscriptionStatus.free());
  }

  @override
  Future<Either<Failure, List<Entitlement>>> getEntitlements() async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, bool>> isEntitlementActive(
      String entitlementId) async {
    return const Right(false);
  }

  @override
  Future<Either<Failure, void>> setUserId(String userId) async {
    return const Right(null);
  }

  @override
  Future<bool> isFeatureUnlocked(String featureId) async {
    return false;
  }

  @override
  Future<List<String>> getUnlockedFeatures() async {
    return const [];
  }

  @override
  Future<Either<Failure, void>> logOut() async {
    return const Right(null);
  }
}
