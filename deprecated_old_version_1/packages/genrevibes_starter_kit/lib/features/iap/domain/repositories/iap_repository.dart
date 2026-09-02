import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/entitlement.dart';
import '../entities/product.dart';
import '../entities/subscription_status.dart';

/// Abstract repository for IAP operations
///
/// Implement this with RevenueCat, Adapty, or any other IAP provider
abstract class IapRepository {
  /// Initialize the IAP service with API key
  Future<Either<Failure, void>> initialize(String apiKey);

  /// Get current subscription status
  Future<Either<Failure, SubscriptionStatus>> getSubscriptionStatus();

  /// Get available products for purchase
  Future<Either<Failure, List<Product>>> getProducts(List<String> productIds);

  /// Purchase a product
  Future<Either<Failure, SubscriptionStatus>> purchaseProduct(String productId);

  /// Restore previous purchases
  Future<Either<Failure, SubscriptionStatus>> restorePurchases();

  /// Get all active entitlements
  Future<Either<Failure, List<Entitlement>>> getEntitlements();

  /// Check if a specific entitlement is active
  Future<Either<Failure, bool>> isEntitlementActive(String entitlementId);

  /// Set user ID for the IAP service
  Future<Either<Failure, void>> setUserId(String userId);

  /// Check if a feature is unlocked for the current user
  ///
  /// Use this for generic feature gating based on entitlements.
  /// The featureId should map to entitlement IDs configured in your IAP provider.
  Future<bool> isFeatureUnlocked(String featureId);

  /// Get list of all unlocked feature IDs
  Future<List<String>> getUnlockedFeatures();

  /// Log out user from IAP service
  Future<Either<Failure, void>> logOut();
}
