import 'package:flutter/material.dart';
import 'package:storysaver/Utils/saveStatus.dart';
import 'package:storysaver/Services/AppRatingService.dart';
import 'package:storysaver/Utils/SavedMediaManager.dart';

class BatchDownloadService {
  static Future<void> downloadAll(BuildContext context, List<String> imagePaths,
      List<String> videoPaths) async {
    List<String> allPaths = [...imagePaths, ...videoPaths];

    if (allPaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No items to download")),
      );
      return;
    }

    int total = allPaths.length;
    ValueNotifier<int> completedNotifier = ValueNotifier(0);
    int successCount = 0;
    int failCount = 0;

    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Downloading All..."),
          content: ValueListenableBuilder<int>(
            valueListenable: completedNotifier,
            builder: (context, completed, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(
                    value: total > 0 ? completed / total : 0,
                    backgroundColor: Colors.grey[300],
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                  const SizedBox(height: 20),
                  Text("$completed of $total completed"),
                ],
              );
            },
          ),
        );
      },
    );

    // Process downloads
    for (String path in allPaths) {
      bool success = await saveStatusSilent(context, path);
      if (success) {
        successCount++;
        // Update the cache and notify listeners
        await SavedMediaManager().saveMedia(path);
      } else {
        failCount++;
      }

      completedNotifier.value++;

      // Allow UI to update
      await Future.delayed(Duration.zero);
    }

    // Close the progress dialog
    Navigator.of(context, rootNavigator: true).pop();

    // Show summary
    String message = "Downloaded $successCount of $total items.";
    if (failCount > 0) {
      message += " ($failCount failed)";
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );

    // Trigger rating if eligible
    if (successCount > 0) {
      AdvancedAppRatingService.trackDownloadAndShowRatingIfNeeded(context);
    }
  }
}
