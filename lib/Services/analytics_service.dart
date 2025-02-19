
import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:storysaver/Utils/device_identifier.dart';
import 'package:storysaver/firebase_options.dart';

class AnalyticsService {
  final _instance = FirebaseAnalytics.instance;

  static Future<void> init() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  static Future<void> logAppOpen() async {
    // Obtain the unique device identifier
    final String uniqueDeviceId = await DeviceIdentifier.getDeviceIdentifier();

    // Determine platform for analytics parameters
    final String platform = Platform.isAndroid ? 'android' : 'ios';

    // Log the app open event with Firebase Analytics
    await FirebaseAnalytics.instance.logAppOpen(
      parameters: {
        'platform': platform,
        'unique_device_id': uniqueDeviceId,
      },
    );
  }

  Future<void> logSaveStatus() async {
    // await _instance.logEvent(name: "save status");
    try {
      print("Logging save_status event...");
      await  FirebaseAnalytics.instance.logEvent(
        name: "save_status",
        parameters: {
          "platform": Platform.operatingSystem,
        },
      );
      print("save_status event logged successfully");
    } catch (e) {
      print("Error logging event: $e");
    }
  }


}