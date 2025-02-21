import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_isolate/flutter_isolate.dart';
import 'package:list_all_videos/thumbnail/generate_thumpnail.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:storysaver/Constants/constant.dart';
import 'package:storysaver/Utils/getThumbnails.dart';
import 'package:video_compress/video_compress.dart';

// import 'package:flutter_isolate/flutter_isolate.dart';
// import 'package:flutter/foundation.dart';  // For Isolates

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

  void addNewMediaToTop(AssetEntity newMedia) {
    _getMediaFile.insert(0, newMedia); // Insert at the top of the list
    notifyListeners(); // Notify UI listeners
  }



  Future<void> loadVideosWithIsolate() async {



    _isLoading = false;

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   notifyListeners();
    // });





    print('---------------***--- step 1');

    try {
      final receivePort = ReceivePort();
      var rootToken = RootIsolateToken.instance!;
      print('---------------***--- step 1.1 ${receivePort.sendPort}');
      final isolate = await Isolate.spawn(
        _fetchInBatchIsolate,
        {
          'sendPort': receivePort.sendPort,
          'rootToken': rootToken
        }, // Passing a map with parameters
      );
      // FlutterIsolate.spawn((message) {
      //   print("Hello from isolate: $message");
      // }, "Test Message");

      // Listening to the messages from the isolate
      receivePort.listen((message) {
        print('---------------***--- step 4');
        if (message == 'done') {
          print('Isolate finished processing.');
          receivePort.close(); // Close the port when done
          isolate.kill(priority: Isolate.immediate);
        }

        if (message is List<AssetEntity>) {

          // Update the list of fetched assets and notify listeners
          print("message ${message.length}");
          _getMediaFile.addAll(message);
          // notifyListeners();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            notifyListeners();
          });

        }
      });

    } catch (e, st) {
      print('Call Isolate.spawn $e, $st');
    }

    // try {
    //   print('---------------***--- step 1.1.1');
    //   // if(receivePort.sendPort != null)
    //     await Isolate.spawn(
    //     isolateFunction,
    //         {'sendPort': receivePort.sendPort}, // Pass the SendPort to the isolate
    //   );
    //   print('---------------***--- step 1.1.2');
    // } catch (e, st) {
    //   print('Call Isolate.spawn $e, $st');
    // }

    // await FlutterIsolate.spawn(
    //   isolateFunction,
    //   [receivePort.sendPort], // Pass the SendPort to the isolate
    // );
    // await FlutterIsolate.spawn(_generateThumbnailTask, [videoPath, receivePort.sendPort]);

    // Clean up when you're done
    // isolate.kill(priority: Isolate.immediate);
    // receivePort.close();




      // for (int i = 0; i < totalAssets; i += batchSize) {
      //   // Calculate the end index for the current batch
      //   int end = (i + batchSize) > totalAssets ? totalAssets : (i + batchSize);
      //
      //   // Fetch assets in the current batch
      //   final List<AssetEntity> videos = await specificAlbum.getAssetListRange(
      //     start: i,
      //     end: end,
      //   );
      //
      //   print('Fetched ${videos.length} items in batch from $i to $end');
      //
      //   // Add fetched videos to the media list
      //   _getMediaFile.addAll(videos);
      //   notifyListeners();
      // }

      print('object_ok');

      // print('provider assetEntityCount ${await specificAlbum.assetCountAsync}');
      //
      // final List<AssetEntity> videos = await specificAlbum.getAssetListRange(
      //   start: 0,
      //   end: 1000//await specificAlbum.assetCountAsync, // Number of videos to fetch
      // );
      //
      // print('in loadVideos $videos');
      //
      // _getMediaFile = videos;
      // print('_getMediaFile $_getMediaFile');
      // notifyListeners();
      //
      // print('end of loadAllVideos');


    _isLoading = false;
    notifyListeners();

    print('end of savedMediaProvide');

  }


  static Future<void> _fetchInBatchIsolate(Map<String, dynamic> params) async {
    SendPort sendPort = params['sendPort'];
    var rootToken = params['rootToken'];
    BackgroundIsolateBinaryMessenger.ensureInitialized(rootToken);

    try {
      await PhotoManager.requestPermissionExtend();

      final List<AssetPathEntity> videoAlbums = await PhotoManager.getAssetPathList(
        type: RequestType.fromTypes([RequestType.image, RequestType.video]), // Only fetch videos
        // type: RequestType.fromTypes([RequestType.image]),
      );

      // for (final AssetPathEntity album in videoAlbums) {
      //
      //   print(album.name);
      // }

      print('---------------***--- step 2.3');




      if (videoAlbums.isNotEmpty) {
        final specificAlbum = videoAlbums.firstWhere(
              (album) => album.name == "Story Saver",
          orElse: () => throw Exception('Album "Story Saver" not found'),
        );


        final int totalAssets = await specificAlbum.assetCountAsync;
        const int batchSize = 1000;


        List<AssetEntity> result = [];

        for (int i = 0; i < totalAssets; i += batchSize) {
          int end = (i + batchSize) > totalAssets ? totalAssets : (i +
              batchSize);

          final List<AssetEntity> videos = await specificAlbum.getAssetListRange(
            start: i,
            end: end,
          );

          sendPort.send(videos);

          print('Fetched ${videos.length} items in batch from $i to $end');


          // result.addAll(videos);
        }

        print('---------------***--- step 3');

        // Handle the result (e.g., print it, notify listeners, etc.)
        print('Total assets fetched: ${result.length}');
        // sendPort.send(result);
      }
    } catch(e){
      print('Error in Isolate $e');
    }

  }

   static isolateFunction(Map<String, dynamic> params) async {
    print('step 2.2');
    // SendPort sendPort = args[0];
    final SendPort sendPort = params['sendPort'];
    for (int i = 1; i <= 1000; i++) {
      await Future.delayed(Duration(milliseconds: 10)); // Simulate some delay
      sendPort.send("Count: $i");
    }
    sendPort.send("Counting complete!");
  }


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

  Future<void> loadVideosSegmented() async {

    final permission = await PhotoManager.requestPermissionExtend();

    _isLoading = false;
    notifyListeners();

    // Fetch all video albums
    final List<AssetPathEntity> videoAlbums = await PhotoManager.getAssetPathList(
      type: RequestType.fromTypes([RequestType.image, RequestType.video]),
    );



    if (videoAlbums.isNotEmpty) {


      final specificAlbum = videoAlbums.firstWhere(
            (album) => album.name == "Story Saver",
        orElse: () => throw Exception('Album "Story Saver" not found'),
      );

      print('provider assetEntityCount ${await specificAlbum.assetCountAsync}');

      // final List<AssetEntity> videos = await specificAlbum.getAssetListRange(
      //   start: 0,
      //   end: await specificAlbum.assetCountAsync, // Number of videos to fetch
      // );
      //
      // print('in loadVideos $videos');
      //
      // _getMediaFile = videos;
      // print('_getMediaFile $_getMediaFile');
      // notifyListeners();
      //
      // print('end of loadAllVideos');


      ///////////////
      final int totalAssets = await specificAlbum.assetCountAsync;
      const int batchSize = 10;

      for (int i = 0; i < totalAssets; i += batchSize) {
        // Calculate the end index for the current batch
        int end = (i + batchSize) > totalAssets ? totalAssets : (i + batchSize);

        // Fetch assets in the current batch
        final List<AssetEntity> videos = await specificAlbum.getAssetListRange(
          start: i,
          end: end,
        );

        print('Fetched ${videos.length} items in batch from $i to $end');

        // Add fetched videos to the media list
        _getMediaFile.addAll(videos);
        notifyListeners();
      }


    }

    _isLoading = false;
    notifyListeners();

    print('end of savedMediaProvide');

  }

}


