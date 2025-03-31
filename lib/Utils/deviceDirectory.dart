import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'package:external_path/external_path.dart';
import 'package:storysaver/Constants/constant.dart';

class DeviceFileInfo {

  String _savedMediaPath = "Pictures/${AppConstants.SAVED_STORY_PATH}";
  String get savedMediaPath => _savedMediaPath;

  Future<String> GetSavedMediaAbsolutePath() async {

    var path = await ExternalPath.getExternalStorageDirectories();

    var filePath = path![0] + '/' + _savedMediaPath;

    return filePath;
  }

  Future<String> GetSavedMediaBasedOnDevice() async {

    if (Platform.isAndroid) {
      final androidVersion = await getAndroidVersion();
      if( androidVersion! >= 10) {
        return _savedMediaPath;
      }
    }

    return await GetSavedMediaAbsolutePath();
  }

  static Future<int?> getAndroidVersion() async {
    if (Platform.isAndroid) {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return int.tryParse(androidInfo.version.release); // Returns Android version as an int
    }
    return null;
  }

  static void checkVersion() async {
    int? version = await getAndroidVersion();
    print("Android Version: $version");
  }
}
