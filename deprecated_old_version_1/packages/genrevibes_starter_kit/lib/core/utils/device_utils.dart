import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Utilities for identifying the device
class DeviceUtils {
  static const String _kDeviceIdKey = 'sk_device_id';
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Get a stable unique identifier for this device install
  ///
  /// This ID persists across app launches but is reset if the app is uninstalled.
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_kDeviceIdKey)) {
      return prefs.getString(_kDeviceIdKey)!;
    }

    String deviceId;
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        deviceId = androidInfo.id; // stable android ID
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? const Uuid().v4();
      } else {
        deviceId = const Uuid().v4();
      }
    } catch (e) {
      deviceId = const Uuid().v4();
    }

    await prefs.setString(_kDeviceIdKey, deviceId);
    return deviceId;
  }
}
