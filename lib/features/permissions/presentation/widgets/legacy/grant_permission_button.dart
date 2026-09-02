import 'package:flutter/material.dart';

import '../../../data/datasources/app_storage_permission.dart';

/// Compatibility wrapper for the original `GrantPermissionButton` helper.
Widget GrantPermissionButton(
  BuildContext context, {
  VoidCallback? onPermissionGranted,
}) {
  Future<void> requestPermission() async {
    final granted = await AppStoragePermission().getStoragePermission();
    if (!context.mounted) return;
    if (granted) onPermissionGranted?.call();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(granted ? 'Permission Granted ✅' : 'Permission Denied ❌'),
      ),
    );
  }

  return Center(
    child: ElevatedButton(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all<Color>(Colors.green),
      ),
      onPressed: requestPermission,
      child: const Text(
        'Grant Permission',
        style: TextStyle(color: Colors.white),
      ),
    ),
  );
}
