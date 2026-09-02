abstract class PermissionBaseLocalDataSource {
  Future<bool> checkStoragePermission();

  Future<bool> requestStoragePermission();

  Future<bool> checkStatusFolderPermission({required bool isBusinessMode});

  Future<void> requestStatusFolderPermission({required bool isBusinessMode});
}
