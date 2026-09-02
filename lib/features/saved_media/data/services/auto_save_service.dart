import 'dart:async';
import 'dart:io';
import 'package:docman/docman.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storysaver/core/utils/legacy_app_constants.dart';
import 'package:storysaver/features/saved_media/data/datasources/local/saved_media_cache.dart';
import 'package:storysaver/features/saved_media/data/datasources/local/media_file_operations.dart';
import 'package:workmanager/workmanager.dart';

class AutoSaveService {
  static const String taskName = "autoSaveTask";
  static const String devTaskName = "devAutoSaveTask";
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Initialize WorkManager and Notifications
  static Future<void> initialize() async {
    // Notification setup
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // WorkManager setup is done in main.dart via callbackDispatcher
  }

  // Register the periodic background task (1 hour)
  static Future<void> registerPeriodicTask() async {
    await Workmanager().registerPeriodicTask(
      taskName,
      taskName,
      frequency: const Duration(hours: 1),
      constraints: Constraints(
        // networkType: NetworkType.not_required,
        requiresBatteryNotLow: true,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );
    print("AutoSaveService: Periodic task registered");
  }

  // Cancel all background tasks
  static Future<void> cancelAllTasks() async {
    await Workmanager().cancelAll();
    print("AutoSaveService: All tasks cancelled");
  }

  // --- Dev Test Mode (High Frequency Timer) ---
  static Timer? _devTimer;

  static void startDevTestMode() {
    stopDevTestMode(); // Ensure no duplicates

    // Re-initialize notifications if they might have been lost (though plugin handles this well usually)
    // But more importantly, ensure _devTimer is fresh.

    print("AutoSaveService: Starting Dev Test Mode (10s interval)");
    _devTimer = Timer.periodic(const Duration(seconds: 50), (timer) async {
      print("AutoSaveService: Dev Timer Tick");
      // Re-check initialization if needed, or just run logic
      await _checkAndSaveNewStatuses(isDevMode: true);
    });
  }

  static void stopDevTestMode() {
    if (_devTimer != null) {
      _devTimer!.cancel();
      _devTimer = null;
      print("AutoSaveService: Dev Test Mode Stopped");
    }
  }

  // Check SharedPreferences and resume Dev Mode if it was enabled
  static Future<void> checkAndResumeDevMode() async {
    final prefs = await SharedPreferences.getInstance();
    final isDevModeEnabled =
        prefs.getBool("is_dev_auto_save_test_mode") ?? false;

    if (isDevModeEnabled) {
      print("AutoSaveService: Resuming Dev Test Mode from persistent state");
      startDevTestMode();
    }
  }

  // --- Core Logic ---

  // This method is called by WorkManager (background) or Timer (dev mode)
  static Future<void> executeBackgroundTask() async {
    print("AutoSaveService: Executing background task");
    await _checkAndSaveNewStatuses();
  }

  static Future<void> _checkAndSaveNewStatuses({bool isDevMode = false}) async {
    try {
      // 1. Check if feature is enabled (double check for background)
      final prefs = await SharedPreferences.getInstance();
      // We assume the caller checks permission/premium, but good to verify
      // bool isPremium = ... (Check premium status if possible in background, or rely on UI toggle state)

      // 2. Get accessible files using DocMan (Headless)
      // Note: DocMan relies on persisted permissions.
      List<PersistedPermission> accessiblePath = await DocMan.perms.list(
        files: false,
        directories: true,
      );

      List<File> allStatusFiles = [];

      // Helper method to navigate to status folder
      Future<DocumentFile?> navigateToStatusFolder(
        DocumentFile androidMediaDir,
        bool isBusiness,
      ) async {
        try {
          var relativePath = "com.whatsapp/WhatsApp/Media/.Statuses";
          if (isBusiness) {
            relativePath = "com.whatsapp.w4b/WhatsApp Business/Media/.Statuses";
          }

          // Extract base docId ("primary:Android/media")
          final baseDocId = Uri.decodeComponent(
            androidMediaDir
                .toString()
                .split('/tree/')
                .last
                .split('/document/')
                .first,
          );

          // Build the full docId with the relative path
          final fullDocId = "$baseDocId/$relativePath";

          // Encode and build final content:// URI
          final fullUri =
              "content://com.android.externalstorage.documents/tree/${Uri.encodeComponent(baseDocId)}/document/${Uri.encodeComponent(fullDocId)}";

          final doc = await DocumentFile.fromUri(fullUri);
          if (doc != null && await doc.exists) {
            return doc;
          }
        } catch (e) {
          print("AutoSaveService: Error navigating to status folder: $e");
        }
        return null;
      }

      // Helper to process a directory and add files
      Future<void> processStatusDirectory(DocumentFile statusDir) async {
        try {
          print("AutoSaveService: Processing directory: ${statusDir.uri}");
          List<DocumentFile> documents = await statusDir.listDocuments(
            mimeTypes: ['image/*', 'video/*'],
          );

          for (var doc in documents) {
            File? cachedFile = await doc.cache();
            if (cachedFile != null) {
              allStatusFiles.add(cachedFile);
            }
          }
        } catch (e) {
          print("AutoSaveService: Error processing directory: $e");
        }
      }

      for (final permission in accessiblePath) {
        final decodedUri = Uri.decodeFull(permission.uri);
        print("AutoSaveService: Checking URI: $decodedUri");

        // 1. Check for direct access (Specific .Statuses folder)
        if (decodedUri.contains(".Statuses")) {
          final statusDir = await DocumentFile.fromUri(permission.uri);
          if (statusDir != null && await statusDir.exists) {
            await processStatusDirectory(statusDir);
          }
        }
        // 2. Check for Android/media access (Root access)
        else if (decodedUri.contains("Android") &&
            decodedUri.contains("media")) {
          final androidMediaDir = await DocumentFile.fromUri(permission.uri);
          if (androidMediaDir != null && await androidMediaDir.exists) {
            // Check Regular WhatsApp
            final regularDir = await navigateToStatusFolder(
              androidMediaDir,
              false,
            );
            if (regularDir != null && await regularDir.exists) {
              await processStatusDirectory(regularDir);
            }

            // Check WhatsApp Business
            final businessDir = await navigateToStatusFolder(
              androidMediaDir,
              true,
            );
            if (businessDir != null && await businessDir.exists) {
              await processStatusDirectory(businessDir);
            }
          }
        }
      }

      print(
        "AutoSaveService: Found ${allStatusFiles.length} potential status files",
      );

      // 3. Compare with SavedMediaManager
      final mediaManager = SavedMediaManager();
      int savedCount = 0;

      for (File file in allStatusFiles) {
        // Check if already saved
        // Note: isMediaSaved checks SharedPreferences cache
        if (!await mediaManager.isMediaSaved(file.path)) {
          print("AutoSaveService: Saving new file: ${file.path}");

          // 4. Save the file
          bool success = await saveStatusBackground(file.path);
          if (success) {
            // Update cache so we don't save it again next time
            await mediaManager.saveMedia(file.path);
            savedCount++;
          }
        }
      }

      // 5. Notify User
      if (savedCount > 0) {
        await _showNotification(savedCount);
      } else if (isDevMode) {
        print("AutoSaveService: No new files to save.");
      }
    } catch (e) {
      print("AutoSaveService Error: $e");
    }
  }

  static Future<void> _showNotification(int count) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'auto_save_channel',
          'Auto Save Notifications',
          channelDescription: 'Notifications for auto-saved statuses',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: 'ic_stat_download', // Custom icon
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    // Ensure channel exists (critical for Android 8+)
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'auto_save_channel',
            'Auto Save Notifications',
            description: 'Notifications for auto-saved statuses',
            importance: Importance.defaultImportance,
          ),
        );

    await flutterLocalNotificationsPlugin.show(
      0,
      'Auto Save Complete',
      'Saved $count new statuses to your gallery.',
      platformChannelSpecifics,
    );
  }

  static Future<void> showTestNotification() async {
    await _showNotification(1);
  }
}
