import 'package:permission_handler/permission_handler.dart';


// Request storage permission
Future<bool> getStoragePermission() async {
  final status = await Permission.storage.request();
  if (status.isGranted) {
    return true;
  } else {
    final storagePermission = await Permission.manageExternalStorage.request();
    if (storagePermission.isGranted) {
      return true;
    } else {
      openAppSettings(); // Optionally prompt user to open settings for manual permission
      return false;
    }
  }
}