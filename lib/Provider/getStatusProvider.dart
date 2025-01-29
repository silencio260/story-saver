import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:list_all_videos/thumbnail/generate_thumpnail.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:storysaver/Constants/constant.dart';
import 'package:video_compress/video_compress.dart';

import 'package:flutter_isolate/flutter_isolate.dart';
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


  final Map<String, Uint8List?> _thumbnailCache = {};
  final Map<String, String?> _thumbnailCacheV2 = {};
  bool _isLoading = false;

  Map<String, Uint8List?> get thumbnailCache => _thumbnailCache;
  Map<String, String?> get thumbnailCacheV2 => _thumbnailCacheV2;
  bool get isLoading => _isLoading;



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

}


////////////////----------------------------////////////////////////

Future<Uint8List?> generateThumbnailInIsolateWithFlutterIsolates(String videoPath) async {
  final receivePort = ReceivePort();

  // Spawn the isolate
  await FlutterIsolate.spawn(_generateThumbnailTask, [videoPath, receivePort.sendPort]);

  // Wait for the result from the isolate
  final result = await receivePort.first;

  print('generating in isolate $result');

  // Close the receive port
  receivePort.close();

  return result as Uint8List?;
}

/// The isolate function for generating a thumbnail
Future<void> _generateThumbnailTask(List<dynamic> args) async {
  final String videoPath = args[0]; // The video file path
  final SendPort sendPort = args[1]; // SendPort to communicate back

  print('thumbnails value $videoPath $sendPort');

  // VideoCompress.getByteThumbnail(
  //   videoPath,
  //   quality: 100, // Adjust quality if needed
  //   position: -1, // Default position
  // ).then((onValue){
  //   print('in .then $onValue');
  // });

  try {
    // Generate the thumbnail using the async library function
    final thumbnail = await VideoCompress.getByteThumbnail(
      videoPath,
      quality: 100, // Adjust quality if needed
      position: -1, // Default position
    );
    //     .then((onValue){
    //   print('in .then $onValue');
    // });

    print("thumb in isolate generated ");
    // Send the result back to the main isolate
    sendPort.send(thumbnail);
  } catch (e) {
    print("Error generating thumbnail 2: $e");
    sendPort.send(null);
  }
}






