import 'package:onesignal_flutter/onesignal_flutter.dart';

class PushNotification {
  static const ONE_SIGNAL_ID =
      const String.fromEnvironment("one_signal_app_id");

  Future<void> initializeAndPrompt() async {
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

      OneSignal.InAppMessages.addClickListener(
          (OSInAppMessageClickEvent event) {
        // CORRECT for handling clicks
        print("PushNotification: In-App Message clicked!");
        print("PushNotification: Click action ID: ${event.result.actionId}");

        if (event.result.actionId == 'prompt_for_push') {
          print(
              "PushNotification: 'prompt_for_push' action recognized. Triggering OS permission dialog.");
          promptPlatformPermission();
        }
        // You can handle other action IDs for other In-App Message buttons here
      });

      // Monitor subscription state changes
      OneSignal.User.pushSubscription.addObserver((state) {
        print("PushNotification: Subscription state changed!");
        print("PushNotification: User ID: ${state.current.id}");
        print("PushNotification: Push Token: ${state.current.token}");
        print("PushNotification: Opted In: ${state.current.optedIn}");

        if (!state.current.optedIn) {
          print(
              "PushNotification: WARNING - User is NOT opted in to push notifications!");
        }
      });

      // Log initial subscription state
      final subscriptionState = OneSignal.User.pushSubscription;
      print("PushNotification: Initial subscription state:");
      print("PushNotification: User ID: ${subscriptionState.id}");
      print("PushNotification: Token: ${subscriptionState.token}");
      print("PushNotification: Opted In: ${subscriptionState.optedIn}");

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

  static Future<void> sendTestNotification() async {
    try {
      // Get the current user's OneSignal ID
      final userId = OneSignal.User.pushSubscription.id;

      if (userId == null || userId.isEmpty) {
        print(
            "PushNotification: No user ID found. User may not be subscribed.");
        throw Exception("User not subscribed to push notifications");
      }

      print("PushNotification: Sending test notification to user ID: $userId");

      // Note: To actually send a notification, you need to use OneSignal's REST API
      // This requires your OneSignal REST API Key which should be kept server-side
      // For testing, you can manually send a notification from the OneSignal dashboard
      // or implement a server endpoint that calls the OneSignal API

      throw Exception(
          "Test notifications must be sent from OneSignal Dashboard or via REST API");
    } catch (e) {
      print("PushNotification: Error sending test notification: $e");
      rethrow;
    }
  }

  static Future<String?> getUserId() async {
    return OneSignal.User.pushSubscription.id;
  }
}
