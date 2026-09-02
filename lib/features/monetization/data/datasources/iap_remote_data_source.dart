import '../services/revenue_cat_service.dart';
import '../services/subscription_service.dart';
import 'iap_base_remote_data_source.dart';

export 'iap_base_remote_data_source.dart';

class RevenueCatIapRemoteDataSource implements IapBaseRemoteDataSource {
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
  Future<bool> showPaywall() async {
    await _revenueCat.PresentRevenueCatPayWallIfNeeded();
    return refresh();
  }

  @override
  Future<void> showCustomerCenter() =>
      _revenueCat.PresentRevenueCatCustomerCenter();

  @override
  Future<bool> restorePurchases() async {
    await _revenueCat.restorePurchases();
    return refresh();
  }
}
