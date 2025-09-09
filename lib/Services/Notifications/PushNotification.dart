
import 'package:onesignal_flutter/onesignal_flutter.dart';

class PushNotification {

  static const ONE_SIGNAL_ID =  const String.fromEnvironment("one_signal_app_id");

  Future<void> initializeAndPrompt()  async {
    try {
      // Enable verbose logging for debugging (remove in production)
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      // Initialize with your OneSignal App ID
      OneSignal.initialize(ONE_SIGNAL_ID);
      // Use this method to prompt for push notifications.
      // We recommend removing this method after testing and instead use In-App Messages to prompt for notification permission.

      await OneSignal.Notifications.requestPermission(false);


    } catch (e) {
      print("Error initializing OneSignal: $e");
    }
  }

  void initialize() {
    try {
      // Enable verbose logging for debugging (remove in production)
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      // Initialize with your OneSignal App ID
      OneSignal.initialize(ONE_SIGNAL_ID);
      // Use this method to prompt for push notifications.
      // We recommend removing this method after testing and instead use In-App Messages to prompt for notification permission.

      // OneSignal.User.pushSubscription.optedIn();
      // print("Notification permission: ${OneSignal.Notifications. .pushSubscription.optedIn}");

      print("Notification permission: ${OneSignal.Notifications.permission}");

      // OneSignal.InAppMessages..clearAll();

      OneSignalInAppMessages();

      // OneSignal.User..optIn();

      // OneSignal.Notifications.requestPermission(false);

      // Clear previous impressions for testing
      OneSignal.InAppMessages.clearTriggers();
      Future.delayed(Duration(milliseconds: 100));
      OneSignal.InAppMessages.addTrigger("show_permission_prompt", "true");

      OneSignal.InAppMessages.addClickListener((OSInAppMessageClickEvent event) { // CORRECT for handling clicks
        print("PushNotification: In-App Message clicked!");
        print("PushNotification: Click action ID: ${event.result.actionId}");

        if (event.result.actionId == 'prompt_for_push') {
          print("PushNotification: 'prompt_for_push' action recognized. Triggering OS permission dialog.");
          promptPlatformPermission();
        }
        // You can handle other action IDs for other In-App Message buttons here
      });



      // final observer = (bool hasPermission) {
      //   print("Notification permission: $hasPermission");
      // };
      //
      // OneSignal.Notifications.addPermissionObserver(observer);
      //
      // // Remove later if needed
      // OneSignal.Notifications.removePermissionObserver(observer);


    } catch (e) {
      print("Error initializing OneSignal: $e");
    }
  }

  static Future<void> promptPlatformPermission() async {
    // This will show the native OS dialog for push notification permission.
    await OneSignal.Notifications.requestPermission(false);
    print("PushNotification: OS permission dialog has been requested.");
  }
}