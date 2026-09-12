import 'package:flutter/material.dart';

import '../../../../analytics/data/services/analytics_service.dart';
import '../../../../settings/presentation/services/rating_prompt.dart';
import '../../../data/datasources/local/saved_media_cache.dart';
import 'media_file_operations_legacy.dart';

class BatchDownloadService {
  static Future<void> downloadAll(
    BuildContext context,
    List<String> imagePaths,
    List<String> videoPaths,
  ) async {
    // Track analytics
    await AnalyticsService.logDownloadAll();

    List<String> allPaths = [...imagePaths, ...videoPaths];

    if (allPaths.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No items to download")));
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
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.green,
                    ),
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
      await AnalyticsService.track(
        success ? 'save_status' : 'save_status_failed',
        {'source': 'bulk'},
      );
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

    await AnalyticsService.track('download_all_completed', {
      'total_count': total,
      'saved_count': successCount,
      'failed_count': failCount,
    });
    // Close the progress dialog
    Navigator.of(context, rootNavigator: true).pop();

    // Show summary
    String message = "Downloaded $successCount of $total items.";
    if (failCount > 0) {
      message += " ($failCount failed)";
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));

    // Trigger rating if eligible
    if (successCount > 0) {
      RatingPrompt.recordDownload(context);
    }
  }
}
