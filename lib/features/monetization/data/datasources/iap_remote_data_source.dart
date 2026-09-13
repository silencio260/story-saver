import 'package:genrevibes_iap/genrevibes_iap.dart';
import '../services/revenue_cat_service.dart';
import '../services/subscription_service.dart';
import 'iap_base_remote_data_source.dart';

export 'iap_base_remote_data_source.dart';

class RevenueCatIapRemoteDataSource
    implements IapBaseRemoteDataSource, PurchaseOutcomeSource {
  RevenueCatIapRemoteDataSource({
    required RevenueCatService revenueCat,
    required SubscriptionManager subscriptionManager,
  }) : _revenueCat = revenueCat,
       _subscriptionManager = subscriptionManager;

  final RevenueCatService _revenueCat;
  final SubscriptionManager _subscriptionManager;

  @override
  Future<bool> initialize() async {
    await _revenueCat.ConfigureRevenueCatSDK();
    await _subscriptionManager.initialize();
    return _subscriptionManager.isPremium;
  }

  @override
  Future<bool> refresh() async {
    await _subscriptionManager.refreshSubscriptionStatus();
    return _subscriptionManager.isPremium;
  }

  @override
  PurchaseStatus? lastPurchaseStatus;

  @override
  Future<bool> showPaywall() async {
    lastPurchaseStatus = null;
    final outcome = await _revenueCat.PresentRevenueCatPayWallIfNeeded();
    lastPurchaseStatus = switch (outcome) {
      PaywallOutcome.purchased => PurchaseStatus.purchased,
      PaywallOutcome.restored => PurchaseStatus.restored,
      PaywallOutcome.cancelled => PurchaseStatus.cancelled,
      PaywallOutcome.pending => PurchaseStatus.pending,
      PaywallOutcome.notPresented => null,
    };
    return refresh();
  }

  @override
  Future<void> showCustomerCenter() =>
      _revenueCat.PresentRevenueCatCustomerCenter();

  @override
  Future<bool> restorePurchases() async {
    final result = await _revenueCat.restorePurchases();
    result.fold(onSuccess: (_) {}, onFailure: (error) => throw error);
    return refresh();
  }
}
