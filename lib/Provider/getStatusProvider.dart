import 'dart:io';
import 'package:docman/docman.dart';
import 'package:list_all_videos/thumbnail/generate_thumpnail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storysaver/Constants/constant.dart';
import 'package:storysaver/Utils/getStoragePermission.dart';
import 'package:storysaver/Utils/getThumbnails.dart';
// import 'package:saf/saf.dart';
import 'package:flutter/foundation.dart'; // For Isolates

class GetStatusProvider extends ChangeNotifier {
  List<FileSystemEntity> _getImages = [];
  List<FileSystemEntity> _getVideos = [];
  List<FileSystemEntity> _getExperimentalFiles = [];
  bool _isWhatsappAvailable = false;

  List<FileSystemEntity> get getImages => _getImages;
  List<FileSystemEntity> get getVideos => _getVideos;
  List<FileSystemEntity> get getExperimentalFiles => _getExperimentalFiles;
  bool get isWhatsappAvailable => _isWhatsappAvailable;

  final Map<String, Uint8List?> _thumbnailCache = {};
  final Map<String, String?> _thumbnailCacheV2 = {};
  bool _isLoading = false;

  Map<String, Uint8List?> get thumbnailCache => _thumbnailCache;
  Map<String, String?> get thumbnailCacheV2 => _thumbnailCacheV2;
  bool get isLoading => _isLoading;

  bool _isBusinessMode = false;
  bool get isBusinessMode => _isBusinessMode;

  Future<void> checkIsBusinessMode() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getBool(AppConstants().IS_BUSINESS_MODE);

    _isBusinessMode = val == null ? false : val;
    print("checkIsBusinessMode $val");
    notifyListeners();
  }

  void setIsBusinessMode(bool newValue) async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.setBool(AppConstants().IS_BUSINESS_MODE, newValue);

    _isBusinessMode = newValue;
    notifyListeners();
  }

  void clearAllStatus() async {
    _getVideos = [];
    _getImages = [];
    notifyListeners();
  }

  Future<List<File>> deleteExistingMediaCache(
      List<File> existingCachedFiles) async {
    // --- Start of new block ---
    List<File> filesToKeep = [];
    DateTime now = DateTime.now();
    print(
        '--- Processing existing cached files (deleting if older than 25 hours) ---');

    for (File file in existingCachedFiles) {
      try {
        FileStat stats = await file.stat();
        Duration age = now.difference(stats.modified);

        if (age.inHours > 25) {
          print('File ${file.path} is ${age.inHours} hours old. Deleting...');
          try {
            await file.delete();
            print('Successfully deleted old file: ${file.path}');
          } catch (deleteError) {
            print('Error deleting file ${file.path}: $deleteError');
          }
        } else {
          String formattedTime =
              "${stats.modified.hour.toString().padLeft(2, '0')}:"
              "${stats.modified.minute.toString().padLeft(2, '0')}:"
              "${stats.modified.second.toString().padLeft(2, '0')}";
          print(
              'Keeping file: ${file.path}, Age: ${age.inHours} hours, Last Modified Time: $formattedTime');
          filesToKeep.add(file);
        }
      } catch (statError) {
        print(
            'Error getting stats for file ${file.path}, cannot determine age: $statError. Skipping this file.');
        // Files for which stats cannot be read will not be added to filesToKeep.
      }
    }

    return filesToKeep;
  }

  void getAllStatusesWithSaf({VoidCallback? onComplete}) async {
    await checkIsBusinessMode();
    print(' getAllStatusesWithSaf checkIsBusinessMode $_isBusinessMode');

    // clearAllCache();

    // getWhatsAppStatusWithDocMan();

    // if(_isBusinessMode == false){
    //
    //   await getWhatsAppStatusWithDocMan();
    // } else {
    //
    //   getBusinessStatusWithDocMan();
    // }

    if (_isBusinessMode == true) {
      await _getAllStatusWithDocMan(isBusinessMode: true);
    } else {
      await _getAllStatusWithDocMan();
    }

    // At the end of the method
    onComplete?.call();
  }

  // Regular WhatsApp navigation (fallback)
  Future<DocumentFile?> _navigateToWhatsAppStatusFolder(
      {required DocumentFile androidMediaDir,
      bool isBusinessMode = false}) async {
    try {
      // const relativePath = "com.whatsapp/Whatsapp/Media/.Statuses";

      var relativePath = "com.whatsapp/Whatsapp/Media/.Statuses";

      if (isBusinessMode == true)
        relativePath = "com.whatsapp.w4b/WhatsApp Business/Media/.Statuses";

      // Extract base docId ("primary:Android/media")
      final baseDocId = Uri.decodeComponent(
        androidMediaDir
            .toString()
            .split('/tree/')
            .last
            .split('/document/')
            .first,
      );

      // Build the full docId with the relative path
      final fullDocId = "$baseDocId/$relativePath";

      // Encode and build final content:// URI
      final fullUri =
          "content://com.android.externalstorage.documents/tree/${Uri.encodeComponent(baseDocId)}/document/${Uri.encodeComponent(fullDocId)}";

      final doc = await DocumentFile.fromUri(fullUri);
      if (doc != null && await doc.exists) {
        return doc;
      }
    } catch (e) {
      print("Error navigating to regular WhatsApp status folder: $e");
      return null;
    }
    return null;
  }

  Future<void> _getAllStatusWithDocMan({bool isBusinessMode = false}) async {
    try {
      _isLoading = true;
      notifyListeners();

      print('Before Getting all DocMan Files -- getWhatsAppStatusWithDocMan ');

      List<PersistedPermission> accessiblePath =
          await DocMan.perms.list(files: false, directories: true);

      print(
          'After DocMan.perms.list  --> ${accessiblePath.map((p) => p.uri).toList()}');

      DocumentFile? statusDir;

      // Future<DocumentFile?> getStatusDir(PersistedPermission permission) async {
      final getStatusDir = (PersistedPermission permission) async {
        return await DocumentFile.fromUri(permission.uri)
            .catchError((error) async {
          print('Error listing documents: $error ${permission.uri}');

          await DocMan.dir.clearCache();

          if (error.toString().contains('Cannot initialize document file') ||
              error.toString().contains('uri is invalid') ||
              error.toString().contains('Permission Denial')) {
            print('Invalid URI - releasing permission');
            await DocMan.perms.releaseAll();
          }

          return null;
        });
      };

      // First check if we already have direct .Statuses access (for both regular WhatsApp and Business)
      for (final permission in accessiblePath) {
        final decodedUri = Uri.decodeFull(permission.uri);
        print('Checking URI: ${decodedUri}');

        if (decodedUri.contains(".Statuses")) {
          // Check for regular WhatsApp
          if (isBusinessMode == false &&
              (decodedUri.contains("com.whatsapp") &&
                  !decodedUri.contains("w4b"))) {
            print('Found direct WhatsApp .Statuses access: ${decodedUri}');
            statusDir = await getStatusDir(permission);
          }

          //Check for WhatsApp Business
          if (isBusinessMode == true &&
              (decodedUri.contains("com.whatsapp.w4b"))) {
            print(
                'Found direct Business WhatsApp .Statuses access: ${decodedUri}');
            statusDir = await getStatusDir(permission);
          }

          if (statusDir != null && await statusDir.exists) {
            print('Successfully found direct status directory access');
            break;
          } else {
            statusDir = null;
          }
        }
      }

      // If no direct .Statuses access, look for Android/media access and navigate
      if (statusDir == null) {
        print(
            'No direct .Statuses access found, checking for Android/media access');

        for (final permission in accessiblePath) {
          final decodedUri = Uri.decodeFull(permission.uri);

          if (decodedUri.contains("Android") &&
              decodedUri.contains("media") &&
              !decodedUri.contains("whatsapp")) {
            // print('Found Android/media permission: ${decodedUri}');

            DocumentFile? androidMediaDir =
                await DocumentFile.fromUri(permission.uri);

            if (androidMediaDir != null && await androidMediaDir.exists) {
              // Try WhatsApp Business first, then regular WhatsApp

              statusDir = await _navigateToWhatsAppStatusFolder(
                  androidMediaDir: androidMediaDir,
                  isBusinessMode: isBusinessMode);

              // statusDir = await _navigateToWhatsAppStatus(androidMediaDir);

              if (statusDir != null) {
                print('Successfully navigated to WhatsApp status folder');
                break;
              }
            }
          }
        }
      }

      // If no folder access found break the function
      if (statusDir == null) {
        print('statusDir is null --> ${statusDir}');
        _isWhatsappAvailable = false;
        _isLoading = false;
        notifyListeners();
        return;
      }

      print('After getting statusDir --> ${statusDir.uri}');

      List<DocumentFile> documents = await statusDir.listDocuments(
          mimeTypes: ['image/*', 'video/*']).catchError((error) async {
        print('Error listing documents: $error');

        if (error.toString().contains('Cannot initialize document file') ||
            error.toString().contains('uri is invalid') ||
            error.toString().contains('Permission Denial')) {
          print('Invalid URI - releasing permission');
          await DocMan.perms.release(statusDir!.uri);
        }

        return <DocumentFile>[]; // must return a fallback list
      });

      print(
          'After statusDir.listDocuments --> ${documents.map((d) => d.name).toList()}');

      List<File> existingCachedFiles = [];

      // Check DocMan cache directory
      final docManCacheDir = Directory(
          '/storage/emulated/0/Android/data/com.genrevibes.whatsappstorysaver/cache/docManMedia');
      if (await docManCacheDir.exists()) {
        List<FileSystemEntity> docManCacheContents =
            await docManCacheDir.list().toList();
        existingCachedFiles.addAll(
            docManCacheContents.where((entity) => entity is File).cast<File>());
      }

      existingCachedFiles = await deleteExistingMediaCache(
          existingCachedFiles); // Update the list to only contain files to keep

      print(
          'All Cached Files ${existingCachedFiles.length} - ${existingCachedFiles}');

      List<String> alreadyCachedNames =
          existingCachedFiles.map((file) => file.path.split('/').last).toList();

      print('Already cached files: $alreadyCachedNames');

      documents.sort((a, b) => b.lastModified.compareTo(a.lastModified));
      // List<DocumentFile> recentDocuments = documents.take(20).toList(); // Only cache 20 newest
      List<DocumentFile> recentDocuments = documents.toList();

      List<File> cachedFiles = [];
      // DocMan.dir.clearCache();

      for (DocumentFile doc in recentDocuments) {
        print('cached file: ${doc.name} ----- ');
        if (alreadyCachedNames.contains(doc.name)) {
          print('Skipping already cached file: ${doc.name}');

          // Find the existing cached file and add it to cachedFiles
          File? existingCachedFile = existingCachedFiles
              .firstWhere((file) => file.path.split('/').last == doc.name);

          cachedFiles.add(existingCachedFile);
          print('Added existing cached file: ${existingCachedFile.path}');

          continue;
        }

        try {
          File? cachedFile = await doc.cache();
          if (cachedFile != null) {
            print('During DocumentFile cachedFile -> ${cachedFile}');
            cachedFiles.add(cachedFile);
          }
        } catch (e) {
          print('Cache timeout: ${doc.name}');
        }
      }

      print('After caching files -- ${cachedFiles.length}');

      List<String> cachedFilesPath =
          cachedFiles.map((file) => file.path).toList();

      print('After getting cached file paths -- ${cachedFilesPath}');

      _getVideos = cachedFilesPath
          .where((path) => path.endsWith('.mp4'))
          .map((path) => File(path))
          .toList();

      _getImages = cachedFilesPath
          .where((path) => path.endsWith('.jpg') || path.endsWith('.jpeg'))
          .map((path) => File(path))
          .toList();

      print(
          'After Getting all DocMan Files -- getWhatsAppStatusWithDocMan --${_getVideos.length} --> ${_getVideos}');
      print('getWhatsAppStatusWithDocMan AllFiles --> ${_getImages}');

      _isWhatsappAvailable = true;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('error in getWhatsAppStatusWithDocMan --> ${e}');

      _isWhatsappAvailable = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  /////////////////////////////////
  Future<void> _getAllStatusWithDocMan_Deprecated(
      {bool isBusinessMode = false}) async {
    try {
      _isLoading = true;
      notifyListeners();

      print('Before Getting all DocMan Files -- getWhatsAppStatusWithDocMan ');

      List<PersistedPermission> accessiblePath =
          await DocMan.perms.list(files: false, directories: true);

      print(
          'After DocMan.perms.list  --> ${accessiblePath.map((p) => p.uri).toList()}');

      DocumentFile? statusDir;

      // Future<DocumentFile?> getStatusDir(PersistedPermission permission) async {
      final getStatusDir = (PersistedPermission permission) async {
        return await DocumentFile.fromUri(permission.uri)
            .catchError((error) async {
          print('Error listing documents: $error ${permission.uri}');

          await DocMan.dir.clearCache();

          if (error.toString().contains('Cannot initialize document file') ||
              error.toString().contains('uri is invalid') ||
              error.toString().contains('Permission Denial')) {
            print('Invalid URI - releasing permission');
            await DocMan.perms.releaseAll();
          }

          return null;
        });
      };

      // First check if we already have direct .Statuses access (for both regular WhatsApp and Business)
      for (final permission in accessiblePath) {
        final decodedUri = Uri.decodeFull(permission.uri);
        print('Checking URI: ${decodedUri}');

        if (decodedUri.contains(".Statuses")) {
          // Check for regular WhatsApp
          if (isBusinessMode == false &&
              (decodedUri.contains("com.whatsapp") &&
                  !decodedUri.contains("w4b"))) {
            print('Found direct WhatsApp .Statuses access: ${decodedUri}');
            statusDir = await getStatusDir(permission);
          }

          //Check for WhatsApp Business
          if (isBusinessMode == true &&
              (decodedUri.contains("com.whatsapp.w4b"))) {
            print(
                'Found direct Business WhatsApp .Statuses access: ${decodedUri}');
            statusDir = await getStatusDir(permission);
          }

          if (statusDir != null && await statusDir.exists) {
            print('Successfully found direct status directory access');
            break;
          } else {
            statusDir = null;
          }
        }
      }

      // If no direct .Statuses access, look for Android/media access and navigate
      if (statusDir == null) {
        print(
            'No direct .Statuses access found, checking for Android/media access');

        for (final permission in accessiblePath) {
          final decodedUri = Uri.decodeFull(permission.uri);

          if (decodedUri.contains("Android") &&
              decodedUri.contains("media") &&
              !decodedUri.contains("whatsapp")) {
            // print('Found Android/media permission: ${decodedUri}');

            DocumentFile? androidMediaDir =
                await DocumentFile.fromUri(permission.uri);

            if (androidMediaDir != null && await androidMediaDir.exists) {
              // Try WhatsApp Business first, then regular WhatsApp

              statusDir = await _navigateToWhatsAppStatusFolder(
                  androidMediaDir: androidMediaDir,
                  isBusinessMode: isBusinessMode);

              // statusDir = await _navigateToWhatsAppStatus(androidMediaDir);

              if (statusDir != null) {
                print('Successfully navigated to WhatsApp status folder');
                break;
              }
            }
          }
        }
      }

      // If no folder access found break the function
      if (statusDir == null) {
        print('statusDir is null --> ${statusDir}');
        _isWhatsappAvailable = false;
        _isLoading = false;
        notifyListeners();
        return;
      }

      print('After getting statusDir --> ${statusDir.uri}');

      List<DocumentFile> documents = await statusDir.listDocuments(
          mimeTypes: ['image/*', 'video/*']).catchError((error) async {
        print('Error listing documents: $error');

        if (error.toString().contains('Cannot initialize document file') ||
            error.toString().contains('uri is invalid') ||
            error.toString().contains('Permission Denial')) {
          print('Invalid URI - releasing permission');
          await DocMan.perms.release(statusDir!.uri);
        }

        return <DocumentFile>[]; // must return a fallback list
      });

      print(
          'After statusDir.listDocuments --> ${documents.map((d) => d.name).toList()}');

      List<File> existingCachedFiles = [];

      // Check DocMan cache directory
      final docManCacheDir = Directory(
          '/storage/emulated/0/Android/data/com.genrevibes.whatsappstorysaver/cache/docManMedia');
      if (await docManCacheDir.exists()) {
        List<FileSystemEntity> docManCacheContents =
            await docManCacheDir.list().toList();
        existingCachedFiles.addAll(
            docManCacheContents.where((entity) => entity is File).cast<File>());
      }

      existingCachedFiles = await deleteExistingMediaCache(
          existingCachedFiles); // Update the list to only contain files to keep

      print(
          'All Cached Files ${existingCachedFiles.length} - ${existingCachedFiles}');

      List<String> alreadyCachedNames =
          existingCachedFiles.map((file) => file.path.split('/').last).toList();

      print('Already cached files: $alreadyCachedNames');

      documents.sort((a, b) => b.lastModified.compareTo(a.lastModified));
      // List<DocumentFile> recentDocuments = documents.take(20).toList(); // Only cache 20 newest
      List<DocumentFile> recentDocuments = documents.toList();

      List<File> cachedFiles = [];
      for (DocumentFile doc in recentDocuments) {
        print('cached file: ${doc.name} ----- ');
        if (alreadyCachedNames.contains(doc.name)) {
          print('Skipping already cached file: ${doc.name}');

          // Find the existing cached file and add it to cachedFiles
          File? existingCachedFile = existingCachedFiles
              .firstWhere((file) => file.path.split('/').last == doc.name);

          cachedFiles.add(existingCachedFile);
          print('Added existing cached file: ${existingCachedFile.path}');

          continue;
        }

        try {
          File? cachedFile = await doc.cache();
          if (cachedFile != null) {
            print('During DocumentFile cachedFile -> ${cachedFile}');
            cachedFiles.add(cachedFile);
          }
        } catch (e) {
          print('Cache timeout: ${doc.name}');
        }
      }

      print('After caching files -- ${cachedFiles.length}');

      List<String> cachedFilesPath =
          cachedFiles.map((file) => file.path).toList();

      print('After getting cached file paths -- ${cachedFilesPath}');

      _getVideos = cachedFilesPath
          .where((path) => path.endsWith('.mp4'))
          .map((path) => File(path))
          .toList();

      _getImages = cachedFilesPath
          .where((path) => path.endsWith('.jpg'))
          .map((path) => File(path))
          .toList();

      print(
          'After Getting all DocMan Files -- getWhatsAppStatusWithDocMan --${_getVideos.length} --> ${_getVideos}');
      print('getWhatsAppStatusWithDocMan AllFiles --> ${_getImages}');

      _isWhatsappAvailable = true;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('error in getWhatsAppStatusWithDocMan --> ${e}');

      _isWhatsappAvailable = false;
      _isLoading = false;
      notifyListeners();
    }
  }

//////
  Future<void> getBusinessStatusWithDocMan() async {
    try {
      _isLoading = true;
      notifyListeners();

      // await DocMan.dir.clearCache();

      print('Before Getting all DocMan Files -- getWhatsAppStatusWithDocMan ');

      List<PersistedPermission> accessiblePath =
          await DocMan.perms.list(files: false, directories: true);

      print(
          'After DocMan.perms.list  --> ${accessiblePath.map((p) => p.uri).toList()}');

      DocumentFile? statusDir;

      // First check if we already have direct .Statuses access
      for (final permission in accessiblePath) {
        final decodedUri = Uri.decodeFull(permission.uri);
        print('${decodedUri}');
        if (decodedUri.contains("whatsapp.w4b") &&
            decodedUri.contains(".Statuses")) {
          print('decodedUri ${decodedUri}');
          statusDir = await DocumentFile.fromUri(permission.uri)
              .catchError((error) async {
            print('Error listing documents: $error ${permission.uri}');

            await DocMan.dir.clearCache();

            if (error.toString().contains('Cannot initialize document file') ||
                error.toString().contains('uri is invalid') ||
                error.toString().contains('Permission Denial')) {
              print('Invalid URI - releasing permission');
              await DocMan.perms.releaseAll();
              // await DocMan.perms.release(permission.uri);
            }

            return null;
          });

          if (statusDir != null && await statusDir.exists) {
            print('Found direct status directory access');
            break;
          } else {
            statusDir = null;
          }
        }
      }

      // If no direct .Statuses access, look for Android/media access and navigate
      if (statusDir == null) {
        print(
            'No direct .Statuses access found, checking for Android/media access');

        for (final permission in accessiblePath) {
          final decodedUri = Uri.decodeFull(permission.uri);

          if (decodedUri.contains("Android") &&
              decodedUri.contains("media") &&
              !decodedUri.contains("whatsapp")) {
            print('Found Android/media permission: ${decodedUri}');

            DocumentFile? androidMediaDir =
                await DocumentFile.fromUri(permission.uri);

            if (androidMediaDir != null && await androidMediaDir.exists) {
              statusDir =
                  await _navigateToWhatsAppBusinessStatus(androidMediaDir);
              if (statusDir != null) {
                print(
                    'Successfully navigated to WhatsApp Business status folder');
                break;
              }
            }
          }
        }
      }

      if (statusDir == null) {
        print('statusDir is null --> ${statusDir}');
        _isWhatsappAvailable = false;
        _isLoading = false;
        notifyListeners();
        return;
      }

      print('After getting statusDir --> ${statusDir.uri}');

      List<DocumentFile> documents = await statusDir.listDocuments(
          mimeTypes: ['image/*', 'video/*']).catchError((error) async {
        print('Error listing documents: $error');

        if (error.toString().contains('Cannot initialize document file') ||
            error.toString().contains('uri is invalid') ||
            error.toString().contains('Permission Denial')) {
          print('Invalid URI - releasing permission');
          await DocMan.perms.releaseAll();
          // await DocMan.perms.release(statusDir!.uri);
        }

        return <DocumentFile>[]; // must return a fallback list
      });

      print(
          'After statusDir.listDocuments --> ${documents.map((d) => d.name).toList()}');

      List<File> cachedFiles = [];
      for (DocumentFile doc in documents) {
        File? cachedFile = await doc.cache();
        if (cachedFile != null) {
          cachedFiles.add(cachedFile);
        }
      }

      print('After caching files -- ${cachedFiles.length}');

      List<String> cachedFilesPath =
          cachedFiles.map((file) => file.path).toList();

      print('After getting cached file paths -- ${cachedFilesPath}');

      print("accessiblePath  ${accessiblePath.map((p) => p.uri).toList()}");
      print('object ${cachedFilesPath}');

      _getVideos = cachedFilesPath
          .where((path) => path.endsWith('.mp4'))
          .map((path) => File(path))
          .toList();

      _getImages = cachedFilesPath
          .where((path) => path.endsWith('.jpg'))
          .map((path) => File(path))
          .toList();

      print(
          'After Getting all DocMan Files -- getWhatsAppStatusWithDocMan  --> ${_getVideos}');
      print('getWhatsAppStatusWithDocMan AllFiles --> ${_getImages}');

      _isWhatsappAvailable = true;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('error in getWhatsAppStatusWithDocMan --> ${e}');

      _isWhatsappAvailable = false;
      _isLoading = false;
      notifyListeners();
    }
  }

// Helper method to navigate from Android/media to WhatsApp Business status folder
  Future<DocumentFile?> _navigateToWhatsAppBusinessStatus(
      DocumentFile androidMediaDir) async {
    try {
      // Navigate: Android/media -> com.whatsapp.w4b -> WhatsApp Business -> Media -> .Statuses

      List<DocumentFile> mediaContents = await androidMediaDir.listDocuments();
      DocumentFile? whatsappW4bDir =
          mediaContents.cast<DocumentFile?>().firstWhere(
                (dir) => dir != null && dir.name == "com.whatsapp.w4b",
                orElse: () => null,
              );

      if (whatsappW4bDir == null) {
        print("com.whatsapp.w4b folder not found in Android/media");
        return null;
      }

      List<DocumentFile> w4bContents = await whatsappW4bDir.listDocuments();
      print('WhatsApp Business Search ${w4bContents}');
      DocumentFile? whatsappBusinessDir =
          w4bContents.cast<DocumentFile?>().firstWhere(
                (dir) => dir != null && dir.name == "Whatsapp Business",
                orElse: () => null,
              );

      if (whatsappBusinessDir == null) {
        print("WhatsApp Business folder not found");
        return null;
      }

      List<DocumentFile> businessContents =
          await whatsappBusinessDir.listDocuments();
      DocumentFile? mediaDir =
          businessContents.cast<DocumentFile?>().firstWhere(
                (dir) => dir != null && dir.name == "Media",
                orElse: () => null,
              );

      if (mediaDir == null) {
        print("Media folder not found");
        return null;
      }

      List<DocumentFile> mediaContents2 = await mediaDir.listDocuments();
      DocumentFile? statusDir = mediaContents2.cast<DocumentFile?>().firstWhere(
            (dir) => dir != null && dir.name == ".Statuses",
            orElse: () => null,
          );

      return statusDir;
    } catch (e) {
      print("Error navigating to WhatsApp Business status folder: $e");
      return null;
    }
  }

  // Regular WhatsApp navigation (fallback)
  Future<DocumentFile?> _navigateToWhatsAppStatus(
      DocumentFile androidMediaDir) async {
    try {
      const relativePath = "com.whatsapp/Whatsapp/Media/.Statuses";

      // Extract base docId ("primary:Android/media")
      final baseDocId = Uri.decodeComponent(
        androidMediaDir
            .toString()
            .split('/tree/')
            .last
            .split('/document/')
            .first,
      );

      // Build the full docId with the relative path
      final fullDocId = "$baseDocId/$relativePath";

      // Encode and build final content:// URI
      final fullUri =
          "content://com.android.externalstorage.documents/tree/${Uri.encodeComponent(baseDocId)}/document/${Uri.encodeComponent(fullDocId)}";

      final doc = await DocumentFile.fromUri(fullUri);
      if (doc != null && await doc.exists) {
        return doc;
      }
    } catch (e) {
      print("Error navigating to regular WhatsApp status folder: $e");
      return null;
    }
    return null;
  }

  // Complete updated method that handles both regular WhatsApp and WhatsApp Business
  Future<void> getWhatsAppStatusWithDocMan() async {
    try {
      _isLoading = true;
      notifyListeners();

      print('Before Getting all DocMan Files -- getWhatsAppStatusWithDocMan ');

      List<PersistedPermission> accessiblePath =
          await DocMan.perms.list(files: false, directories: true);

      print(
          'After DocMan.perms.list  --> ${accessiblePath.map((p) => p.uri).toList()}');

      DocumentFile? statusDir;

      // First check if we already have direct .Statuses access (for both regular WhatsApp and Business)
      for (final permission in accessiblePath) {
        final decodedUri = Uri.decodeFull(permission.uri);
        print('Checking URI: ${decodedUri}');

        // Check for both regular WhatsApp and WhatsApp Business
        if ((decodedUri.contains("com.whatsapp.w4b") ||
                decodedUri.contains("com.whatsapp")) &&
            decodedUri.contains(".Statuses")) {
          print('Found direct .Statuses access: ${decodedUri}');
          statusDir = await DocumentFile.fromUri(permission.uri)
              .catchError((error) async {
            print('Error listing documents: $error ${permission.uri}');

            await DocMan.dir.clearCache();

            if (error.toString().contains('Cannot initialize document file') ||
                error.toString().contains('uri is invalid') ||
                error.toString().contains('Permission Denial')) {
              print('Invalid URI - releasing permission');
              await DocMan.perms.releaseAll();
            }

            return null;
          });

          if (statusDir != null && await statusDir.exists) {
            print('Successfully found direct status directory access');
            break;
          } else {
            statusDir = null;
          }
        }
      }

      // If no direct .Statuses access, look for Android/media access and navigate
      if (statusDir == null) {
        print(
            'No direct .Statuses access found, checking for Android/media access');

        for (final permission in accessiblePath) {
          final decodedUri = Uri.decodeFull(permission.uri);

          if (decodedUri.contains("Android") &&
              decodedUri.contains("media") &&
              !decodedUri.contains("whatsapp")) {
            print('Found Android/media permission: ${decodedUri}');

            DocumentFile? androidMediaDir =
                await DocumentFile.fromUri(permission.uri);

            if (androidMediaDir != null && await androidMediaDir.exists) {
              // Try WhatsApp Business first, then regular WhatsApp

              statusDir = await _navigateToWhatsAppStatus(androidMediaDir);

              if (statusDir != null) {
                print('Successfully navigated to WhatsApp status folder');
                break;
              }
            }
          }
        }
      }

      if (statusDir == null) {
        print('statusDir is null --> ${statusDir}');
        _isWhatsappAvailable = false;
        _isLoading = false;
        notifyListeners();
        return;
      }

      print('After getting statusDir --> ${statusDir.uri}');

      List<DocumentFile> documents = await statusDir.listDocuments(
          mimeTypes: ['image/*', 'video/*']).catchError((error) async {
        print('Error listing documents: $error');

        if (error.toString().contains('Cannot initialize document file') ||
            error.toString().contains('uri is invalid') ||
            error.toString().contains('Permission Denial')) {
          print('Invalid URI - releasing permission');
          await DocMan.perms.release(statusDir!.uri);
        }

        return <DocumentFile>[]; // must return a fallback list
      });

      print(
          'After statusDir.listDocuments --> ${documents.map((d) => d.name).toList()}');

      List<File> existingCachedFiles = [];

      // Check app cache directory
      // final appCacheDir = await DocMan.dir.cache();
      // if (appCacheDir != null && await appCacheDir.exists()) {
      //   List<FileSystemEntity> appCacheContents = await appCacheDir.list().toList();
      //   existingCachedFiles.addAll(
      //       appCacheContents
      //           .where((entity) => entity is File)
      //           .cast<File>()
      //   );
      // }

      // Check DocMan cache directory
      final docManCacheDir = Directory(
          '/storage/emulated/0/Android/data/com.genrevibes.whatsappstorysaver/cache/docManMedia');
      if (await docManCacheDir.exists()) {
        List<FileSystemEntity> docManCacheContents =
            await docManCacheDir.list().toList();
        existingCachedFiles.addAll(
            docManCacheContents.where((entity) => entity is File).cast<File>());
      }

      existingCachedFiles = await deleteExistingMediaCache(
          existingCachedFiles); // Update the list to only contain files to keep

      print('All Cached Files ${existingCachedFiles}');

      List<String> alreadyCachedNames =
          existingCachedFiles.map((file) => file.path.split('/').last).toList();

      print('Already cached files: $alreadyCachedNames');

      documents.sort((a, b) => b.lastModified.compareTo(a.lastModified));
      List<DocumentFile> recentDocuments =
          documents.take(20).toList(); // Only cache 20 newest

      List<File> cachedFiles = [];
      for (DocumentFile doc in recentDocuments) {
        print('cached file: ${doc.name} ----- ');
        if (alreadyCachedNames.contains(doc.name)) {
          print('Skipping already cached file: ${doc.name}');

          // Find the existing cached file and add it to cachedFiles
          File? existingCachedFile = existingCachedFiles
              .firstWhere((file) => file.path.split('/').last == doc.name);

          cachedFiles.add(existingCachedFile);
          print('Added existing cached file: ${existingCachedFile.path}');

          continue;
        }

        try {
          File? cachedFile = await doc.cache();
          if (cachedFile != null) {
            print('During DocumentFile cachedFile -> ${cachedFile}');
            cachedFiles.add(cachedFile);
          }
        } catch (e) {
          print('Cache timeout: ${doc.name}');
        }
      }

      print('After caching files -- ${cachedFiles.length}');

      List<String> cachedFilesPath =
          cachedFiles.map((file) => file.path).toList();

      print('After getting cached file paths -- ${cachedFilesPath}');

      _getVideos = cachedFilesPath
          .where((path) => path.endsWith('.mp4'))
          .map((path) => File(path))
          .toList();

      _getImages = cachedFilesPath
          .where((path) => path.endsWith('.jpg'))
          .map((path) => File(path))
          .toList();

      print(
          'After Getting all DocMan Files -- getWhatsAppStatusWithDocMan  --> ${_getVideos}');
      print('getWhatsAppStatusWithDocMan AllFiles --> ${_getImages}');

      _isWhatsappAvailable = true;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('error in getWhatsAppStatusWithDocMan --> ${e}');

      _isWhatsappAvailable = false;
      _isLoading = false;
      notifyListeners();
    }
  }

//////
//   void getWhatsAppStatusWithDocMan() async {
//
//     try {
//       _isLoading = true;
//       notifyListeners();
//
//       // await DocMan.dir.clearCache();
//
//       print('Before Getting all DocMan Files -- getWhatsAppStatusWithDocMan ');
//
//       List<PersistedPermission> accessiblePath = await DocMan.perms.list(files: false, directories: true);
//
//       print('After DocMan.perms.list  --> ${accessiblePath.map((p) => p.uri).toList()}');
//
//       DocumentFile? statusDir;
//       for (final permission in accessiblePath) {
//         final decodedUri = Uri.decodeFull(permission.uri);
//         print('${decodedUri}');
//         if (decodedUri.contains("com.whatsapp") && decodedUri.contains(".Statuses")) {
//           print('decodedUri ${decodedUri}');
//           statusDir = await DocumentFile.fromUri(permission.uri)
//               .catchError((error) async {
//             print('Error listing documents: $error ${permission.uri}');
//
//             await DocMan.dir.clearCache();
//
//             if (error.toString().contains('Cannot initialize document file') ||
//                 error.toString().contains('uri is invalid') ||
//                 error.toString().contains('Permission Denial')) {
//               print('Invalid URI - releasing permission');
//               await DocMan.perms.releaseAll();
//             }
//
//             return null;
//           });
//           print('statusDir ');
//           break;
//         }
//       }
//
//       if(statusDir == null){
//         _isWhatsappAvailable = false;
//         _isLoading = false;
//         notifyListeners();
//         return;
//       }
//
//       print('After DocumentFile.fromUri --> ${statusDir!.uri}');
//
//       List<DocumentFile> documents = await statusDir!
//           .listDocuments(mimeTypes: ['image/*', 'video/*'])
//           .catchError((error) async {
//         print('Error listing documents: $error');
//
//         if (error.toString().contains('Cannot initialize document file') ||
//             error.toString().contains('uri is invalid') ||
//             error.toString().contains('Permission Denial')) {
//           print('Invalid URI - releasing permission');
//           await DocMan.perms.release(statusDir!.uri);
//         }
//
//         return <DocumentFile>[]; // must return a fallback list
//       });
//
//       print('After statusDir.listDocuments --> ${documents.map((d) => d.name).toList()}');
//
//       List<File> cachedFiles = [];
//       for (DocumentFile doc in documents) {
//         File? cachedFile = await doc.cache();
//         if (cachedFile != null) {
//           cachedFiles.add(cachedFile);
//         }
//       }
//
//       print('After caching files -- ${cachedFiles.length}');
//
//       List<String> cachedFilesPath = cachedFiles.map((file) => file.path).toList();
//
//       print('After getting cached file paths -- ${cachedFilesPath}');
//
//       print("accessiblePath  ${accessiblePath.map((p) => p.uri).toList()}");
//       print('object ${cachedFilesPath}');
//
//       _getVideos = cachedFilesPath
//           .where((path) => path.endsWith('.mp4'))
//           .map((path) => File(path))
//           .toList();
//
//       _getImages = cachedFilesPath
//           .where((path) => path.endsWith('.jpg'))
//           .map((path) => File(path))
//           .toList();
//
//       print('After Getting all DocMan Files -- getWhatsAppStatusWithDocMan  --> ${_getVideos}');
//       print('getWhatsAppStatusWithDocMan AllFiles --> ${_getImages}');
//
//       _isWhatsappAvailable = true;
//       _isLoading = false;
//       notifyListeners();
//     }catch(e){
//       print('error in getWhatsAppStatusWithDocMan --> ${e}');
//
//       _isWhatsappAvailable = false;
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

  //////
  // void deprecated_getBusinessStatusWithSaf() async {
  //   _isLoading = true;
  //   notifyListeners();
  //
  //   Saf saf  = Saf("Android/media/com.whatsapp.w4b/WhatsApp Business/Media/.Statuses");
  //   final isSync =  await saf.sync();
  //
  //   final accessiblePath = await Saf.getPersistedPermissionDirectories();
  //
  //   List<String>? paths = await saf.getFilesPath(fileType: FileTypes.media);
  //
  //   final isCached = await saf.cache();
  //
  //   List<String>? cachedFilesPath = await saf.getCachedFilesPath();
  //
  //   print("accessiblePath  ${accessiblePath}");
  //   print('object ${cachedFilesPath}');
  //
  //   _getVideos = cachedFilesPath!
  //       .where((path) => path.endsWith('.mp4'))
  //       .map((path) => File(path))
  //       .toList();
  //
  //   _getImages = cachedFilesPath!
  //       .where((path) => path.endsWith('.jpg'))
  //       .map((path) => File(path))
  //       .toList();
  //
  //
  //   _isWhatsappAvailable = true;
  //   _isLoading = false;
  //   notifyListeners();
  // }
  //
  // //////
  // void deprecated_getWhatsAppStatusWithSaf() async {
  //   try {
  //     _isLoading = true;
  //     notifyListeners();
  //
  //     print('Before Getting all Saf Files -- getWhatsAppStatusWithSaf ');
  //     Saf saf = Saf("Android/media/com.whatsapp/WhatsApp/Media/.Statuses");
  //     final isSync = await saf.sync();
  //     saf.clearCache();
  //
  //     if(isSync == null){
  //       re
  //     }
  //     print('After Saf isSync  --> ${isSync}');
  //
  //     final accessiblePath = await Saf.getPersistedPermissionDirectories();
  //     final granted = await saf.getDirectoryPermission(isDynamic: false);
  //
  //     print(
  //         'After accessiblePath = await Saf.getPersistedPermissionDirectories() --> ${accessiblePath} - granted -  ${granted}');
  //
  //     List<String>? paths = await saf.getFilesPath(fileType: FileTypes.media);
  //
  //     print(
  //         'After List<String>? paths = await saf.getFilesPath(fileType: FileTypes.media) --> ${paths}');
  //
  //     final isCached = await saf.cache();
  //
  //     print('After await saf.cache() -- ${isCached}');
  //
  //     List<String>? cachedFilesPath = await saf.getCachedFilesPath();
  //
  //     print('After await saf.cache() -- ${cachedFilesPath}');
  //
  //     print("accessiblePath  ${accessiblePath}");
  //     print('object ${cachedFilesPath}');
  //
  //
  //     // cachedFilesPath?.sort((a, b) {
  //     //   return File(b)
  //     //       .lastModifiedSync()
  //     //       .compareTo(File(a).lastModifiedSync());
  //     // });
  //
  //     _getVideos = cachedFilesPath!
  //         .where((path) => path.endsWith('.mp4'))
  //         .map((path) => File(path))
  //         .toList();
  //
  //     _getImages = cachedFilesPath!
  //         .where((path) => path.endsWith('.jpg'))
  //         .map((path) => File(path))
  //         .toList();
  //
  //     print('After Getting all Saf Files -- getWhatsAppStatusWithSaf  --> ${_getVideos}');
  //     print('getWhatsAppStatusWithSaf AllFiles --> ${_getImages}');
  //
  //
  //     _isWhatsappAvailable = true;
  //     _isLoading = false;
  //     notifyListeners();
  //   }catch(e){
  //     print('error in getWhatsAppStatusWithSaf --> ${e}');
  //
  //     _isWhatsappAvailable = false;
  //     _isLoading = false;
  //     notifyListeners();
  //   }
  // }

  // Fetch WhatsApp Status files based on extension

  void getStatus(String ext) async {
    if (await AppStoragePermission().getStoragePermission() == true) {
      final directory = Directory(AppConstants.WHATSAPP_PATH);
      if (directory.existsSync()) {
        final items = directory.listSync();

        // Sort by last modified time (newest first)
        // items.sort((a, b) {
        //   return File(b.path).lastModifiedSync().compareTo(File(a.path).lastModifiedSync());
        // });

        if (ext == ".mp4") {
          _getVideos =
              items.where((element) => element.path.endsWith(ext)).toList();
          notifyListeners();
        } else {
          _getImages =
              items.where((element) => element.path.endsWith('.jpg')).toList();
          notifyListeners();
        }
      }
      _isWhatsappAvailable = true;
      notifyListeners();
    }
  }

  void getAllStatus() async {
    _isLoading = true;
    notifyListeners();

    if (await AppStoragePermission().getStoragePermission() == true) {
      List<FileSystemEntity> allStatus = [];

      for (final folder in AppConstants.WHATSAPP_PATH_LIST) {
        print('------ Folder -> ${folder}');
        final directory = Directory(folder);
        if (directory.existsSync()) {
          final items = directory.listSync();

          print('------ items -> ${items}');
          // Sort by last modified time (newest first)
          allStatus.addAll(items);

          // final fakeFileMP = File('/path/to/fake_file.mp4');
          // _getVideos.insert(0, fakeFileMP);
          //
          // final fakeFileIMG = File('/path/to/fake_file.jpg');
          // _getImages.insert(0, fakeFileIMG);
        }

        allStatus.sort((a, b) {
          return File(b.path)
              .lastModifiedSync()
              .compareTo(File(a.path).lastModifiedSync());
        });
      }

      _getVideos =
          allStatus.where((element) => element.path.endsWith('.mp4')).toList();
      _getImages =
          allStatus.where((element) => element.path.endsWith('.jpg')).toList();

      _isWhatsappAvailable = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  void getAllStatusOldAndRetired() async {
    _isLoading = true;
    notifyListeners();

    if (await AppStoragePermission().getStoragePermission() == true) {
      final directory = Directory(AppConstants.WHATSAPP_PATH);
      if (directory.existsSync()) {
        final items = directory.listSync();

        // Sort by last modified time (newest first)
        items.sort((a, b) {
          return File(b.path)
              .lastModifiedSync()
              .compareTo(File(a.path).lastModifiedSync());
        });

        _getVideos =
            items.where((element) => element.path.endsWith('.mp4')).toList();
        _getImages =
            items.where((element) => element.path.endsWith('.jpg')).toList();

        final fakeFileMP = File('/path/to/fake_file.mp4');
        _getVideos.insert(0, fakeFileMP);

        final fakeFileIMG = File('/path/to/fake_file.jpg');
        _getImages.insert(0, fakeFileIMG);
      }

      _isWhatsappAvailable = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  void removeImageAtIndex(int index) {
    if (index >= 0 && index < _getImages.length && _getImages.length > 0) {
      _getImages.removeAt(index);
      notifyListeners();
    }
  }

  void removeVideoAtIndex(int index) {
    if (index >= 0 && index < _getVideos.length && _getVideos.length > 0) {
      _getVideos.removeAt(index);
      notifyListeners();
    }
  }

  // Fetch files from another directory for experimental use
  void getExperimentalStatus(String ext) async {
    if (await AppStoragePermission().getStoragePermission() == true) {
      final directory = Directory(AppConstants.TEST_STORYSAVER_PATH);
      if (directory.existsSync()) {
        final items = await directory.list().toList();
        if (ext == ".mp4") {
          _getExperimentalFiles =
              items.where((element) => element.path.endsWith(ext)).toList();
          notifyListeners();
        }
      }
      _isWhatsappAvailable = true;
      notifyListeners();
    }
  }

  Future<void> generateThumbnailsWithExternalIsolates(String files) async {
    if (_thumbnailCache.containsKey(files)) return;

    final result = await generateThumbnailInIsolateWithFlutterIsolates(files);

    // print("generateThumbnailInIsolate $files $result");

    _thumbnailCache[files] = result;
  }

  Future<void> generateThumbnailFromListAllVideos(String videoPath) async {
    // If already cached, no need to regenerate
    if (_thumbnailCache.containsKey(videoPath)) return;

    _isLoading = true;
    // notifyListeners();

    try {
      // Replace this with your thumbnail generation logic
      final thumbnail = await Thumbnail().generate(videoPath);

      print("----- show thumbnail $thumbnail $videoPath");

      _thumbnailCacheV2[videoPath] = thumbnail;
      notifyListeners();

      // print(_thumbnailCache[videoPath]);
    } catch (e) {
      _thumbnailCache[videoPath] = null; // Cache null for failed attempts
    } finally {
      _isLoading = false;
    }
  }

  Future<String> generateThumbnailFromListAllVideosForFutureBuilder(
      String videoPath) async {
    // If already cached, no need to regenerate
    if (_thumbnailCacheV2.containsKey(videoPath)) {
      return Future.value(
          _thumbnailCacheV2[videoPath]!); // Ensure it's non-null
    }

    _isLoading = true;
    // notifyListeners();

    try {
      // Replace this with your thumbnail generation logic
      final thumbnail = await Thumbnail().generate(videoPath);

      print("----- show thumbnail $thumbnail $videoPath");

      _thumbnailCacheV2[videoPath] = thumbnail;
      notifyListeners();

      return thumbnail;

      // print(_thumbnailCache[videoPath]);
    } catch (e) {
      _thumbnailCacheV2[videoPath] = null; // Cache null for failed attempts
    } finally {
      _isLoading = false;

      return _thumbnailCacheV2[videoPath]!;
    }
  }
}
