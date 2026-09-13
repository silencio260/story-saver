import 'package:genrevibes_iap/genrevibes_iap.dart';

abstract class IapBaseRemoteDataSource {
  Future<bool> initialize();

  Future<bool> refresh();

  Future<bool> showPaywall();

  Future<void> showCustomerCenter();

  Future<bool> restorePurchases();
}

/// Optional result detail for providers that distinguish payment outcomes.
abstract interface class PurchaseOutcomeSource {
  PurchaseStatus? get lastPurchaseStatus;
}
