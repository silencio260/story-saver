import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:storysaver/Provider/PermissionProvider.dart';
import 'package:storysaver/Utils/globalNavigationKey.dart';

class AppStoragePermission {
  void _setPermissionValue(bool value) {
    // Provider.of<PermissionProvider>(context, listen: false).getAllStatus();
    final context = myGlobalNavigatorKey.currentContext;

    if (context == null) return;

    final provider = Provider.of<PermissionProvider>(
      context,
      listen: false,
    );

    provider.setHasStoragePermission(value);
  }

// Request storage permission
  Future<bool> getStoragePermission() async {
    final status = await Permission.storage.request();
    if (status.isGranted) {
      _setPermissionValue(true);
      return true;
    } else {
      final storagePermission = await Permission.manageExternalStorage
          .request();
      if (storagePermission.isGranted) {
        _setPermissionValue(true);
        return true;
      } else {
        openAppSettings(); // Optionally prompt user to open settings for manual permission
        return false;
      }
    }
  }

  Future<bool> checkIfWeHaveStoragePermission() async {
    final status = await Permission.storage.request();
    if (status.isGranted) {
      _setPermissionValue(true);
      return true;
    } else {
      final storagePermission = await Permission.manageExternalStorage
          .request();
      if (storagePermission.isGranted) {
        _setPermissionValue(true);
        return true;
      } else {
        return false;
      }
    }

    return false;
  }

  Future<bool> checkForStoragePermissionOnly() async {
    final status = await Permission.storage.request();
    if (status.isGranted) {
      _setPermissionValue(true);
      return true;
    }
    else {
      return false;
    }
  }

  // Future<void> forceRequestAllPermissions() async {
  //   if (Platform.isAndroid) {
  //     Map<Permission, PermissionStatus> statuses;
  //
  //     // Get Android version
  //     final androidInfo = await DeviceInfoPlugin().androidInfo;
  //     int sdkInt = androidInfo.version.sdkInt;
  //
  //     if (sdkInt >= 33) {
  //       // Android 13+
  //       statuses = await [
  //         Permission.photos,
  //         Permission.videos,
  //         Permission.audio,
  //       ].request();
  //     } else {
  //       // Android 12 and below
  //       statuses = await [
  //         Permission.storage,
  //       ].request();
  //     }
  //
  //     // Print all results
  //     statuses.forEach((permission, status) {
  //       print('$permission: $status');
  //     });
  //
  //     // Now try PhotoManager
  //     final ps = await PhotoManager.requestPermissionExtend();
  //     print("PhotoManager permission after direct request: ${ps.isAuth}");
  //   }
  // }
}
