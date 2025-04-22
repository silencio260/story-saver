import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:storysaver/Constants/constant.dart';


class GetSavedMediaProvider extends ChangeNotifier {
  bool _isFolderAvailable = false;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // final GlobalKey<AnimatedListState> listKey = GlobalKey<AnimatedListState>();

  void setIsLoading(bool value) {
    _isLoading = value;
    notifyListeners(); // ✅ Notify UI when state changes
  }

  bool _isProcessingMedia = false;
  bool get isProcessingMedia => _isProcessingMedia;

  bool stopLoadingMedia = false;

  List<AssetEntity> _getMediaFile = [];
  List<AssetEntity> get getMediaFile => _getMediaFile;
  static AssetPathEntity? savedMediaAlbum = null;

  bool _buildCachedFirstItem = false;
  bool get buildCachedFirstItem => _buildCachedFirstItem;
  AssetEntity? _prevFirstItem = null;
  AssetEntity? get prevFirstItem => _prevFirstItem;


  int _loadAlbumSegmentBatchSize = 50;//500;
  int get loadAlbumSegmentBatchSize => _loadAlbumSegmentBatchSize;
  int _loopBatchSize = 10;

  int _loadAlbumStartIndex = 0;
  int get loadAlbumStartIndex => _loadAlbumStartIndex;

  int _loadTriggerInterval = 10;
  int _nextLoadTrigger = 20;//250;
  int get nextLoadTrigger => _nextLoadTrigger;

  int _totalNumAssets = 0;
  int get totalNumAssets => _totalNumAssets;

  int _numLoadedAssets = 0;
  int get numLoadedAssets => _numLoadedAssets;

  void setNewLoadTrigger() {
    if(stopLoadingMedia == false){
    _nextLoadTrigger += _loadTriggerInterval;
    notifyListeners();
    }
  }




  void removeFrom(int index) {

    _getMediaFile.removeAt(index);

    notifyListeners(); // Notify UI listeners
  }

  void addNewMediaToTop(AssetEntity newMedia) {

    _prevFirstItem = _getMediaFile[0];
    _buildCachedFirstItem = true;
    _getMediaFile = [newMedia, ..._getMediaFile];

    notifyListeners(); // Notify UI listeners
  }

  void reSetBuildVariables() {

    _prevFirstItem = null;
    _buildCachedFirstItem = false;
    notifyListeners();
  }



  void preventDuplicateAddition(AssetEntity newMedia) {
    bool isAlreadySaved = _getMediaFile.any((file) => file.title == newMedia.title);
    print('Alredy Saved ${isAlreadySaved}');
    if(isAlreadySaved) {
      final oldFile = _getMediaFile.removeWhere((item) =>
      item.title == newMedia.title); // Insert at the top of the list

      print('Old File');
    }
    notifyListeners(); // Notify UI listeners
  }


  Future<void> loadVideosWithIsolate() async {
    _isLoading = false;


    // print('---------------***--- step 1');

    try {
      final receivePort = ReceivePort();
      var rootToken = RootIsolateToken.instance!;
      // print('---------------***--- step 1.1 ${receivePort.sendPort}');
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
        // print('---------------***--- step 4');
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

    // print('object_ok');


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

      final List<AssetPathEntity> videoAlbums =
          await PhotoManager.getAssetPathList(
        type: RequestType.fromTypes(
            [RequestType.image, RequestType.video]), // Only fetch videos
        // type: RequestType.fromTypes([RequestType.image]),
      );

      // print('---------------***--- step 2.3');

      if (videoAlbums.isNotEmpty) {
        final specificAlbum = videoAlbums.firstWhere(
          (album) => album.name == "Story Saver",
          orElse: () => throw Exception('Album "Story Saver" not found'),
        );

        final int totalAssets = await specificAlbum.assetCountAsync;
        const int batchSize = 1000;

        List<AssetEntity> result = [];

        for (int i = 0; i < totalAssets; i += batchSize) {
          int end =
              (i + batchSize) > totalAssets ? totalAssets : (i + batchSize);

          final List<AssetEntity> videos =
              await specificAlbum.getAssetListRange(
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
    } catch (e) {
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

    // Fetch all video albums
    final List<AssetPathEntity> videoAlbums =
        await PhotoManager.getAssetPathList(
      type: RequestType.video, // Only fetch videos
    );


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

    print('end of savedMediaProvide');
  }

  Future<void> loadVideosSegmented() async {
    final permission = await PhotoManager.requestPermissionExtend();

    _isLoading = false;
    notifyListeners();

    // Fetch all video albums
    final List<AssetPathEntity> videoAlbums =
        await PhotoManager.getAssetPathList(
      type: RequestType.fromTypes([RequestType.image, RequestType.video]),
    );

    if (videoAlbums.isNotEmpty) {
      final specificAlbum = videoAlbums.firstWhere(
        (album) => album.name == "Saved Saver",
        orElse: () => throw Exception('Album "Story Saver" not found'),
      );

      print('provider assetEntityCount ${await specificAlbum.assetCountAsync}');


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

  Future<AssetPathEntity?> GetSavedMediaAlbum() async {
    try {
      final permission = await PhotoManager.requestPermissionExtend();

      // Fetch albums
      final List<AssetPathEntity> mediaAlbums =
          await PhotoManager.getAssetPathList(
        type: RequestType.fromTypes([RequestType.image, RequestType.video]),
      );

      if (mediaAlbums.isNotEmpty) {
        final specificAlbum = await mediaAlbums.firstWhere(
          (album) => album.name == AppConstants.SAVED_STORY_PATH,
          orElse: () => throw Exception('Album "Story Saver" not found'),
        );


        print('provider assetEntityCount ${await specificAlbum.assetCountAsync}');
        savedMediaAlbum = specificAlbum;
        notifyListeners();

        return specificAlbum; //Future.value(specificAlbum);
      }
    } catch (e) {
      print('Album not found: $e');
    }

    return null; // Return null if no albums found
  }

  Future<void> loadVMediaInStaggeredBatches() async {

    _isProcessingMedia = true;
    notifyListeners();

    AssetPathEntity? specificAlbum = savedMediaAlbum;

    if (specificAlbum == null) {
      specificAlbum = await GetSavedMediaAlbum();
    }

    ///////////////
    _totalNumAssets = await specificAlbum!.assetCountAsync; //135;
    final int totalAssets = _totalNumAssets;
    final int batchSize = _loopBatchSize;
    print('assetCountAsync ${totalAssets}');


    final int startIndex = _loadAlbumStartIndex;

    final checkRemainingAssetCount =
        startIndex + _loadAlbumSegmentBatchSize < totalAssets
            ? startIndex + _loadAlbumSegmentBatchSize
            : totalAssets;

    final int endIndex = checkRemainingAssetCount;

    // print('count of _loadAlbumStartIndex -> $_loadAlbumStartIndex');
    // print('count of startIndex -> $startIndex');
    // print('count of _loadAlbumSegmentBatchSize -> $_loadAlbumSegmentBatchSize');
    // print('count of endIndex -> $endIndex');
    // print('count of totalCount -> $totalAssets');
    // print('count of _nextLoadTrigger -> $_nextLoadTrigger');
    // print('count of _numLoadedAssets -> $_numLoadedAssets');

    if(_numLoadedAssets < totalAssets) {
      _numLoadedAssets += _loadAlbumSegmentBatchSize;
      notifyListeners();
      // print('inside LoadMedia _numLoadedAssets =  $_numLoadedAssets totalAssets = $totalAssets');
      // print('inside LoadMedia_2 startIndex =  $startIndex endIndex =  $endIndex checkRemainingAssetCount = $checkRemainingAssetCount');
      for (int i = startIndex; i < endIndex; i += batchSize) {
        // Calculate the end index for the current batch
        int end = (i + batchSize) > totalAssets ? totalAssets : (i + batchSize);

        // Fetch assets in the current batch
        final List<AssetEntity> videos = await specificAlbum!.getAssetListRange(
          start: i,
          end: end,
        );

        // print('Fetched ${videos.length} items in batch from $i to $end');

        _getMediaFile = updateMediaFiles(_getMediaFile, videos); //.addAll(videos);


        notifyListeners();
      }
      // print('inside LoadMedia _getMediaFile = ${_getMediaFile.length}');
      // print('inside LoadMedia start = $startIndex | end = $endIndex');

      _loadAlbumStartIndex += _loadAlbumSegmentBatchSize;

    } else {
      stopLoadingMedia = true;

    }

    _isProcessingMedia = false;
    notifyListeners();

    // print('end of savedMediaProvide');
  }
}

List<AssetEntity>  updateMediaFiles(List<AssetEntity>  _getMediaFile, List<AssetEntity>  newFiles) {
  // Convert _getMediaFile to a Set for quick lookup
  Set<AssetEntity> existingFiles = _getMediaFile.toSet();

  // Remove duplicates: Keep only items in `videos` that are NOT in `_getMediaFile`
  List<AssetEntity> uniqueVideos = newFiles.where((file) => !existingFiles.contains(file)).toList();

  // Add unique videos to _getMediaFile
  _getMediaFile.addAll(uniqueVideos);

  // print("Updated _getMediaFile: $_getMediaFile");
  return _getMediaFile;
}


