
import 'package:onesignal_flutter/onesignal_flutter.dart';

class PushNotification {

  static const ONE_SIGNAL_ID =  const String.fromEnvironment("one_signal_app_id");

  void initialize() {

    // Enable verbose logging for debugging (remove in production)
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    // Initialize with your OneSignal App ID
    OneSignal.initialize(ONE_SIGNAL_ID);
    // Use this method to prompt for push notifications.
    // We recommend removing this method after testing and instead use In-App Messages to prompt for notification permission.
    OneSignal.Notifications.requestPermission(false);

  }
}