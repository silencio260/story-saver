import 'app_storage_permission.dart';
import 'permission_base_local_data_source.dart';

export 'permission_base_local_data_source.dart';

class PermissionLocalDataSource implements PermissionBaseLocalDataSource {
  const PermissionLocalDataSource({required AppStoragePermission permissionApi})
    : _permissionApi = permissionApi;

  final AppStoragePermission _permissionApi;

  @override
  Future<bool> checkStoragePermission() =>
      _permissionApi.checkForStoragePermissionOnly();

  @override
  Future<bool> requestStoragePermission() =>
      _permissionApi.getStoragePermission();

  @override
  Future<bool> checkStatusFolderPermission({required bool isBusinessMode}) =>
      _permissionApi.isWhatsAppStatusFolderPermissionAvailable(
        isBusinessMode: isBusinessMode,
      );

  @override
  Future<void> requestStatusFolderPermission({required bool isBusinessMode}) =>
      _permissionApi.pickWhatsAppStatusFolder(isBusinessMode: isBusinessMode);
}
