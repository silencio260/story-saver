import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';

import 'package:media_store_plus/media_store_plus.dart';
import 'package:provider/provider.dart';
import 'package:storysaver/Provider/savedMediaProvider.dart';
import 'package:storysaver/Screens/BottomNavPages/Experiments/Widget/GridMediaItems.dart';
import 'package:storysaver/Screens/BottomNavPages/Experiments/Widget/image_tile.dart';
import 'package:storysaver/Screens/BottomNavPages/Experiments/Widget/video_tile.dart';
import 'package:storysaver/Utils/GetAssetEntityPath.dart';
import 'package:storysaver/Utils/SavedMediaManager.dart';
import 'package:storysaver/Utils/saveStatus.dart';
import 'package:storysaver/Widget/SavedMediaPhotoViewWrapper.dart';
import 'package:visibility_detector/visibility_detector.dart';

class MediaStoreVideos extends StatefulWidget {
  const MediaStoreVideos({Key? key}) : super(key: key);

  @override
  _MediaStoreVideosState createState() => _MediaStoreVideosState();
}

class _MediaStoreVideosState extends State<MediaStoreVideos> with AutomaticKeepAliveClientMixin {
  List<AssetEntity> videoAssets = [];
  bool isLoading = true;
  int reBuildCount = 0;
  final ScrollController _scrollController = ScrollController();
  final mediaManager = SavedMediaManager();

  bool _keepWidgetAlive = true;

  void toggleKeepAlive(bool value) {
    if(_keepWidgetAlive != value)
    setState(() {
      _keepWidgetAlive = value;
    });
  }

  @override
  bool get wantKeepAlive => true;

  // @override
  // bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // loadVideos();

    // print("MediaStoreVideos initState");


    // Provider.of<GetSavedMediaProvider>(context, listen: false).loadVideos();
    // print("GetSavedMediaProvider__ ${GetSavedMediaProvider().loadVideos()}");
    // setState(() {
    //   print('iinit asset');
    //   videoAssets = GetSavedMediaProvider().getMediaFile;
    //   print('videoAssets - $videoAssets');
    //   isLoading = false;
    // });
  }

  // Future<void> loadVideos() async {
  //   print('!!!!!!!!! in load');
  //   // Request permission to access media
  //   final permission = await PhotoManager.requestPermissionExtend();
  //   print('!!!!!!!!! in load after photo manager request');
  //   if (!permission.isAuth) {
  //     // Handle permission denial
  //     print('!!!!!!!!! in load permission.isAuth');
  //     setState(() {
  //       isLoading = false;
  //       print('!!!!!!!!! in load setstate');
  //     });
  //     // return;
  //   }
  //
  //   // Fetch all video albums
  //   final List<AssetPathEntity> videoAlbums = await PhotoManager.getAssetPathList(
  //     type: RequestType.video, // Only fetch videos
  //   );
  //
  //   // for (final AssetPathEntity album in videoAlbums) {
  //   //
  //   //   print(album.name);
  //   // }
  //
  //   // print(videoAlbums.)
  //
  //   // print('!!!!!!!!! in load videoAlbum $videoAlbums');
  //
  //   if (videoAlbums.isNotEmpty) {
  //     print('!!!!!!!!! in load videoAlbums.isNotEmpty');
  //     // Fetch all videos from the first album
  //     final specificAlbum = videoAlbums.firstWhere(
  //           (album) => album.name == "Story Saver",
  //           orElse: () => throw Exception('Album "Story Saver" not found'),
  //     );
  //
  //     print(' assetEntityCount ${await specificAlbum.assetCountAsync}');
  //
  //     final List<AssetEntity> videos = await specificAlbum.getAssetListRange(
  //       start: 0,
  //       end: 10, // Number of videos to fetch
  //     );
  //
  //     setState(() {
  //
  //       videoAssets = videos;
  //       print('videoAssets $videoAssets');
  //
  //       isLoading = false;
  //     });
  //   } else {
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }

  Future<void> clearOldCachedFiles() async {
    final cacheDir = await getTemporaryDirectory();
    final now = DateTime.now();

    if (cacheDir.existsSync()) {
      final files = cacheDir.listSync(); // List all files in the cache directory

      for (final file in files) {
        final stat = file.statSync(); // Get file stats
        final lastModified = stat.modified; // Get last modified time

        print("temp dir $file $lastModified ${files.length}");

        print("file life ${now.difference(lastModified).inHours }");

        // Check if the file is older than 24 hours
        if (now.difference(lastModified) > const Duration(hours: 24)) {
          print("file life ${now.difference(lastModified) }");
          file.deleteSync(); // Delete the file
        }
      }
    }
  }

  String extractKeyString(Key key) {
    if (key is ValueKey<String>) {
      return key.value;
    }
    return 'Unknown Key';
  }

  int? extractNumberAsInt(String input) {
    RegExp regex = RegExp(r'\d+');
    Match? match = regex.firstMatch(input);
    return match != null ? int.parse(match.group(0)!) : null;
  }

  void loadMoreItem () {
    Provider.of<GetSavedMediaProvider>(context, listen: false).loadVMediaInStaggeredBatches();
  }

  void confirmFileDeleteDialog(BuildContext context, String message, String fileName, GetSavedMediaProvider file, int index) {
    Future.delayed(Duration.zero, () {
      showDialog(
        context: context,
        // barrierDismissible: false, // Prevents user from tapping outside to dismiss
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: Text("Error"),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.popUntil(dialogContext, (route) => route.isFirst);
                },
                child: Text("Cancel", style: TextStyle(color: Colors.grey),),
              ),
              TextButton(
                onPressed: () {
                  deleteMedia(fileName, file, index);
                  Navigator.popUntil(dialogContext, (route) => route.isFirst);
                },
                child: Text("OK", style: TextStyle(color: Colors.red),),
              ),
            ],
          );
        },
      );
    });
  }

  void deleteMedia(String fileName, GetSavedMediaProvider file, int index) {

    mediaManager.deleteMedia(fileName);
    file.removeFrom(index);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      // appBar: AppBar(title: Text("MediaStore Videos")),
      body: Consumer<GetSavedMediaProvider>(builder: (context, file, child) {
      //(
      //   builder: (context) {
      //   print("GetSavedMediaProvider__ ${file.getMediaFile}");

        // if(!file.isLoading){
        //   // toggleKeepAlive(true);
        //   toggleKeepAlive(false);
        //   print("toggleKeepAlive");
        // } else {
        //   // toggleKeepAlive(false);
        // }

        // if (file.isLoading) {
        //   WidgetsBinding.instance.addPostFrameCallback((_) {
        //     if (mounted) {
        //       // setState(() {
        //         toggleKeepAlive(false);
        //         file.setIsLoading(false);
        //       // });
        //     }
        //   });
        //   print("toggleKeepAlive");
        // }
        // else {
        //   WidgetsBinding.instance.addPostFrameCallback((_) {
        //     if (mounted) {
        //       toggleKeepAlive(true);
        //     }
        //   });
        // }
          return file.isLoading
              ? Center(child: CircularProgressIndicator())
              : file.getMediaFile.isNotEmpty
              ?
          GridView.builder(
            // key: ValueKey(file.getMediaFile.length),
            gridDelegate:
            const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 300, // Each item max width = 150
              crossAxisSpacing: 5,
              mainAxisSpacing: 8,
              childAspectRatio: 0.95,
            ),
            itemCount: file.getMediaFile.length,
              itemBuilder: (BuildContext context, int index) {

                // print('GetSavedMediaProvider().getMediaFile[index] $video');

                final video = file.getMediaFile[index];

                // // print('saved_status_file ${file.nextLoadTrigger} - ${''}');
                // print('saved_status_file ${file.getMediaFile.length} - ${''}');
                // print('saved_status_file_title ${file.getMediaFile[0].title} - ${''}');
                // print('saved_status_file_video ${video.title} - ${index}');

                // return Dismissible( // ✅ Allows swipe-to-remove without full rebuild
                //   key: ValueKey(video),
                //   direction: DismissDirection.up,
                //   onDismissed: (_) => file.removeFrom(index),
                //   background: Container(color: Colors.red),
                //   child: SavedMediaGridItem(video: video),
                // );

                // return AnimatedSwitcher(
                //   duration: Duration(milliseconds: 300),
                //   child: VisibilityDetector(
                //     onVisibilityChanged: (visibilityInfo) {
                //       var visiblePercentage = visibilityInfo.visibleFraction * 100;
                //       String nextLoadTriggerItem = 'item_${file.nextLoadTrigger}';
                //
                //       debugPrint(
                //           'Widget ${visibilityInfo.key} is ${visiblePercentage}% visible');
                //
                //
                //       debugPrint(
                //           'NextTrigger - $nextLoadTriggerItem - ${file.nextLoadTrigger} =  key is ${extractKeyString(visibilityInfo.key)}');
                //       print('file.getMediaFile.length ${file.getMediaFile.length}');
                //
                //       String keyAsString = extractKeyString(visibilityInfo.key);
                //       int? keyAsInt = extractNumberAsInt(keyAsString);
                //
                //       if((keyAsString == nextLoadTriggerItem && visiblePercentage >= 50) ||
                //           ( keyAsInt != null && keyAsInt >= file.nextLoadTrigger)
                //       ){
                //
                //
                //         if(file.numLoadedAssets <= file.totalNumAssets && !file.isProcessingMedia){
                //           loadMoreItem();
                //           file.setNewLoadTrigger();
                //           print('Load More Media Files nextLoadTrigger = ${file.nextLoadTrigger} - numLoadedAssets = ${file.numLoadedAssets} ');
                //         }
                //
                //       }
                //     },
                //     key: Key('item_$index'),
                //     child: Container(
                //       key: ValueKey(file.getMediaFile[index]),
                //       child: Column(
                //         children: [
                //           SizedBox(child: SavedMediaGridItem(video: video), height: 90),
                //
                //           GestureDetector(
                //             // key: ValueKey(file.getMediaFile[index]),
                //             onTap: () => {
                //               print('index_to_delete ${index}'),
                //               file.removeFrom(index)
                //             },
                //             child: Container(
                //               alignment: Alignment.center,
                //               color: Colors.blueAccent,
                //               child: Text(file.getMediaFile[index].id, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),),
                //               // child: Text(
                //               //   '${file.getMediaFile[index]}',
                //               //   style: TextStyle(color: Colors.white, fontSize: 20),
                //               // ),
                //             ),
                //           ),
                //         ],
                //       ),
                //     ),
                //   ),
                // );

                return AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  key: ValueKey(file.getMediaFile[index]),
                  child: VisibilityDetector(
                    key: Key('item_$index'),
                    onVisibilityChanged: (visibilityInfo) {
                      var visiblePercentage = visibilityInfo.visibleFraction * 100;
                      String nextLoadTriggerItem = 'item_${file.nextLoadTrigger}';

                      debugPrint(
                          'Widget ${visibilityInfo.key} is ${visiblePercentage}% visible');


                      debugPrint(
                          'NextTrigger - $nextLoadTriggerItem - ${file.nextLoadTrigger} = extractKeyString key is ${extractKeyString(visibilityInfo.key)} // key = ${visibilityInfo.key}');
                      print('file.getMediaFile.length ${file.getMediaFile.length}');

                      String keyAsString = extractKeyString(visibilityInfo.key);
                      int? keyAsInt = extractNumberAsInt(keyAsString);

                      if((keyAsString == nextLoadTriggerItem && visiblePercentage >= 50) ||
                          ( keyAsInt != null && keyAsInt >= file.nextLoadTrigger) ){

                        if(file.numLoadedAssets <= file.totalNumAssets && !file.isProcessingMedia){
                          loadMoreItem();
                          file.setNewLoadTrigger();
                          print('Load More Media Files nextLoadTrigger = ${file.nextLoadTrigger} - numLoadedAssets = ${file.numLoadedAssets} ');
                        }

                      }
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(0),
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 90,
                            child: GestureDetector(

                            onTap: () {

                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                    builder: (_) =>
                                        SavedMediaPhotoViewWrapper(initialIndex: index, isVideoView: true,
                                            galleryItems: Provider.of<GetSavedMediaProvider>(context, listen: false).getMediaFile)
                                  // VideoView(videoPath: widget.videoFilePath),
                                ),
                              );
                          },
                          child: SavedMediaGridItem(video: video),
                            ),
                          ),//160),


                          GestureDetector(

                            onTap: () =>
                            {
                              // deleteSaveStatus(context, file.getMediaFile[index]),
                              print('Media Manger ${file.getMediaFile[index].title.toString()}'),

                              confirmFileDeleteDialog(
                                  context,
                                  'Are you sure you want to delete?',
                                  file.getMediaFile[index].title.toString(),
                                file,
                                index
                              ),

                              // mediaManager.deleteMedia(file.getMediaFile[index].title.toString()),
                              // file.removeFrom(index)
                            },
                            child: Text(index.toString(), style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: Colors.red),),
                          ),


                          // GestureDetector(
                          //   behavior: HitTestBehavior.opaque,
                          //   onTap: () {
                          //     file.removeFrom(index);
                          //     // file.getMediaFile.removeAt(index);
                          //
                          //     setState(() {
                          //       file.removeFrom(index);
                          //     });
                          //     print('Remove_Element $index ${file.getMediaFile.length}');
                          //
                          //   },
                          //   child: Text(index.toString(), style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: Colors.red),),
                          // )
                        ],

                      ),
                    ),
                  ),
                );

                return VisibilityDetector(
                  key: Key('item_$index'),
                  onVisibilityChanged: (visibilityInfo) {
                    var visiblePercentage = visibilityInfo.visibleFraction * 100;
                    String nextLoadTriggerItem = 'item_${file.nextLoadTrigger}';

                    debugPrint(
                        'Widget ${visibilityInfo.key} is ${visiblePercentage}% visible');


                    debugPrint(
                        'NextTrigger - $nextLoadTriggerItem - ${file.nextLoadTrigger} =  key is ${extractKeyString(visibilityInfo.key)}');
                    print('file.getMediaFile.length ${file.getMediaFile.length}');

                    String keyAsString = extractKeyString(visibilityInfo.key);
                    int? keyAsInt = extractNumberAsInt(keyAsString);

                    if((keyAsString == nextLoadTriggerItem && visiblePercentage >= 50) ||
                        ( keyAsInt != null && keyAsInt >= file.nextLoadTrigger)
                    ){


                      if(file.numLoadedAssets <= file.totalNumAssets && !file.isProcessingMedia){
                        loadMoreItem();
                        file.setNewLoadTrigger();
                        print('Load More Media Files nextLoadTrigger = ${file.nextLoadTrigger} - numLoadedAssets = ${file.numLoadedAssets} ');
                      }

                    }
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(0),
                    ),
                    child: Column(
                      children: [
                        SizedBox(child: SavedMediaGridItem(video: video), height: 90),//160),


                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            file.removeFrom(index);
                            // file.getMediaFile.removeAt(index);

                            setState(() {
                              file.removeFrom(index);
                            });
                            print('Remove_Element $index ${file.getMediaFile.length}');

                          },
                          child: Text(index.toString(), style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: Colors.red),),
                        )
                      ],

                    ),
                  ),
                );
                return SavedMediaGridItem(video: video);
                return FutureBuilder<dynamic>(
                  future: video.type == AssetType.video ? video.thumbnailData : video.file, // Fetch thumbnail data
                  builder: (context, snapshot) {

                    // print('in FutureBuilder snapshot.hasData: ${snapshot.hasData} - file.getMediaFile $index: ${video.thumbnailData}');
                    // final f = await video.file;
                    // f.path;
                    // if(video.type == AssetType.image)
                    //   print("Path: ${} ${video.title}");

                    print(snapshot.data);
                    reBuildCount += 1;

                    return video.type == AssetType.video ?
                    VideoTile(snapshot: snapshot) :
                    ImageTile(snapshot: snapshot);
                  },
                );
              },
          )
              : Center(child: Text("No Videos Found"));
        }
      ),
    );
  }
}
