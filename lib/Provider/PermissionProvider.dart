import 'package:flutter/widgets.dart';

class PermissionProvider extends ChangeNotifier {
  bool _hasStoragePermission = false;

  bool get hasStoragePermission => _hasStoragePermission;

  void setHasStoragePermission(bool value) {
    _hasStoragePermission = value;
    notifyListeners();
  }
}
