import 'dart:io';
import 'package:flutter/material.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_scanner/media_scanner.dart';

import '../../../../analytics/data/services/firebase_analytics_service.dart';
import '../../../../permissions/data/datasources/app_storage_permission.dart';
import '../../../data/datasources/local/device_directory.dart';
import '../../bloc/saved_media_bloc/saved_media_bloc.dart';

// Global lock to prevent duplicate saves
final Set<String> _currentlySavingFiles = {};

Future<void> saveStatus(BuildContext context, String filePath) async {
  // Check if already being saved - silently skip to avoid error spam
  if (_currentlySavingFiles.contains(filePath)) {
    print("File is already being saved, skipping UI feedback");
    return;
  }

  try {
    bool success = await _saveStatusLogic(context, filePath);

    if (success) {
      // Notify the user of success
      String fileName = File(filePath).uri.pathSegments.last;
      String fileExtension = fileName.split('.').last.toLowerCase();
      String successMessage =
          fileExtension.startsWith('mp4') || fileExtension.startsWith('mov')
              ? "Video saved successfully!"
              : "Image saved successfully!";
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));

      // Optional: Log event to Firebase
      await AnalyticsService().logSaveStatus();
    }
  } catch (e) {
    // Handle errors
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Error saving file: $e")));
  }
}

Future<bool> saveStatusSilent(BuildContext context, String filePath) async {
  try {
    return await _saveStatusLogic(context, filePath);
  } catch (e) {
    print("Error in saveStatusSilent: $e");
    return false;
  }
}

Future<bool> _saveStatusLogic(BuildContext context, String filePath) async {
  // Check if this file is already being saved
  if (_currentlySavingFiles.contains(filePath)) {
    print("File is already being saved, skipping: $filePath");
    return false; // Already saving, skip
  }

  // Add to lock set
  _currentlySavingFiles.add(filePath);

  try {
    // Step 1: Ensure the file exists
    File originalFile = File(filePath);
    if (!await originalFile.exists()) {
      throw Exception("File does not exist");
    }

    // Step 2: Request storage permissions using permission_handler
    if (await AppStoragePermission().getStoragePermission() == false) {
      throw Exception("Storage permission required");
    }

    // ✅ Step 3: Define target save directory
    String saveDirectory = await DeviceFileInfo().GetSavedMediaAbsolutePath();
    Directory directory = Directory(saveDirectory);

    // ✅ Step 4: Ensure directory exists
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }

    // ✅ Step 5: Extract file name & check if it already exists
    String fileName = originalFile.uri.pathSegments.last;
    String newFilePath = "$saveDirectory/$fileName";
    File newFile = File(newFilePath);

    if (newFile.existsSync()) {
      // ✅ File already exists, delete it
      await deleteFileFromAppFolderWithMediaStore(
        fileName: fileName,
        appFolder: saveDirectory.split('/').last,
      );
    }

    // Step 4: Determine if it's an image or video
    String fileExtension = fileName.split('.').last.toLowerCase();
    AssetEntity? savedMedia;
    var relativeFilePath = await DeviceFileInfo().GetSavedMediaBasedOnDevice();

    if ([
      'jpg',
      'jpeg',
      'png',
      'gif',
      'bmp',
      'webp',
      'heic',
    ].contains(fileExtension)) {
      // Save image
      savedMedia = await PhotoManager.editor.saveImageWithPath(
        filePath,
        title: fileName,
        relativePath: relativeFilePath,
      );
    } else if ([
      'mp4',
      'mov',
      'avi',
      'mkv',
      'webm',
      'flv',
    ].contains(fileExtension)) {
      // Save video
      savedMedia = await PhotoManager.editor.saveVideo(
        File(filePath),
        title: fileName,
        relativePath: relativeFilePath,
      );
    } else {
      throw Exception("Unsupported file format.");
    }

    // Step 5: Handle success or failure
    if (savedMedia != null && await savedMedia.exists == true) {
      context.read<SavedMediaBloc>().add(const SavedMediaLoadRequested());
      return true;
    } else {
      throw Exception("Failed to save media.");
    }
  } finally {
    // Always remove from lock set when done
    _currentlySavingFiles.remove(filePath);
  }
}

Future<void> deleteFileFromAppFolderWithMediaStore({
  required String fileName,
  required String appFolder,
}) async {
  // saveDirectory.split('/').last
  MediaStore.appFolder = appFolder;
  final mediaStore = await MediaStore();
  String extension = fileName.split('.').last.toLowerCase();
  late Uri? fileUri = null;

  if ([
    'jpg',
    'jpeg',
    'png',
    'gif',
    'bmp',
    'webp',
    'heic',
  ].contains(extension)) {
    fileUri = await mediaStore.getFileUri(
      fileName: fileName, // Only file name
      dirType: DirType.photo,
      dirName: DirName.pictures, // Folder under Pictures
    );
  } else if (['mp4', 'mov', 'avi', 'mkv', 'webm', 'flv'].contains(extension)) {
    fileUri = await mediaStore.getFileUri(
      fileName: fileName, // Only file name
      dirType: DirType.video,
      dirName: DirName.pictures, // Folder under Pictures
    );
  }

  print(
    'deleted_file ${fileName} - ${appFolder} - ${fileUri.toString()} -'
    '${extension}',
  );

  if (fileUri != null) {
    await mediaStore.deleteFileUsingUri(uriString: fileUri.toString());

    print('deleted_file_1 ${fileName} - ${appFolder} $fileUri');
  }

  // await mediaStore.deleteFile(
  //   fileName: fileName, // Only file name
  //   dirType: DirType.photo,
  //   dirName: DirName.pictures, // Folder under Pictures
  // );
}

Future<void> deleteSaveStatusFromDevice(
  BuildContext context,
  String filePath, {
  bool showSnackBar = true,
}) async {
  try {
    // Step 1: Ensure the file exists
    File originalFile = File(filePath);
    if (!await originalFile.exists()) {
      if (showSnackBar) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: File does not exist")),
        );
      }
      return;
    }

    // Step 2: Request storage permissions using permission_handler
    if (await AppStoragePermission().getStoragePermission() == false) {
      if (showSnackBar) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Storage permission required")),
        );
      }
      return;
    }

    if (originalFile.existsSync()) {
      // ✅ File already exists, delete it
      print('File Exist ${originalFile.path}');
      final String filePath = originalFile.path;
      originalFile.deleteSync();

      // Try to refresh gallery, but don't crash if plugin fails
      try {
        await MediaScanner.loadMedia(path: filePath);
      } catch (e) {
        print('MediaScanner error (non-critical): $e');
        // Gallery refresh failed, but file is still deleted successfully
      }

      if (showSnackBar) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Media Successfully Deleted")));
      }
    }

    // Optional: Log event to Firebase
    // await AnalyticsService().logSaveStatus();
  } catch (e) {
    // Handle errors
    if (showSnackBar) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error saving file: $e")));
    }
  }
}

Future<void> deleteSaveStatusWithPhotoManager(
  BuildContext context,
  AssetEntity entity,
) async {
  try {
    final result = await PhotoManager.editor.deleteWithIds([entity.id]);
    PhotoManager.clearFileCache();

    print("Result of deleting media ${result}");

    if (result.isNotEmpty) {
      print("Media deleted successfully");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Media Successfully Deleted")));
    } else {
      print("Failed to delete media");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to delete file")));
    }
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Error deleting file: $e")));
  }
}

Future<bool> saveStatusBackground(String filePath) async {
  try {
    // Step 1: Ensure the file exists
    File originalFile = File(filePath);
    if (!await originalFile.exists()) {
      print("Background Save Error: File does not exist - $filePath");
      return false;
    }

    // Step 2: Request storage permissions using permission_handler
    // Note: In background, we assume permissions are already granted.
    // If not, this will fail silently or we should check before calling.
    if (await AppStoragePermission().getStoragePermission() == false) {
      print("Background Save Error: Storage permission required");
      return false;
    }

    // ✅ Step 3: Define target save directory
    String saveDirectory = await DeviceFileInfo().GetSavedMediaAbsolutePath();
    Directory directory = Directory(saveDirectory);

    // ✅ Step 4: Ensure directory exists
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }

    // ✅ Step 5: Extract file name & check if it already exists
    String fileName = originalFile.uri.pathSegments.last;
    String newFilePath = "$saveDirectory/$fileName";
    File newFile = File(newFilePath);

    if (newFile.existsSync()) {
      // ✅ File already exists, delete it
      await deleteFileFromAppFolderWithMediaStore(
        fileName: fileName,
        appFolder: saveDirectory.split('/').last,
      );
    }

    // Step 4: Determine if it's an image or video
    String fileExtension = fileName.split('.').last.toLowerCase();
    AssetEntity? savedMedia;
    var relativeFilePath = await DeviceFileInfo().GetSavedMediaBasedOnDevice();

    if ([
      'jpg',
      'jpeg',
      'png',
      'gif',
      'bmp',
      'webp',
      'heic',
    ].contains(fileExtension)) {
      // Save image
      savedMedia = await PhotoManager.editor.saveImageWithPath(
        filePath,
        title: fileName,
        relativePath: relativeFilePath,
      );
    } else if ([
      'mp4',
      'mov',
      'avi',
      'mkv',
      'webm',
      'flv',
    ].contains(fileExtension)) {
      // Save video
      savedMedia = await PhotoManager.editor.saveVideo(
        File(filePath),
        title: fileName,
        relativePath: relativeFilePath,
      );
    } else {
      print("Background Save Error: Unsupported file format - $fileExtension");
      return false;
    }

    // Step 5: Handle success or failure
    if (savedMedia != null && await savedMedia.exists == true) {
      // Force gallery refresh
      try {
        await MediaScanner.loadMedia(path: newFilePath);
      } catch (e) {
        print("Error scanning media: $e");
      }
      return true;
    } else {
      print("Background Save Error: Failed to save media.");
      return false;
    }
  } catch (e) {
    print("Background Save Error: $e");
    return false;
  }
}
