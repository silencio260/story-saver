import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';

class MediaStoreVideos extends StatefulWidget {
  const MediaStoreVideos({Key? key}) : super(key: key);

  @override
  _MediaStoreVideosState createState() => _MediaStoreVideosState();
}

class _MediaStoreVideosState extends State<MediaStoreVideos> {
  List<AssetEntity> videoAssets = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadVideos();
  }

  Future<void> loadVideos() async {
    clearOldCachedFiles();
    print('!!!!!!!!! in load');
    // Request permission to access media
    final permission = await PhotoManager.requestPermissionExtend();
    print('!!!!!!!!! in load after photo manager request');
    if (!permission.isAuth) {
      // Handle permission denial
      print('!!!!!!!!! in load permission.isAuth');
      setState(() {
        isLoading = false;
        print('!!!!!!!!! in load setstate');
      });
      // return;
    }

    // Fetch all video albums
    final List<AssetPathEntity> videoAlbums = await PhotoManager.getAssetPathList(
      type: RequestType.video, // Only fetch videos
    );

    for (final AssetPathEntity album in videoAlbums) {

      print(album.name);
    }

    // print(videoAlbums.)

    print('!!!!!!!!! in load videoAlbum $videoAlbums');

    if (videoAlbums.isNotEmpty) {
      print('!!!!!!!!! in load videoAlbums.isNotEmpty');
      // Fetch all videos from the first album
      final specificAlbum = videoAlbums.firstWhere(
            (album) => album.name == "Story Saver",
            orElse: () => throw Exception('Album "Story Saver" not found'),
      );

      final List<AssetEntity> videos = await specificAlbum.getAssetListPaged(
        page: 0,
        size: await specificAlbum.assetCountAsync, // Number of videos to fetch
      );

      setState(() {
        videoAssets = videos;
        print('videoAssets $videoAssets');
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

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
    return Scaffold(
      appBar: AppBar(title: Text("MediaStore Videos")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : videoAssets.isNotEmpty
          ? ListView.builder(
        itemCount: videoAssets.length,
        itemBuilder: (context, index) {
          final video = videoAssets[index];
          return FutureBuilder<Uint8List?>(
            future: video.thumbnailData, // Fetch thumbnail data
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ListTile(
                  leading: CircularProgressIndicator(),
                  title: Text("Loading thumbnail..."),
                );
              }

              if (!snapshot.hasData || snapshot.data == null) {
                return ListTile(
                  leading: Icon(Icons.broken_image),
                  title: Text("Thumbnail not available"),
                );
              }

              return ListTile(
                leading: Image.memory(
                  snapshot.data!,
                  fit: BoxFit.cover,
                  width: 100,
                  height:  100,
                ),
                title: Text("Video ${index + 1}"),
                subtitle: Text("Duration: ${video.duration}s"),
                onTap: () async {
                  final file = await video.file; // Get the actual video file
                  if (file != null) {
                    print("Video Path: ${file.path}");
                  }
                },
              );
            },
          );
        },
      )
          : Center(child: Text("No Videos Found")),
    );
  }
}
