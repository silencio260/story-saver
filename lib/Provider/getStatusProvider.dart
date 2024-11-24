import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class GetStatusProvider extends ChangeNotifier {
  void getStatus() async {
    print('----------------- being called');

    // Request the storage permission
    PermissionStatus status = await Permission.storage.request();
    print('----------------- $status');

    // Check if permission is granted
    if (status.isGranted) {
      Directory? directory = await getExternalStorageDirectory();
      print('Storage Directory Path: ${directory?.path}');
    }

    // Check if permission is denied
    if (status.isDenied) {
      print("Permission denied");
      // You can explicitly ask the user to open app settings if necessary
      openAppSettings();
    }

    // Handle permanent denial of permission
    if (status.isPermanentlyDenied) {
      print("Permission permanently denied");
      openAppSettings(); // Redirect user to app settings
    }

    // For Android 11 and above, request manage external storage permission
    if (await Permission.manageExternalStorage.isDenied) {
      PermissionStatus manageStatus =
          await Permission.manageExternalStorage.request();
      if (manageStatus.isGranted) {
        print('Manage external storage permission granted');
      } else {
        print('Manage external storage permission denied');
      }
    }
  }
}
