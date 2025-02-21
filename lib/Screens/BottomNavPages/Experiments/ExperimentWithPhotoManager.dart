import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';

import 'package:media_store_plus/media_store_plus.dart';
import 'package:provider/provider.dart';
import 'package:storysaver/Provider/savedMediaProvider.dart';
import 'package:storysaver/Screens/BottomNavPages/Experiments/image_tile.dart';
import 'package:storysaver/Screens/BottomNavPages/Experiments/video_tile.dart';
import 'package:storysaver/Utils/GetAssetEntityPath.dart';

class MediaStoreVideos extends StatefulWidget {
  const MediaStoreVideos({Key? key}) : super(key: key);

  @override
  _MediaStoreVideosState createState() => _MediaStoreVideosState();
}

class _MediaStoreVideosState extends State<MediaStoreVideos> with AutomaticKeepAliveClientMixin {
  List<AssetEntity> videoAssets = [];
  bool isLoading = true;
  int reBuildCount = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // loadVideos();


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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      // appBar: AppBar(title: Text("MediaStore Videos")),
      body: Consumer<GetSavedMediaProvider>(builder: (context, file, child) {
      //(
      //   builder: (context) {
        print("GetSavedMediaProvider__ ${file.getMediaFile}");
          return file.isLoading
              ? Center(child: CircularProgressIndicator())
              : file.getMediaFile.isNotEmpty
              ?
          GridView.builder(
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

                // print('saved_status_file ${video} - ${''}');

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
