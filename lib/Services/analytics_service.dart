import 'dart:io';
import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:storysaver/Utils/device_identifier.dart';
import 'package:storysaver/firebase_options.dart';

class AnalyticsService {
  final _instance = FirebaseAnalytics.instance;
  static bool _isFoundersVersion =
      const bool.fromEnvironment("founders_version");

  // In class AnalyticsService
  static Future<void> init() async {
    try {
      print('AnalyticsService: Forcing Firebase initialization...');

      // Check if a [DEFAULT] Firebase app already exists.
      FirebaseApp? existingDefaultApp;
      try {
        existingDefaultApp = Firebase
            .app(); // This gets the [DEFAULT] app or throws if not found.
      } catch (e) {
        // No [DEFAULT] app exists, which is fine.
        print('AnalyticsService: No existing [DEFAULT] Firebase app found.');
      }

      if (existingDefaultApp != null) {
        print(
            'AnalyticsService: Existing [DEFAULT] Firebase app found. Deleting it now...');
        await existingDefaultApp.delete();
        print('AnalyticsService: Existing [DEFAULT] Firebase app deleted.');
      }

      // Now, initialize Firebase. This will become the new [DEFAULT] app.
      print('AnalyticsService: Initializing new [DEFAULT] Firebase app...');

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('AnalyticsService: Firebase has been forcibly re-initialized.');

      if (_isFoundersVersion) {
        // print("AnalyticsService: Founders version, skipping Firebase init.");
        // return;
        // You can disable analytics collection like this:
        await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(false);
      }
      // You can disable analytics collection like this:
      // await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(false);

      // Initialize Crashlytics after a successful Firebase init.
      initCrashlytics();
    } catch (e) {
      print(
          'AnalyticsService: CRITICAL ERROR during forced Firebase re-initialization: $e');
      // Depending on your app's needs, you might want to rethrow the error
      // or handle it in a way that prevents the app from continuing in an unstable state.
      // For example: throw Exception('Failed to forcibly re-initialize Firebase: $e');
    }
  }

  static void initCrashlytics() {
    // Capture Flutter framework errors
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Capture uncaught asynchronous errors
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  static void testCrash() {
    throw const FormatException('Custom format error occurred');
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
          "value":
              valueMicros / 1e6, // Convert from micros to standard currency
          "currency": currency,
        },
      );
      print("ad_impression event logged successfully");
    } catch (e) {
      print("Error logging ad impression: $e");
    }
  }

  static Future<void> logShareApp() async {
    // await _instance.logEvent(name: "save status");
    // print('in Event logger _isFoundersVersion: $_isFoundersVersion');

    if (_isFoundersVersion == false) {
      try {
        // print("Logging save_status event...");
        await FirebaseAnalytics.instance.logEvent(
          name: "share_app",
          parameters: {
            "platform": Platform.operatingSystem,
          },
        );
        // print("save_status event logged successfully");
      } catch (e) {
        print("Error logging event: $e");
      }
    }
  }

  static Future<void> logGoToAppStorePage() async {
    // await _instance.logEvent(name: "save status");
    // print('in Event logger _isFoundersVersion: $_isFoundersVersion');

    if (_isFoundersVersion == false) {
      try {
        // print("Logging save_status event...");
        await FirebaseAnalytics.instance.logEvent(
          name: "goto_app_store_page",
          parameters: {
            "platform": Platform.operatingSystem,
          },
        );
        // print("save_status event logged successfully");
      } catch (e) {
        print("Error logging event: $e");
      }
    }
  }

  static Future<void> logGotoSplashScreen() async {
    // await _instance.logEvent(name: "save status");
    // print('in Event logger _isFoundersVersion: $_isFoundersVersion');

    if (_isFoundersVersion == false) {
      try {
        // print("Logging save_status event...");
        await FirebaseAnalytics.instance.logEvent(
          name: "goto_splash_screen",
          parameters: {
            "platform": Platform.operatingSystem,
          },
        );
        // print("save_status event logged successfully");
      } catch (e) {
        print("Error logging event: $e");
      }
    }
  }

  static Future<void> logGotoHomePage() async {
    // await _instance.logEvent(name: "save status");
    // print('in Event logger _isFoundersVersion: $_isFoundersVersion');

    if (_isFoundersVersion == false) {
      try {
        // print("Logging save_status event...");
        await FirebaseAnalytics.instance.logEvent(
          name: "goto_home_page",
          parameters: {
            "platform": Platform.operatingSystem,
          },
        );
        // print("save_status event logged successfully");
      } catch (e) {
        print("Error logging event: $e");
      }
    }
  }

  static Future<void> logShowGDPRConsentModal() async {
    // await _instance.logEvent(name: "save status");
    // print('in Event logger _isFoundersVersion: $_isFoundersVersion');

    if (_isFoundersVersion == false) {
      try {
        // print("Logging save_status event...");
        await FirebaseAnalytics.instance.logEvent(
          name: "show_gdpr_consent_request",
          parameters: {
            "platform": Platform.operatingSystem,
          },
        );
        // print("save_status event logged successfully");
      } catch (e) {
        print("Error logging event: $e");
      }
    }
  }

  static Future<void> logGrantGDPRConsent() async {
    // await _instance.logEvent(name: "save status");
    // print('in Event logger _isFoundersVersion: $_isFoundersVersion');

    if (_isFoundersVersion == false) {
      try {
        // print("Logging save_status event...");
        await FirebaseAnalytics.instance.logEvent(
          name: "grant_gdpr_consent",
          parameters: {
            "platform": Platform.operatingSystem,
          },
        );
        // print("save_status event logged successfully");
      } catch (e) {
        print("Error logging event: $e");
      }
    }
  }

  static Future<void> logGrantNotificationRequest() async {
    // await _instance.logEvent(name: "save status");
    // print('in Event logger _isFoundersVersion: $_isFoundersVersion');

    if (_isFoundersVersion == false) {
      try {
        // print("Logging save_status event...");
        await FirebaseAnalytics.instance.logEvent(
          name: "grant_notification_request",
          parameters: {
            "platform": Platform.operatingSystem,
          },
        );
        // print("save_status event logged successfully");
      } catch (e) {
        print("Error logging event: $e");
      }
    }
  }

  static Future<void> logOperationFailedAppError() async {
    // await _instance.logEvent(name: "save status");
    // print('in Event logger _isFoundersVersion: $_isFoundersVersion');

    if (_isFoundersVersion == false) {
      try {
        // print("Logging save_status event...");
        await FirebaseAnalytics.instance.logEvent(
          name: "app_error_operation_failed",
          parameters: {
            "platform": Platform.operatingSystem,
          },
        );
        // print("save_status event logged successfully");
      } catch (e) {
        print("Error logging event: $e");
      }
    }
  }

  ////////////////////////////////////////////////

  Future<void> logSaveStatus() async {
    // await _instance.logEvent(name: "save status");
    try {
      print("Logging save_status event...");
      await FirebaseAnalytics.instance.logEvent(
        name: "save_status",
        parameters: {
          "platform": Platform.operatingSystem,
        },
      );
      // print("save_status event logged successfully");
    } catch (e) {
      print("Error logging event: $e");
    }
  }

  static Future<void> logSwitchToBusinessMode() async {
    // await _instance.logEvent(name: "save status");
    // print('in Event logger _isFoundersVersion: $_isFoundersVersion');

    if (_isFoundersVersion == false) {
      try {
        // print("Logging save_status event...");
        await FirebaseAnalytics.instance.logEvent(
          name: "switch_to_business_mode",
          parameters: {
            "platform": Platform.operatingSystem,
          },
        );
        // print("save_status event logged successfully");
      } catch (e) {
        print("Error logging event: $e");
      }
    }
  }

  static Future<void> logSwitchToNormalMode() async {
    // await _instance.logEvent(name: "save status");
    // print('in Event logger _isFoundersVersion: $_isFoundersVersion');

    if (_isFoundersVersion == false) {
      try {
        // print("Logging save_status event...");
        await FirebaseAnalytics.instance.logEvent(
          name: "switch_to_normal_mode",
          parameters: {
            "platform": Platform.operatingSystem,
          },
        );
        // print("save_status event logged successfully");
      } catch (e) {
        print("Error logging event: $e");
      }
    }
  }

  static Future<void> logShowHelpModal() async {
    // await _instance.logEvent(name: "save status");
    // print('in Event logger _isFoundersVersion: $_isFoundersVersion');

    if (_isFoundersVersion == false) {
      try {
        // print("Logging save_status event...");
        await FirebaseAnalytics.instance.logEvent(
          name: "show_help",
          parameters: {
            "platform": Platform.operatingSystem,
          },
        );
        // print("save_status event logged successfully");
      } catch (e) {
        print("Error logging event: $e");
      }
    }
  }

  static Future<void> logRequestFolderPermission() async {
    // await _instance.logEvent(name: "save status");
    // print('in Event logger _isFoundersVersion: $_isFoundersVersion');

    if (_isFoundersVersion == false) {
      try {
        // print("Logging save_status event...");
        await FirebaseAnalytics.instance.logEvent(
          name: "request_whatsapp_folder_permission",
          parameters: {
            "platform": Platform.operatingSystem,
          },
        );
        // print("save_status event logged successfully");
      } catch (e) {
        print("Error logging event: $e");
      }
    }
  }

  static Future<void> logGrantWAFolderPermission() async {
    // await _instance.logEvent(name: "save status");
    // print('in Event logger _isFoundersVersion: $_isFoundersVersion');

    if (_isFoundersVersion == false) {
      try {
        // print("Logging save_status event...");
        await FirebaseAnalytics.instance.logEvent(
          name: "grant_whatsapp_folder_permission",
          parameters: {
            "platform": Platform.operatingSystem,
          },
        );
        // print("save_status event logged successfully");
      } catch (e) {
        print("Error logging event: $e");
      }
    }
  }

  static Future<void> logDeniedWAFolderPermission() async {
    // await _instance.logEvent(name: "save status");
    // print('in Event logger _isFoundersVersion: $_isFoundersVersion');

    if (_isFoundersVersion == false) {
      try {
        // print("Logging save_status event...");
        await FirebaseAnalytics.instance.logEvent(
          name: "denied_whatsapp_folder_permission",
          parameters: {
            "platform": Platform.operatingSystem,
          },
        );
        // print("save_status event logged successfully");
      } catch (e) {
        print("Error logging event: $e");
      }
    }
  }

  static Future<void> logRequestBusinessFolderPermission() async {
    // await _instance.logEvent(name: "save status");
    // print('in Event logger _isFoundersVersion: $_isFoundersVersion');

    if (_isFoundersVersion == false) {
      try {
        // print("Logging save_status event...");
        await FirebaseAnalytics.instance.logEvent(
          name: "request_business_folder_permission",
          parameters: {
            "platform": Platform.operatingSystem,
          },
        );
        // print("save_status event logged successfully");
      } catch (e) {
        print("Error logging event: $e");
      }
    }
  }

  static Future<void> logGrantBusinessFolderPermission() async {
    // await _instance.logEvent(name: "save status");
    // print('in Event logger _isFoundersVersion: $_isFoundersVersion');

    if (_isFoundersVersion == false) {
      try {
        // print("Logging save_status event...");
        await FirebaseAnalytics.instance.logEvent(
          name: "grant_business_folder_permission",
          parameters: {
            "platform": Platform.operatingSystem,
          },
        );
        // print("save_status event logged successfully");
      } catch (e) {
        print("Error logging event: $e");
      }
    }
  }

  static Future<void> logDeniedBusinessFolderPermission() async {
    // await _instance.logEvent(name: "save status");
    // print('in Event logger _isFoundersVersion: $_isFoundersVersion');

    if (_isFoundersVersion == false) {
      try {
        // print("Logging save_status event...");
        await FirebaseAnalytics.instance.logEvent(
          name: "denied_business_folder_permission",
          parameters: {
            "platform": Platform.operatingSystem,
          },
        );
        // print("save_status event logged successfully");
      } catch (e) {
        print("Error logging event: $e");
      }
    }
  }

  static Future<void> logGrantAndroidMediaFolderPermission() async {
    // await _instance.logEvent(name: "save status");
    // print('in Event logger _isFoundersVersion: $_isFoundersVersion');

    if (_isFoundersVersion == false) {
      try {
        // print("Logging save_status event...");
        await FirebaseAnalytics.instance.logEvent(
          name: "grant_Android/Media_folder_permission",
          parameters: {
            "platform": Platform.operatingSystem,
          },
        );
        // print("save_status event logged successfully");
      } catch (e) {
        print("Error logging event: $e");
      }
    }
  }

  static Future<void> logNavigateToFolderPermission() async {
    // await _instance.logEvent(name: "save status");
    // print('in Event logger _isFoundersVersion: $_isFoundersVersion');

    if (_isFoundersVersion == false) {
      try {
        // print("Logging save_status event...");
        await FirebaseAnalytics.instance.logEvent(
          name: "navigate_to_folder_permission_page",
          parameters: {
            "platform": Platform.operatingSystem,
          },
        );
        // print("save_status event logged successfully");
      } catch (e) {
        print("Error logging event: $e");
      }
    }
  }

//*****************************************
// Rating Dialog Event Logs
//*****************************************

  static Future<void> logRatingMaybeLater() async {
    if (_isFoundersVersion == false) {
      try {
        print("Logging rating_maybe_later event...");
        await FirebaseAnalytics.instance.logEvent(
          name: "rating_maybe_later",
          parameters: {
            "platform": Platform.operatingSystem,
          },
        );
        print("rating_maybe_later event logged successfully");
      } catch (e) {
        print("Error logging rating_maybe_later: $e");
      }
    }
  }

  static Future<void> logRatingNever() async {
    if (_isFoundersVersion == false) {
      try {
        print("Logging rating_never event...");
        await FirebaseAnalytics.instance.logEvent(
          name: "rating_never",
          parameters: {
            "platform": Platform.operatingSystem,
          },
        );
        print("rating_never event logged successfully");
      } catch (e) {
        print("Error logging rating_never: $e");
      }
    }
  }

  static Future<void> logRatingSubmitted(int stars) async {
    if (_isFoundersVersion == false) {
      try {
        print("Logging rating_submitted event with $stars stars...");
        await FirebaseAnalytics.instance.logEvent(
          name: "rating_submitted",
          parameters: {
            "platform": Platform.operatingSystem,
            "star_count": stars,
          },
        );
        print("rating_submitted event logged successfully");
      } catch (e) {
        print("Error logging rating_submitted: $e");
      }
    }
  }

  static Future<void> logRating4Stars() async {
    if (_isFoundersVersion == false) {
      try {
        print("Logging rating_4_stars event...");
        await FirebaseAnalytics.instance.logEvent(
          name: "rating_4_stars",
          parameters: {
            "platform": Platform.operatingSystem,
          },
        );
        print("rating_4_stars event logged successfully");
      } catch (e) {
        print("Error logging rating_4_stars: $e");
      }
    }
  }

  static Future<void> logRating5Stars() async {
    if (_isFoundersVersion == false) {
      try {
        print("Logging rating_5_stars event...");
        await FirebaseAnalytics.instance.logEvent(
          name: "rating_5_stars",
          parameters: {
            "platform": Platform.operatingSystem,
          },
        );
        print("rating_5_stars event logged successfully");
      } catch (e) {
        print("Error logging rating_5_stars: $e");
      }
    }
  }

//*****************************************
// User Journey Event Logs
//*****************************************

  static Future<void> logOnboardingComplete() async {
    if (_isFoundersVersion == false) {
      try {
        print("Logging onboarding_complete event...");
        await FirebaseAnalytics.instance.logEvent(
          name: "onboarding_complete",
          parameters: {
            "platform": Platform.operatingSystem,
          },
        );
        print("onboarding_complete event logged successfully");
      } catch (e) {
        print("Error logging onboarding_complete: $e");
      }
    }
  }

  static Future<void> logViewPaywallModal() async {
    if (_isFoundersVersion == false) {
      try {
        print("Logging view_paywall_modal event...");
        await FirebaseAnalytics.instance.logEvent(
          name: "view_paywall_modal",
          parameters: {
            "platform": Platform.operatingSystem,
          },
        );
        print("view_paywall_modal event logged successfully");
      } catch (e) {
        print("Error logging view_paywall_modal: $e");
      }
    }
  }

  static Future<void> logViewPaywall() async {
    if (_isFoundersVersion == false) {
      try {
        print("Logging view_paywall event...");
        await FirebaseAnalytics.instance.logEvent(
          name: "view_paywall",
          parameters: {
            "platform": Platform.operatingSystem,
          },
        );
        print("view_paywall event logged successfully");
      } catch (e) {
        print("Error logging view_paywall: $e");
      }
    }
  }

  static Future<void> logAutoSaveEnabled() async {
    if (_isFoundersVersion == false) {
      try {
        print("Logging auto_save_enabled event...");
        await FirebaseAnalytics.instance.logEvent(
          name: "auto_save_enabled",
          parameters: {
            "platform": Platform.operatingSystem,
          },
        );
        print("auto_save_enabled event logged successfully");
      } catch (e) {
        print("Error logging auto_save_enabled: $e");
      }
    }
  }

  static Future<void> logAutoSaveDisabled() async {
    if (_isFoundersVersion == false) {
      try {
        print("Logging auto_save_disabled event...");
        await FirebaseAnalytics.instance.logEvent(
          name: "auto_save_disabled",
          parameters: {
            "platform": Platform.operatingSystem,
          },
        );
        print("auto_save_disabled event logged successfully");
      } catch (e) {
        print("Error logging auto_save_disabled: $e");
      }
    }
  }

  static Future<void> logDownloadAll() async {
    if (_isFoundersVersion == false) {
      try {
        print("Logging download_all event...");
        await FirebaseAnalytics.instance.logEvent(
          name: "download_all",
          parameters: {
            "platform": Platform.operatingSystem,
          },
        );
        print("download_all event logged successfully");
      } catch (e) {
        print("Error logging download_all: $e");
      }
    }
  }

  static Future<void> logRemoveAdsClicked() async {
    if (_isFoundersVersion == false) {
      try {
        print("Logging remove_ads_clicked event...");
        await FirebaseAnalytics.instance.logEvent(
          name: "remove_ads_clicked",
          parameters: {
            "platform": Platform.operatingSystem,
          },
        );
        print("remove_ads_clicked event logged successfully");
      } catch (e) {
        print("Error logging remove_ads_clicked: $e");
      }
    }
  }

//*****************************************
// RevenueCat Event Logs
//*****************************************

  // Purchase Event
  static Future<void> logCustomPurchase({
    required String currency,
    required double price,
    required String productId,
    required String entitlementId,
  }) async {
    if (_isFoundersVersion == false) {
      try {
        print("Logging custom_purchase event...");
        await FirebaseAnalytics.instance.logEvent(
          name: "custom_purchase",
          parameters: {
            "currency": currency,
            "value": price,
            "item_id": productId,
            "item_name": entitlementId,
            "quantity": 1,
            "platform": Platform.operatingSystem,
          },
        );
        print("custom_purchase event logged successfully");
      } catch (e) {
        print("Error logging custom_purchase: $e");
      }
    }
  }

  // Paywall Cancelled Event
  static Future<void> logCustomPaywallCancelled({
    required String entitlementId,
  }) async {
    if (_isFoundersVersion == false) {
      try {
        print("Logging custom_paywall_cancelled event...");
        await FirebaseAnalytics.instance.logEvent(
          name: "custom_paywall_cancelled",
          parameters: {
            "entitlement_id": entitlementId,
            "platform": Platform.operatingSystem,
          },
        );
        print("custom_paywall_cancelled event logged successfully");
      } catch (e) {
        print("Error logging custom_paywall_cancelled: $e");
      }
    }
  }

  // Purchases Restored Event (with entitlement_id)
  static Future<void> logCustomPurchasesRestored({
    required String entitlementId,
  }) async {
    if (_isFoundersVersion == false) {
      try {
        print("Logging custom_purchases_restored event...");
        await FirebaseAnalytics.instance.logEvent(
          name: "custom_purchases_restored",
          parameters: {
            "entitlement_id": entitlementId,
            "platform": Platform.operatingSystem,
          },
        );
        print("custom_purchases_restored event logged successfully");
      } catch (e) {
        print("Error logging custom_purchases_restored: $e");
      }
    }
  }

  // Purchases Restored Event (with active entitlements count)
  static Future<void> logCustomPurchasesRestoredWithCount({
    required int activeEntitlementsCount,
  }) async {
    if (_isFoundersVersion == false) {
      try {
        print("Logging custom_purchases_restored event...");
        await FirebaseAnalytics.instance.logEvent(
          name: "custom_purchases_restored",
          parameters: {
            "active_entitlements": activeEntitlementsCount,
            "platform": Platform.operatingSystem,
          },
        );
        print("custom_purchases_restored event logged successfully");
      } catch (e) {
        print("Error logging custom_purchases_restored: $e");
      }
    }
  }

  // Customer Center Viewed Event
  static Future<void> logCustomCustomerCenterViewed() async {
    if (_isFoundersVersion == false) {
      try {
        print("Logging custom_customer_center_viewed event...");
        await FirebaseAnalytics.instance.logEvent(
          name: "custom_customer_center_viewed",
          parameters: {
            "platform": Platform.operatingSystem,
          },
        );
        print("custom_customer_center_viewed event logged successfully");
      } catch (e) {
        print("Error logging custom_customer_center_viewed: $e");
      }
    }
  }
  //*****************************************
  // Retention & Targeting Event Logs
  //*****************************************

  /// Log standardized retention events (e.g., app_open, session_start, milestones)
  static Future<void> logRetentionEvent(
      String eventName, Map<String, dynamic> params) async {
    if (_isFoundersVersion == false) {
      try {
        final Map<String, Object> finalParams = {
          "platform": Platform.operatingSystem,
        };

        // Safely add params that are non-null Objects
        params.forEach((key, value) {
          if (value != null) {
            finalParams[key] = value as Object;
          }
        });

        print("Logging retention event: $eventName");
        await FirebaseAnalytics.instance.logEvent(
          name: eventName,
          parameters: finalParams,
        );
      } catch (e) {
        print("Error logging retention event ($eventName): $e");
      }
    }
  }

  /// Log user segment changes (e.g., became_loyal, at_risk)
  static Future<void> logUserSegmentEvent(
      String segmentEvent, Map<String, dynamic> params) async {
    if (_isFoundersVersion == false) {
      try {
        final Map<String, Object> finalParams = {
          "platform": Platform.operatingSystem,
        };

        params.forEach((key, value) {
          if (value != null) {
            finalParams[key] = value as Object;
          }
        });

        print("Logging user segment event: $segmentEvent");
        await FirebaseAnalytics.instance.logEvent(
          name: segmentEvent,
          parameters: finalParams,
        );
      } catch (e) {
        print("Error logging user segment event ($segmentEvent): $e");
      }
    }
  }

  /// Log targeting events (e.g., offer_shown, feature_targeted)
  static Future<void> logTargetingEvent(
      String eventName, Map<String, dynamic> params) async {
    if (_isFoundersVersion == false) {
      try {
        final Map<String, Object> finalParams = {
          "platform": Platform.operatingSystem,
        };

        params.forEach((key, value) {
          if (value != null) {
            finalParams[key] = value as Object;
          }
        });

        print("Logging targeting event: $eventName");
        await FirebaseAnalytics.instance.logEvent(
          name: eventName,
          parameters: finalParams,
        );
      } catch (e) {
        print("Error logging targeting event ($eventName): $e");
      }
    }
  }
}
