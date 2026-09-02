import 'package:permission_handler/permission_handler.dart';

/// Utilities for handling permissions
class PermissionUtils {
  /// Request notification permissions (Android 13+)
  static Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isGranted) return true;

    final result = await Permission.notification.request();
    return result.isGranted;
  }

  /// Request storage/photos permission depending on OS version
  static Future<bool> requestStoragePermission() async {
    // Android 13+ use photos/videos permission
    if (await Permission.photos.status.isGranted ||
        await Permission.videos.status.isGranted) {
      return true;
    }

    // Legacy storage
    final storageStatus = await Permission.storage.status;
    if (storageStatus.isGranted) return true;

    // Request logic
    Map<Permission, PermissionStatus> statuses =
        await [
          Permission.storage,
          Permission.photos,
          Permission.videos,
        ].request();

    return statuses[Permission.storage]?.isGranted == true ||
        statuses[Permission.photos]?.isGranted == true ||
        statuses[Permission.videos]?.isGranted == true;
  }

  /// Open app settings
  static Future<bool> openSettings() => openAppSettings();
}
