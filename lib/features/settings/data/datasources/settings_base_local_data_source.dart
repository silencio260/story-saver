abstract class SettingsBaseLocalDataSource {
  Future<bool> loadAutoSave();

  Future<bool> setAutoSave(bool enabled);

  Future<void> shareApp();

  Future<void> rateApp();

  Future<void> contactSupport();
}
