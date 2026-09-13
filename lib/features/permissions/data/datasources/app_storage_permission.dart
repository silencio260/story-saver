import 'package:flutter/services.dart';
import 'package:docman/docman.dart';
import 'package:photo_manager/photo_manager.dart';

/// Folder access and gallery access are separate. Checking either never prompts.
class AppStoragePermission {
  Future<bool> getStoragePermission() async =>
      (await PhotoManager.requestPermissionExtend()).hasAccess;

  Future<bool> checkIfWeHaveStoragePermission() =>
      checkForStoragePermissionOnly();

  Future<bool> checkForStoragePermissionOnly() async =>
      (await PhotoManager.getPermissionState(
        requestOption: const PermissionRequestOption(),
      )).hasAccess;

  // Kept for legacy explicit gallery actions; never requests notifications or
  // all-files access. SAF browsing needs neither of these permissions.
  Future<bool> forceRequestAllPermissions() => getStoragePermission();

  static String statusPath(bool business) =>
      business
          ? 'Android/media/com.whatsapp.w4b/WhatsApp Business/Media/.Statuses'
          : 'Android/media/com.whatsapp/WhatsApp/Media/.Statuses';

  static String? _treeId(String rawUri) {
    final uri = Uri.tryParse(rawUri);
    if (uri?.authority != 'com.android.externalstorage.documents') return null;
    final parts = uri!.pathSegments;
    final tree = parts.indexOf('tree');
    return tree >= 0 && tree + 1 < parts.length ? parts[tree + 1] : null;
  }

  static bool _coversStatuses(String rawUri, bool business) {
    final id = _treeId(rawUri);
    if (id == null || !id.contains(':')) return false;
    final path = id.substring(id.indexOf(':') + 1);
    final expected = statusPath(business);
    // Accept the exact folder or a relevant ancestor, never a sibling,
    // a similarly named package, or an arbitrary broad storage root.
    return path == expected ||
        (path.startsWith('Android/media') && expected.startsWith('$path/'));
  }

  Future<bool> isWhatsAppStatusFolderPermissionAvailable({
    bool isBusinessMode = false,
  }) async {
    final permissions = await DocMan.perms.list(
      files: false,
      directories: true,
    );
    for (final permission in permissions) {
      if (!_coversStatuses(permission.uri, isBusinessMode)) {
        final folders = await _discover(
          permission.uri,
          business: isBusinessMode,
        );
        if (folders.containsKey(isBusinessMode ? 'business' : 'regular'))
          return true;
        continue;
      }
      try {
        final folder = await DocumentFile.fromUri(permission.uri);
        if (folder != null && folder.canRead && await folder.exists)
          return true;
      } catch (_) {
        // A revoked/missing grant should lead back to setup, not a crash.
      }
    }
    return false;
  }

  /// Resolves a status child under a persisted ancestor without walking every
  /// directory. A missing .Statuses folder is a valid connected-but-empty state.
  Future<DocumentFile?> resolveStatusDirectory({
    required bool isBusinessMode,
  }) async {
    final permissions = await DocMan.perms.list(
      files: false,
      directories: true,
    );
    for (final permission in permissions) {
      final folders = await _discover(permission.uri, business: isBusinessMode);
      final uri = folders[isBusinessMode ? 'business' : 'regular'];
      if (uri == null) continue;
      try {
        // DocMan.fromUri uses fromTreeUri, which resolves the grant root even
        // when a child document ID is supplied. Query the child directly.
        final metadata = await const MethodChannel(
          'story_saver/status_directory',
        ).invokeMapMethod<String, dynamic>('stat', {'uri': uri});
        if (metadata != null) return DocumentFile.fromMap(metadata);
      } catch (_) {
        // Try another valid grant, without releasing unrelated permissions.
      }
    }
    return null;
  }

  static final Map<String, Future<Map<String, String>>> _searches = {};

  Future<Map<String, String>> _discover(
    String uri, {
    bool business = false,
  }) async {
    final key = "$uri:$business";
    // Coalesce mode checks and status loads sharing a grant.
    final active = _searches[key];
    if (active != null) {
      try {
        return await active;
      } on PlatformException {
        return {};
      }
    }
    final search = const MethodChannel('story_saver/status_directory')
        .invokeMapMethod<String, String>('discover', {
          'uri': uri,
          'business': business,
        })
        .then((value) => value ?? <String, String>{});
    _searches[key] = search;
    try {
      return await search;
    } on PlatformException {
      return {};
    } finally {
      _searches.remove(key);
    }
  }

  Future<void> pickWhatsAppStatusFolder({bool isBusinessMode = false}) async {
    final target = Uri.encodeComponent('primary:Android/media');
    // DocMan's directory picker always takes a persistable URI grant.
    DocumentFile? selected;
    try {
      selected = await DocMan.pick.directory(
        initDir:
            'content://com.android.externalstorage.documents/document/$target',
      );
    } catch (_) {
      // Keep the fallback explicit too: omitting the initial location would
      // let DocumentsUI restore a previously visited unrelated folder.
      try {
        final android = Uri.encodeComponent('primary:Android');
        selected = await DocMan.pick.directory(
          initDir:
              'content://com.android.externalstorage.documents/document/$android',
        );
      } catch (_) {
        throw PlatformException(
          code: 'folder_picker_unavailable',
          message: 'Folder chooser unavailable. Please try again.',
        );
      }
    }
    if (selected == null) return; // Cancellation is not an error.
    if (!_coversStatuses(selected.uri, false) &&
        !_coversStatuses(selected.uri, true)) {
      final folders = await _discover(selected.uri, business: isBusinessMode);
      if (folders.isEmpty)
        throw PlatformException(
          code: 'wrong_status_folder',
          message: 'Wrong folder. Choose Android → media and try again.',
        );
    }
    if (!selected.canRead || !await selected.exists) {
      throw PlatformException(
        code: 'unreadable_status_folder',
        message: 'Access not allowed. Try again and tap Allow.',
      );
    }
    // The picker persists the grant. Loading and copying belong to StatusBloc,
    // so permission success returns immediately.
  }
}
