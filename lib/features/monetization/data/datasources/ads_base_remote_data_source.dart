abstract class AdsBaseRemoteDataSource {
  Future<void> loadInterstitial();

  Future<bool> showInterstitial();

  Future<void> dispose();
}
