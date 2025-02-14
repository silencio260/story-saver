import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:storysaver/Utils/getStoragePermission.dart';
import 'package:media_scanner/media_scanner.dart';


Future<void> saveStatus(BuildContext context, String filePath) async {
  try {
    // ✅ Step 1: Ensure the file actually exists before proceeding
    File originalFile = File(filePath);
    if (!await originalFile.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: File does not exist")),
      );
      return;
    }

    // ✅ Step 2: Request storage permission (Android 10+)
    if (await getStoragePermission() == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Storage permission required")),
      );
      return;
    }

    // ✅ Step 3: Define target save directory
    String saveDirectory = "/storage/emulated/0/Pictures/YourApp/Saved Statuses";
    Directory directory = Directory(saveDirectory);

    // ✅ Step 4: Ensure directory exists
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }

    // ✅ Step 5: Extract file name & extension
    String fileName = originalFile.uri.pathSegments.last;
    String fileExtension = fileName.split('.').last.toLowerCase();
    String newFilePath = "$saveDirectory/$fileName";
    File newFile = File(newFilePath);

    // ✅ Step 6: Check if the file already exists in the target directory
    if (newFile.existsSync()) {
      // Delete the old file before copying
      newFile.deleteSync();
    }

    // ✅ Step 7: Copy the file to the new directory
    await originalFile.copy(newFilePath);

    // await MediaStore.ensureInitialized(filePath);

    // await MediaScanner.loadMedia(path: newFilePath);
    // final result = await MediaScanner.loadMedia(filePath);


    // ✅ Step 8: Save the file to the gallery
    final result = await ImageGallerySaver.saveFile(newFilePath);

    // final result = await ImageGallerySaver.saveFile(
    //   originalFile.path,
    //   name: fileName,  // Specify the name
    //   isReturnPathOfIOS: true,  // Get path on iOS
    // );
    //
    if (result['isSuccess'] == true) {
      String successMessage = (fileExtension == "mp4" || fileExtension == "avi" || fileExtension == "mov")
          ? "Video saved successfully!"
          : "Image saved successfully!";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    } else {
      throw Exception("Failed to save file");
    }

  } catch (e) {
    // ✅ Step 9: Handle errors properly
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error saving file: $e")),
    );
  }
}
