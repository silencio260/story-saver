
import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:storysaver/Monetization/Ads/Admob/adConfig.dart';
import 'package:storysaver/Utils/device_identifier.dart';
import 'package:storysaver/firebase_options.dart';

class AnalyticsService {
  final _instance = FirebaseAnalytics.instance;

  // In class AnalyticsService
  static Future<void> init() async {
    try {
      print('AnalyticsService: Forcing Firebase initialization...');

      // Check if a [DEFAULT] Firebase app already exists.
      FirebaseApp? existingDefaultApp;
      try {
        existingDefaultApp = Firebase.app(); // This gets the [DEFAULT] app or throws if not found.
      } catch (e) {
        // No [DEFAULT] app exists, which is fine.
        print('AnalyticsService: No existing [DEFAULT] Firebase app found.');
      }

      if (existingDefaultApp != null) {
        print('AnalyticsService: Existing [DEFAULT] Firebase app found. Deleting it now...');
        await existingDefaultApp.delete();
        print('AnalyticsService: Existing [DEFAULT] Firebase app deleted.');
      }

      // Now, initialize Firebase. This will become the new [DEFAULT] app.
      print('AnalyticsService: Initializing new [DEFAULT] Firebase app...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('AnalyticsService: Firebase has been forcibly re-initialized.');

    } catch (e) {
      print('AnalyticsService: CRITICAL ERROR during forced Firebase re-initialization: $e');
      // Depending on your app's needs, you might want to rethrow the error
      // or handle it in a way that prevents the app from continuing in an unstable state.
      // For example: throw Exception('Failed to forcibly re-initialize Firebase: $e');
    }
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

  Future<void> logAdImpressions({
    required String adUnitId,
    required String adFormat,
    required double valueMicros,
    required String currency,
  }) async {
    try {
      print("Logging ad_impression event...");
      await FirebaseAnalytics.instance.logEvent(
        name: "ad_impression",
        parameters: {
          "ad_platform": "AdMob",
          "ad_unit_id": adUnitId,
          "ad_format": adFormat, // e.g., "banner", "interstitial"
          "value": valueMicros / 1e6, // Convert from micros to standard currency
          "currency": currency,
        },
      );
      print("ad_impression event logged successfully");
    } catch (e) {
      print("Error logging ad impression: $e");
    }
  }


}