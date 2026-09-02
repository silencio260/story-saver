abstract class IapBaseRemoteDataSource {
  Future<bool> initialize();

  Future<bool> refresh();

  Future<bool> showPaywall();

  Future<void> showCustomerCenter();

  Future<bool> restorePurchases();
}
