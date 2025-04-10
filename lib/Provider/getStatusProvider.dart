import 'dart:io';
import 'package:list_all_videos/thumbnail/generate_thumpnail.dart';
import 'package:storysaver/Constants/constant.dart';
import 'package:storysaver/Utils/getStoragePermission.dart';
import 'package:storysaver/Utils/getThumbnails.dart';
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

  // Fetch WhatsApp Status files based on extension
  void getStatus(String ext) async {
    if (await getStoragePermission() == true) {
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

    if (await getStoragePermission() == true) {

      List<FileSystemEntity> allStatus = [];

      for (final folder in AppConstants.WHATSAPP_PATH_LIST) {
        print('------ Folder -> ${folder}');
        final directory = Directory(folder);
        if (directory.existsSync()) {
          final items = directory.listSync();

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

    if (await getStoragePermission() == true) {
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
    if (await getStoragePermission() == true) {
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
