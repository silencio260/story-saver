import '../../domain/entities/entitlement.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/subscription_status.dart';

/// Abstract data source for IAP operations
///
/// Implement this interface for different IAP providers:
/// - RevenueCatDataSource
/// - AdaptyDataSource
/// - StoreKitDataSource (iOS native)
/// - PlayBillingDataSource (Android native)
abstract class IapRemoteDataSource {
  /// Initialize the IAP service
  Future<void> initialize(String apiKey);

  /// Get current subscription status
  Future<SubscriptionStatus> getSubscriptionStatus();

  /// Get available products
  Future<List<Product>> getProducts(List<String> productIds);

  /// Purchase a product
  Future<SubscriptionStatus> purchaseProduct(String productId);

  /// Restore purchases
  Future<SubscriptionStatus> restorePurchases();

  /// Get all entitlements
  Future<List<Entitlement>> getEntitlements();

  /// Check if entitlement is active
  Future<bool> isEntitlementActive(String entitlementId);

  /// Set user ID
  Future<void> setUserId(String userId);

  /// Log out user
  Future<void> logOut();
}
