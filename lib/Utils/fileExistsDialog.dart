

import 'dart:io';

import 'package:flutter/material.dart';

bool checkFileExists(String? filePath)  {
  if (filePath == null || filePath.isEmpty) {
    // showErrorDialog("Media path is missing!");
    return false;
  }

  File file = File(filePath);
  bool exists =  file.existsSync();

  if (!exists) {
    // showErrorDialog("File does not exist at the given path!");
    return false;
  }

  return true;
}

void showErrorDialog(BuildContext context, String message) {
  Future.delayed(Duration.zero, () {
    showDialog(
      context: context,
      // barrierDismissible: false, // Prevents user from tapping outside to dismiss
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text("Error"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.popUntil(dialogContext, (route) => route.isFirst);
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  });
}
