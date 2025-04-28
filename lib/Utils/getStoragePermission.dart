import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
// import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storysaver/Constants/constant.dart';
import 'package:storysaver/Provider/PermissionProvider.dart';
import 'package:storysaver/Utils/globalNavigationKey.dart';
import 'package:saf/saf.dart';

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
    // final status = await Permission.storage.request();
     final status = await forceRequestAllPermissions();
    // print('status.isGranted ${status.isGranted}');
    if (status) {
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
    // final status = await Permission.storage.request();
    final status = await forceRequestAllPermissions();

    if (status) {
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
    // final status = await Permission.storage.request();
    final status = await forceRequestAllPermissions();

    if (status) {
      _setPermissionValue(true);
      return true;
    }
    else {
      return false;
    }
  }

  Future<bool> forceRequestAllPermissions() async {
    if (Platform.isAndroid) {
      Map<Permission, PermissionStatus> statuses;

      // Get Android version
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      int sdkInt = androidInfo.version.sdkInt;

      if (sdkInt >= 33) {
        // Android 13+
        statuses = await [
          Permission.photos,
          Permission.videos,
          Permission.audio,
        ].request();
      } else {
        // Android 12 and below
        statuses = await [
          Permission.storage,
        ].request();
      }

      // Print all results
      statuses.forEach((permission, status) async {
        // print('perm_status $permission: $status');
      });

      // Now try PhotoManager
      final ps = await PhotoManager.requestPermissionExtend();
      // print("PhotoManager permission after direct request: ${ps.isAuth}");
      return ps.isAuth;
    }
    return false;
  }

  Future<bool> isWhatsAppStatusFolderPermissionAvailable({bool isBusinessMode = false}) async {
    bool isGranted = false;
    String statusFolder = isBusinessMode == false ?
    "Android/media/com.whatsapp/WhatsApp/Media/.Statuses" :
    "Android/media/com.whatsapp.w4b/WhatsApp Business/Media/.Statuses";

    Saf saf  = Saf(statusFolder);
    final isSync =  await saf.sync();

    final accessiblePath = await Saf.getPersistedPermissionDirectories();

    print("accessiblePath in isWhatsAppStatusFolderPermissionAvailable ${accessiblePath}");

    if(accessiblePath != null && accessiblePath.length > 0)
      for (final folder in accessiblePath) {
        if(folder == statusFolder)
          isGranted = true;
      }

    return isGranted;
  }

  Future<void> pickWhatsAppStatusFolder({bool isBusinessMode = false}) async {
    // Saf saf = Saf("/storage/emulated/0/Android/media/com.whatsapp.w4b/WhatsApp Business/Media/.Statuses");
    final folderPath = isBusinessMode == false ?
      "/Android/media/com.whatsapp/WhatsApp/Media/.Statuses/" :
      "/Android/media/com.whatsapp.w4b/WhatsApp Business/Media/.Statuses/";

    Saf saf = Saf(folderPath);

    // Saf saf = Saf("/Android/media/com.whatsapp/WhatsApp/Media/.Statuses/");

    bool? isGranted = await saf.getDirectoryPermission(isDynamic: true);

    print("isGranted $isGranted");

    if (isGranted != null && isGranted) {
      // Perform some file operations
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants().IS_WHATSAPP_STATUS_PERMISSION, true);

      print("isGranted is true $isGranted");

      final accessiblePath = await Saf.getPersistedPermissionDirectories();

      List<String>? paths = await saf.getFilesPath(fileType: FileTypes.media);

      final isCached = await saf.cache();

      List<String>? cachedFilesPath = await saf.getCachedFilesPath();


      print('saf_info ${isCached}');
      print('object ${cachedFilesPath}');

      print('saf_accessiblePath ${accessiblePath} - ${paths}');

      if (accessiblePath!.isNotEmpty) {
        final actualPath = accessiblePath.first;

        // Now you can use the traditional File/Directory API
        final directory = Directory("/storage/emulated/0/${actualPath}/");

        print('saf_accessiblePath_directory ${directory.path} ${await directory.exists()}');

        if (directory.existsSync()) {
          final items = directory.listSync();
          print('------ saf_items -> ${items}');
          // Process your files here
        }
      }
    }
  }

}
