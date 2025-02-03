import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:list_all_videos/thumbnail/generate_thumpnail.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:storysaver/Constants/constant.dart';
import 'package:storysaver/Utils/getThumbnails.dart';
import 'package:video_compress/video_compress.dart';

import 'package:flutter_isolate/flutter_isolate.dart';
import 'package:flutter/foundation.dart';  // For Isolates

class GetSavedMediaProvider extends ChangeNotifier {

  bool _isFolderAvailable = false;
  bool _isLoading = false;


  List<AssetEntity> _getMediaFile = [];
  List<AssetEntity> get getMediaFile => _getMediaFile;
  bool get isLoading => _isLoading;



  // Fetch WhatsApp Status files based on extension
  // void loadFiles(String ext) async {
  //   if (await getStoragePermission() == true) {
  //     final directory = Directory(AppConstants.WHATSAPP_PATH);
  //     if (directory.existsSync()) {
  //       final items = directory.listSync();
  //
  //
  //       // Sort by last modified time (newest first)
  //       // items.sort((a, b) {
  //       //   return File(b.path).lastModifiedSync().compareTo(File(a.path).lastModifiedSync());
  //       // });
  //
  //       if (ext == ".mp4") {
  //         _getVideos = items.where((element) => element.path.endsWith(ext)).toList();
  //         notifyListeners();
  //       } else {
  //         _getImages = items.where((element) => element.path.endsWith('.jpg')).toList();
  //         notifyListeners();
  //       }
  //     }
  //     _isWhatsappAvailable = true;
  //     notifyListeners();
  //   }
  // }


  Future<void> loadVideos() async {

    final permission = await PhotoManager.requestPermissionExtend();

    _isLoading = false;
    notifyListeners();

    // Fetch all video albums
    final List<AssetPathEntity> videoAlbums = await PhotoManager.getAssetPathList(
      type: RequestType.video, // Only fetch videos
    );

    // for (final AssetPathEntity album in videoAlbums) {
    //
    //   print(album.name);
    // }

    if (videoAlbums.isNotEmpty) {


      final specificAlbum = videoAlbums.firstWhere(
            (album) => album.name == "Story Saver",
        orElse: () => throw Exception('Album "Story Saver" not found'),
      );

      print('provider assetEntityCount ${await specificAlbum.assetCountAsync}');

      final List<AssetEntity> videos = await specificAlbum.getAssetListRange(
        start: 0,
        end: await specificAlbum.assetCountAsync, // Number of videos to fetch
      );

      print('in loadVideos $videos');

      _getMediaFile = videos;
      print('_getMediaFile $_getMediaFile');
      notifyListeners();

      print('end of loadAllVideos');

    }

    _isLoading = false;
    notifyListeners();

    print('end of savedMediaProvide');

  }

}


