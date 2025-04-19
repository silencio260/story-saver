import 'package:flutter/widgets.dart';

class PermissionProvider extends ChangeNotifier {
  bool _hasStoragePermission = false;
  bool? _isWhatsAppStatusSafAvailable = null;

  bool get hasStoragePermission => _hasStoragePermission;
  bool? get isWhatsAppStatusSafAvailable => _isWhatsAppStatusSafAvailable;

  void setHasStoragePermission(bool value) {
    _hasStoragePermission = value;
    notifyListeners();
  }

  void setIsWhatsAppStatusSafAvailable(bool value) {
    _isWhatsAppStatusSafAvailable = value;
    notifyListeners();
  }
}
