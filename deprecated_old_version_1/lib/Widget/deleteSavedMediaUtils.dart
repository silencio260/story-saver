import 'dart:io';

import 'package:flutter/material.dart';
import 'package:storysaver/Provider/savedMediaProvider.dart';
import 'package:storysaver/Utils/SavedMediaManager.dart';
import 'package:storysaver/Utils/saveStatus.dart';
import 'package:storysaver/Utils/deviceDirectory.dart';

class deleteSavedMeidaUtils {
  void confirmFileDeleteDialog(BuildContext context, String message,
      GetSavedMediaProvider file, int index) {
    Future.delayed(Duration.zero, () {
      showDialog(
        context: context,
        // barrierDismissible: false, // Prevents user from tapping outside to dismiss
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: Text("Confirm"),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.popUntil(dialogContext, (route) => route.isFirst);
                },
                child: Text(
                  "Cancel",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () {
                  // _deleteMedia(context, file.getMediaFile[index])
                  deleteMedia(context, file, index);
                  Navigator.popUntil(dialogContext, (route) => route.isFirst);
                },
                child: Text(
                  "OK",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          );
        },
      );
    });
  }

  void deleteMedia(
      BuildContext context, GetSavedMediaProvider file, int index) async {
    File? fileToDelete = await file.getMediaFile[index].file;
    String? filePath = fileToDelete?.path;
    String fileName = file.getMediaFile[index].title.toString();
    print('delete_path ${filePath} $index ${fileName}');

    deleteSaveStatusFromDevice(context, filePath!);
    SavedMediaManager().deleteMediaFromCache(fileName);
    file.removeFrom(index);
  }

  void confirmDeleteAllDialog(
      BuildContext context, GetSavedMediaProvider provider) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text("Confirm Delete All"),
          content: Text(
              "Are you sure you want to delete ALL saved media? This action cannot be undone."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(
                "Cancel",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                deleteAllMedia(context, provider);
              },
              child: Text(
                "Delete All",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteAllMedia(
      BuildContext context, GetSavedMediaProvider provider,
      {bool showCompletionSnackBar = true}) async {
    try {
      // 1. Get the directory
      String savedPath = await DeviceFileInfo().GetSavedMediaAbsolutePath();
      Directory savedDir = Directory(savedPath);

      if (await savedDir.exists()) {
        List<FileSystemEntity> files = savedDir.listSync();
        for (var file in files) {
          if (file is File) {
            String filePath = file.path;
            String fileName = file.uri.pathSegments.last;

            // 2. Delete using the system
            await deleteSaveStatusFromDevice(context, filePath,
                showSnackBar: false);
            SavedMediaManager().deleteMediaFromCache(fileName);
          }
        }
      }

      // 3. Clear provider
      provider.clearAll();

      // 4. Show success
      if (showCompletionSnackBar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("All media deleted successfully")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting all media: $e")),
      );
    }
  }
}
