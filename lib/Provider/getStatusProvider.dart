import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:storysaver/Constants/constant.dart';
import 'package:video_compress/video_compress.dart';
import 'package:flutter/foundation.dart';  // For Isolates

class GetStatusProvider extends ChangeNotifier {
  List<FileSystemEntity> _getImages = [];
  List<FileSystemEntity> _getVideos = [];
  List<FileSystemEntity> _getExperimentalFiles = [];
  bool _isWhatsappAvailable = false;

  List<FileSystemEntity> get getImages => _getImages;
  List<FileSystemEntity> get getVideos => _getVideos;
  List<FileSystemEntity> get getExperimentalFiles => _getExperimentalFiles;
  bool get isWhatsappAvailable => _isWhatsappAvailable;

  // Fetch WhatsApp Status files based on extension
  void getStatus(String ext) async {
    if (await getStoragePermission() == true) {
      final directory = Directory(AppConstants.WHATSAPP_PATH);
      if (directory.existsSync()) {
        final items = directory.listSync();
        if (ext == ".mp4") {
          _getVideos = items.where((element) => element.path.endsWith(ext)).toList();
          notifyListeners();
        } else {
          _getImages = items.where((element) => element.path.endsWith('.jpg')).toList();
          notifyListeners();
        }
      }
      _isWhatsappAvailable = true;
      notifyListeners();
    }
  }

  // Fetch files from another directory for experimental use
  void getExperimentalStatus(String ext) async {
    if (await getStoragePermission() == true) {
      final directory = Directory(AppConstants.TEST_STORYSAVER_PATH);
      if (directory.existsSync()) {
        final items = await directory.list().toList();
        if (ext == ".mp4") {
          _getExperimentalFiles = items.where((element) => element.path.endsWith(ext)).toList();
          notifyListeners();
        }
      }
      _isWhatsappAvailable = true;
      notifyListeners();
    }
  }

  // Use Isolates for thumbnail generation (asynchronously)
  Future<void> generateThumbnailsWithIsolates(List<FileSystemEntity> files) async {
    List<Future<Uint8List>> futures = [];
    for (var file in files) {
      futures.add(_generateThumbnailInIsolate(file));
    }

    final thumbnails = await Future.wait(futures);

    // Update the experimental files list with the generated thumbnails
    // Assuming you're storing Uint8List in the list for thumbnails
    _getExperimentalFiles = thumbnails.map((thumb) => _createFileFromThumbnail(thumb)).toList();
    notifyListeners();
  }

  // Create a temporary file to hold the generated thumbnail
  FileSystemEntity _createFileFromThumbnail(Uint8List thumb) {
    final tempFile = File('${(Directory.systemTemp.path)}/temp_thumbnail_${DateTime.now().millisecondsSinceEpoch}.jpg');
    tempFile.writeAsBytesSync(thumb);
    return tempFile;
  }

  // Generate thumbnail for a single file using isolate
  Future<Uint8List> _generateThumbnailInIsolate(FileSystemEntity file) async {
    return await compute(_generateThumbnail, file.path);
  }

  // This static function generates the thumbnail in the isolate
  static Future<Uint8List> _generateThumbnail(String path) async {
    try {
      final thumb = await VideoCompress.getByteThumbnail(
        path,
        quality: 100,
        position: -1,
      );
      if (thumb == null) throw Exception('Failed to generate thumbnail');
      return thumb;
    } catch (e) {
      throw Exception('Error generating thumbnail for $path: $e');
    }
  }

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
}
