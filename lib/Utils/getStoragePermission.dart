import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:storysaver/Provider/PermissionProvider.dart';
import 'package:storysaver/Utils/globalNavigationKey.dart';


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
    final storagePermission = await Permission.manageExternalStorage.request();
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
    final storagePermission = await Permission.manageExternalStorage.request();
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