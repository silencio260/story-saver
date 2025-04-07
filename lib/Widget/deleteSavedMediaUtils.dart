
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:storysaver/Provider/savedMediaProvider.dart';
import 'package:storysaver/Utils/SavedMediaManager.dart';
import 'package:storysaver/Utils/saveStatus.dart';

class deleteSavedMeidaUtils {

  void confirmFileDeleteDialog(BuildContext context, String message,GetSavedMediaProvider file, int index) {
    Future.delayed(Duration.zero, () {
      showDialog(
        context: context,
        // barrierDismissible: false, // Prevents user from tapping outside to dismiss
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: Text("Error"),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.popUntil(dialogContext, (route) => route.isFirst);
                },
                child: Text("Cancel", style: TextStyle(color: Colors.grey),),
              ),
              TextButton(
                onPressed: () {
                  // _deleteMedia(context, file.getMediaFile[index])
                  deleteMedia(context, file, index);
                  Navigator.popUntil(dialogContext, (route) => route.isFirst);
                },
                child: Text("OK", style: TextStyle(color: Colors.red),),
              ),
            ],
          );
        },
      );
    });
  }

  void deleteMedia(BuildContext context, GetSavedMediaProvider file, int index) async {

    File? fileToDelete = await file.getMediaFile[index].file;
    String? filePath = fileToDelete?.path;
    String fileName = file.getMediaFile[index].title.toString();
    print('delete_path ${filePath} $index ${fileName}');

    deleteSaveStatusFromDevice(context, filePath!);
    SavedMediaManager().deleteMediaFromCache(fileName);
    file.removeFrom(index);
  }
}