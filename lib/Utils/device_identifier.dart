import 'dart:io'; // To check platform
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:device_info_plus/device_info_plus.dart'; // For device information
import 'package:app_tracking_transparency/app_tracking_transparency.dart'; // For ATT prompt on iOS

class DeviceIdentifier {
  static Future<String> getDeviceIdentifier() async {
    String? deviceId;

    // iOS: Handle App Tracking Transparency (ATT) and IDFA
    if (Platform.isIOS) {
      final TrackingStatus status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        // Request ATT permission
        await AppTrackingTransparency.requestTrackingAuthorization();
      }

      final TrackingStatus newStatus = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (newStatus == TrackingStatus.authorized) {
        deviceId = await AppTrackingTransparency.getAdvertisingIdentifier();
      }
    }

    // Fallback to `device_info_plus` for Android and iOS if ATT fails
    if (deviceId == null || deviceId.isEmpty) {
      final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
        deviceId = androidInfo.id; // Unique Android ID
      } else if (Platform.isIOS) {
        final IosDeviceInfo iosInfo = await deviceInfoPlugin.iosInfo;
        deviceId = iosInfo.identifierForVendor; // Unique iOS device ID
      }
    }

    // Fallback to UUID stored in SharedPreferences
    if (deviceId == null || deviceId.isEmpty) {
      deviceId = await _getFallbackUuid();
    }

    return deviceId;
  }

  static Future<String> _getFallbackUuid() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? uuid = prefs.getString('device_uuid');

    if (uuid == null) {
      uuid = const Uuid().v4(); // Generate a new UUID
      await prefs.setString('device_uuid', uuid);
    }

    return uuid;
  }
}
