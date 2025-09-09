import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:docman/docman.dart';
// import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storysaver/Constants/constant.dart';
import 'package:storysaver/Provider/PermissionProvider.dart';
import 'package:storysaver/Services/Notifications/PushNotification.dart';
import 'package:storysaver/Services/analytics_service.dart';
import 'package:storysaver/Utils/globalNavigationKey.dart';
// import 'package:saf/saf.dart';

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

      await PushNotification().initializeAndPrompt();

      // Now try PhotoManager
      final ps = await PhotoManager.requestPermissionExtend();
      // print("PhotoManager permission after direct request: ${ps.isAuth}");
      return ps.isAuth;
    }
    return false;
  }

  Future<bool> isWhatsAppStatusFolderPermissionAvailable({bool isBusinessMode = false}) async {
    // String statusFolder = isBusinessMode == false
    //     ? "Android/media/com.whatsapp/WhatsApp/Media/.Statuses"
    //     : "Android/media/com.whatsapp.w4b/WhatsApp Business/Media/.Statuses";

    String androidMediaFolder = "Android/media";


    // // Extract base docId ("primary:Android/media")
    // final baseDocId = Uri.decodeComponent(
    //   androidMediaDir.toString().split('/tree/').last.split('/document/').first,
    // );
    //
    // // Build the full docId with the relative path
    // final fullDocId = "$baseDocId/$relativePath";
    //
    // // Encode and build final content:// URI
    // final fullUri =
    //     "content://com.android.externalstorage.documents/tree/${Uri.encodeComponent(baseDocId)}/document/${Uri.encodeComponent(fullDocId)}";


    List<PersistedPermission> permissions = await DocMan.perms.list(files: false, directories: true);

    print("accessiblePath in isWhatsAppStatusFolderPermissionAvailable ${permissions.map((p) => p.uri).toList()}");

    bool isGranted = false;

    for (final permission in permissions) {
      final decodedUri = Uri.decodeFull(permission.uri);

      final baseDocId = Uri.decodeComponent(
        permission.uri.toString().split('media').first,
      );

      print('_getBusinessWhatsAppStatusFolderPermission -> decodedUri.endsWith("androidMediaFolder") - ${decodedUri.endsWith("$androidMediaFolder")} - ${decodedUri}');
      if (decodedUri.endsWith("$androidMediaFolder")){

        print('_getBusinessWhatsAppStatusFolderPermission 2 -> ${decodedUri} - ${baseDocId}');
        isGranted = true;
        break;
      }
      else if (isBusinessMode == true &&
        (decodedUri.contains('whatsapp.w4b') && decodedUri.contains('.Statuses')) ){

        isGranted = true;
        break;
      }
      else if(isBusinessMode == false
      && ( (decodedUri.contains("com.whatsapp") && !decodedUri.contains("w4b"))
              && decodedUri.contains('.Statuses')) ) {

        isGranted = true;
        break;
      }
    }

      // if (decodedUri.contains(androidMediaFolder) ||
      //     (isBusinessMode && decodedUri.contains('whatsapp.w4b') && decodedUri.contains('.Statuses')) ||
      //     (!isBusinessMode && decodedUri.contains('com.whatsapp') && decodedUri.contains('.Statuses'))) {
      //   isGranted = true;
      //   break;
      // }

    return isGranted;
  }

  // Future<void> pickWhatsAppStatusFolder({bool isBusinessMode = false}) async {
  //   final folderPath = isBusinessMode == false ?
  //   "/Android/media/com.whatsapp/WhatsApp/Media/.Statuses/" :
  //   "/Android/media/com.whatsapp.w4b/WhatsApp Business/Media/.Statuses/";
  //
  //   print("Expected folder path: $folderPath");
  //
  //   DocumentFile? statusDir = await DocMan.pick.directory(initDir: folderPath);
  //
  //   print("isGranted ${statusDir}");
  //
  //   if (statusDir != null && await statusDir.exists) {
  //     // Validate that the correct WhatsApp folder was selected
  //     String expectedPath = isBusinessMode ? "whatsapp.w4b" : "com.whatsapp";
  //
  //     if (statusDir.uri.contains(expectedPath) && statusDir.uri.contains(".Statuses")) {
  //       final prefs = await SharedPreferences.getInstance();
  //
  //       // Set different permission keys based on mode
  //       if (isBusinessMode) {
  //         await prefs.setBool(AppConstants().IS_BUSINESS_MODE, true);
  //       } else {
  //         await prefs.setBool(AppConstants().IS_WHATSAPP_STATUS_PERMISSION, true);
  //       }
  //
  //       print("Permission granted for WhatsApp ${isBusinessMode ? 'Business' : 'Regular'}");
  //       print("Selected correct path: ${statusDir.uri}");
  //
  //       // Rest of your existing code...
  //       List<PersistedPermission> permissions = await DocMan.perms.list(files: false, directories: true);
  //
  //       List<DocumentFile> documents = await statusDir.listDocuments(
  //         mimeTypes: ['image/*', 'video/*'],
  //       );
  //
  //       List<File> cachedFiles = [];
  //       for (DocumentFile doc in documents) {
  //         File? cachedFile = await doc.cache();
  //         if (cachedFile != null) {
  //           cachedFiles.add(cachedFile);
  //         }
  //       }
  //
  //       List<String> cachedFilesPath = cachedFiles.map((file) => file.path).toList();
  //
  //       print('saf_info ${cachedFiles.length}');
  //       print('object ${cachedFilesPath}');
  //
  //       print('saf_accessiblePath ${permissions.map((p) => p.uri).toList()} - ${documents.map((d) => d.uri).toList()}');
  //
  //       if (permissions.isNotEmpty) {
  //         final actualUri = permissions.first.uri;
  //
  //         DocumentFile? directory = await DocumentFile.fromUri(actualUri);
  //
  //         print('saf_accessiblePath_directory ${directory?.uri} ${await directory?.exists ?? false}');
  //
  //         if (directory != null && await directory.exists) {
  //           List<DocumentFile> items = await directory.listDocuments();
  //           print('------ saf_items -> ${items.map((item) => item.name).toList()}');
  //         }
  //       }
  //     } else {
  //       print("Wrong folder selected!");
  //       print("Expected path containing: $expectedPath and .Statuses");
  //       print("Selected path: ${statusDir.uri}");
  //       print("Please navigate to: $folderPath");
  //     }
  //   }
  // }


  Future<void> pickWhatsAppStatusFolder({bool isBusinessMode = false}) async {
    final initDirUri = isBusinessMode == false ?
    "content://com.android.externalstorage.documents/tree/primary%3AAndroid%2Fmedia%2Fcom.whatsapp%2FWhatsApp%2FMedia%2F.Statuses" :
    "content://com.android.externalstorage.documents/tree/primary%3AAndroid%2Fmedia%2Fcom.whatsapp.w4b%2FWhatsApp%20Business%2FMedia%2F.Statuses";

    DocumentFile? androidMediaDir = await DocMan.pick.directory(initDir: "content://com.android.externalstorage.documents/tree/primary%3AAndroid%2Fmedia");

    print("Selected directory: ${androidMediaDir?.uri}");

    if (androidMediaDir != null && await androidMediaDir.exists) {
      // Validate this is the Android/media directory
      if (androidMediaDir.uri.contains("Android") && androidMediaDir.uri.contains("media")) {
        print("Correct Android/media directory selected");

        // Now look for existing WhatsApp permissions or navigate to WhatsApp folders
        List<PersistedPermission> permissions = await DocMan.perms.list(files: false, directories: true);

        String expectedPath = isBusinessMode ? "whatsapp.w4b" : "com.whatsapp";
        DocumentFile? statusDir;

        // Check if we already have permission to the specific WhatsApp status folder
        for (final permission in permissions) {
          final decodedUri = Uri.decodeFull(permission.uri);
          if (decodedUri.toLowerCase().endsWith("android/media") ||
          (decodedUri.contains(expectedPath) && decodedUri.contains(".Statuses"))) {
            print("Found existing WhatsApp permission: $decodedUri");
            statusDir = await DocumentFile.fromUri(permission.uri);

            if (statusDir != null && await statusDir.exists && statusDir.canRead) {

              if(decodedUri.toLowerCase().endsWith("android/media")){
                AnalyticsService.logGrantAndroidMediaFolderPermission();
              }

              print("statusDir is active and can read");
              break;
            } else {
              await DocMan.perms.release(permission.uri);
              statusDir = null;
            }
          }
        }

        // If no existing valid permission, user needs to navigate manually to specific folder
        if (statusDir == null) {
          print("No existing permission found for WhatsApp ${isBusinessMode ? 'Business' : 'Regular'}");
          print("You now have access to Android/media. Please navigate to the specific folder:");
          // print(folderPath);
          return;
        }

        // Continue with existing logic if we found valid statusDir
        final prefs = await SharedPreferences.getInstance();

        if (isBusinessMode) {
          await prefs.setBool(AppConstants().IS_BUSINESS_MODE, true);
        } else {
          await prefs.setBool(AppConstants().IS_WHATSAPP_STATUS_PERMISSION, true);
        }

        print("Permission granted for WhatsApp ${isBusinessMode ? 'Business' : 'Regular'}");
        print("Using status directory: ${statusDir.uri}");

        List<DocumentFile> documents = await statusDir.listDocuments(
          mimeTypes: ['image/*', 'video/*'],
        );

        List<File> cachedFiles = [];
        for (DocumentFile doc in documents) {
          File? cachedFile = await doc.cache();
          if (cachedFile != null) {
            cachedFiles.add(cachedFile);
          }
        }

        List<String> cachedFilesPath = cachedFiles.map((file) => file.path).toList();

        print('saf_info ${cachedFiles.length}');
        print('object ${cachedFilesPath}');

        print('saf_accessiblePath ${permissions.map((p) => p.uri).toList()} - ${documents.map((d) => d.uri).toList()}');

        if (permissions.isNotEmpty) {
          final actualUri = permissions.first.uri;

          DocumentFile? directory = await DocumentFile.fromUri(actualUri);

          print('saf_accessiblePath_directory ${directory?.uri} ${await directory?.exists ?? false}');

          if (directory != null && await directory.exists) {
            List<DocumentFile> items = await directory.listDocuments();
            print('------ saf_items -> ${items.map((item) => item.name).toList()}');
          }
        }

      } else {
        print("Please select the Android/media folder specifically");
        print("Selected: ${androidMediaDir.uri}");
      }
    } else {
      print("No directory selected or Android/media folder doesn't exist");
    }
  }
}
