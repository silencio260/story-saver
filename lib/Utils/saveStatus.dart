import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'package:storysaver/Provider/savedMediaProvider.dart';
import 'package:storysaver/Services/analytics_service.dart';
import 'package:storysaver/Utils/deviceDirectory.dart';
import 'package:storysaver/Utils/getStoragePermission.dart';



Future<void> saveStatus(BuildContext context, String filePath) async {
  try {
    // Step 1: Ensure the file exists
    File originalFile = File(filePath);
    if (!await originalFile.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: File does not exist")),
      );
      return;
    }

    // Step 2: Request storage permissions using permission_handler
    if (await getStoragePermission() == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Storage permission required")),
      );
      return;
    }

    // // Step 3: Define the save directory and file name
    // String saveDirectory = "Pictures/YourApp/Saved Statuses"; // Gallery subfolder
    // String fileName = originalFile.uri.pathSegments.last;


    // ✅ Step 3: Define target save directory
    // String saveDirectory = "/storage/emulated/0/Pictures/YourApp/Saved Statuses";
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

    var path = await DeviceFileInfo().GetSavedMediaAbsolutePath();
    var path2 = await DeviceFileInfo().GetSavedMediaBasedOnDevice();
    // checkVersion();
    print('ExternalPath $path');
    print('ExternalPath222 $path2');
    print('File(filePath) ${File(filePath)}');
    print('File Exist newFile.path ${newFile.path}');
    print("newFile.existsSync() ${newFile.existsSync()}");
    print('directory!.path ${directory!.path}');
    if (newFile.existsSync()) {
      // ✅ File already exists, delete it
      print('File Exist ${newFile.path}');
      newFile.deleteSync();
    }

    // Step 4: Determine if it's an image or video
    String fileExtension = fileName.split('.').last.toLowerCase();
    AssetEntity? savedMedia;
    var relativeFilePath = await DeviceFileInfo().GetSavedMediaBasedOnDevice();
    print('relativeFilePath2 ${relativeFilePath}');


    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'heic'].contains(fileExtension)) {
      // Save image
      savedMedia = await PhotoManager.editor.saveImageWithPath(
        filePath,//await DeviceFileInfo().GetSavedMediaBasedOnDevice(),
        title: fileName,
        relativePath: relativeFilePath,
      );
      print('savedMedia ${savedMedia.relativePath}');
    } else if (['mp4', 'mov', 'avi', 'mkv', 'webm', 'flv'].contains(fileExtension)) {
      // Save video
      savedMedia = await PhotoManager.editor.saveVideo(
        File(filePath),
        title: fileName,
        relativePath: relativeFilePath
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unsupported file format.")),
      );
      return;
    }


    // Step 5: Handle success or failure
    if (await savedMedia.exists == true) {
      // Update the provider with the new media
      context.read<GetSavedMediaProvider>().preventDuplicateAddition(savedMedia);
      context.read<GetSavedMediaProvider>().addNewMediaToTop(savedMedia);

      // Notify the user of success
      String successMessage = fileExtension.startsWith('mp4') || fileExtension.startsWith('mov')
          ? "Video saved successfully!"
          : "Image saved successfully!";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );

      // Optional: Log event to Firebase
      await AnalyticsService().logSaveStatus();
    } else {
      throw Exception("Failed to save media.");
    }
  } catch (e) {
    // Handle errors
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error saving file: $e")),
    );
  }
}

Future<void> deleteSaveStatusFromDevice(BuildContext context, String filePath) async {

  try {
    // Step 1: Ensure the file exists
    File originalFile = File(filePath);
    if (!await originalFile.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: File does not exist")),
      );
      return;
    }

    // Step 2: Request storage permissions using permission_handler
    if (await getStoragePermission() == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Storage permission required")),
      );
      return;
    }


    if (originalFile.existsSync()) {
      // ✅ File already exists, delete it
      print('File Exist ${originalFile.path}');
      originalFile.deleteSync();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Media Successfully Deleted")),
      );
    }


    // Optional: Log event to Firebase
    // await AnalyticsService().logSaveStatus();

  } catch (e) {
    // Handle errors
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error saving file: $e")),
    );
  }



  // try{
  //
  //   final result = await PhotoManager.editor.deleteWithIds([entity.id]);
  //   PhotoManager.clearFileCache();
  //
  //   print("Result of deleting media ${result}");
  //
  //
  //   if (result.isNotEmpty) {
  //     print("Media deleted successfully");
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text("Media Successfully Deleted")),
  //     );
  //   } else {
  //     print("Failed to delete media");
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text("Failed to delete file")),
  //     );
  //   }
  //
  // }catch(e) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(content: Text("Error deleting file: $e")),
  //   );
  // }
}



Future<void> deleteSaveStatusWithPhotoManager(BuildContext context, AssetEntity entity) async {

  try{


    final result = await PhotoManager.editor.deleteWithIds([entity.id]);
    PhotoManager.clearFileCache();

    print("Result of deleting media ${result}");


    if (result.isNotEmpty) {
      print("Media deleted successfully");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Media Successfully Deleted")),
      );
    } else {
      print("Failed to delete media");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete file")),
      );
    }

  }catch(e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error deleting file: $e")),
    );
  }

}

