// import 'package:get_thumbnail_video/index.dart';
// import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_video_thumbnail_plus/flutter_video_thumbnail_plus.dart';
import 'package:video_compress/video_compress.dart';


import 'package:photo_manager/photo_manager.dart';

Future<AssetPathEntity?> getSpecificAlbum(String albumName) async {
  final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList();

  for (final AssetPathEntity album in albums) {
    if (album.name == albumName) {
      return album; // Return the specific album
    }
  }
  return null; // Album not found
}

Future<List<AssetEntity>> getAssetsFromAlbum(AssetPathEntity album) async {
  final List<AssetEntity> assets = await album.getAssetListRange(
    start: 0,
    end: await album.assetCountAsync,//album.assetCount,
  );
  return assets;
}




Future<Uint8List> getThumbnail(String path) async {
  // XFile thumb = await VideoThumbnail.thumbnailFile(video: path);
  // final thumb = await VideoCompress.getFileThumbnail(path,
  //     quality: 50, // default(100)
  //     position: -1 // default(-1)
  //     );
  // final thumb = await FlutterVideoThumbnailPlus.thumbnailFile(
  //   video: path,
  //   thumbnailPath: (await getTemporaryDirectory()).path,
  //   // imageFormat: ImageFormat.png, //ImageFormat.png,
  //   // maxHeight: 100,
  //   // maxWidth: 100,
  //   // timeMs: 1000,
  //   quality: 100,
  // );
  // print('------------- in get thumbnail');
  // print(thumb);

  final thumb = await VideoCompress.getByteThumbnail(path,
      quality: 100, // default(100)
      position: -1 // default(-1)
      );

  print('------------- in get thumbnail');
  print(thumb);

  if (thumb == null) {
    print('Error with Thumbnail generation');
    throw Exception('Failed to generate thumbnail');
  }

  // XFile thumb = await VideoThumbnail.thumbnailFile(
  //   video: path,
  //   thumbnailPath: (await getTemporaryDirectory()).path,
  //   imageFormat: ImageFormat.JPEG,
  //   maxWidth: 128,
  //   quality: 25,
  // );
  // print('Thumbnail generated: ${thumb.path}');
  // print(thumb);
  return thumb;
}

//
// Stream<Uint8List> getThumbnailStream(String path) async* {
//   try {
//     final thumb = await VideoCompress.getByteThumbnail(
//       path,
//       quality: 100,
//       position: -1,
//     );
//
//     if (thumb == null) {
//       throw Exception('Failed to generate thumbnail');
//     }
//
//     yield thumb;
//   } catch (e) {
//     print('Error generating thumbnail: $e');
//   }
// }

























Stream<List<Uint8List>> getThumbnailsStream(List<String> paths) async* {
  List<Uint8List> thumbnails = [];

  for (var path in paths) {
    try {
      final thumb = await VideoCompress.getByteThumbnail(path, quality: 100, position: -1);
      if (thumb != null) {
        thumbnails.add(thumb);
      }
    } catch (e) {
      print('Error generating thumbnail for $path: $e');
    }

    // Yield the list as a chunk after processing each thumbnail
    yield List.from(thumbnails);  // Emit the current state of thumbnails list
  }
}



// // A helper class to pass arguments to the isolate
// class ThumbnailRequest {
//   final String path;
//   final SendPort sendPort;
//
//   ThumbnailRequest(this.path, this.sendPort);
// }
//
// // The function that runs in the isolate
// Future<void> generateThumbnailInIsolate(ThumbnailRequest request) async {
//   // Ensure WidgetsFlutterBinding is initialized
//   WidgetsFlutterBinding.ensureInitialized();
//
//   try {
//     final Uint8List? thumb = await VideoCompress.getByteThumbnail(
//       request.path,
//       quality: 100,
//       position: -1,
//     );
//
//     if (thumb == null) {
//       throw Exception('Failed to generate thumbnail');
//     }
//
//     request.sendPort.send(thumb);
//   } catch (e) {
//     request.sendPort.send({'error': e.toString()});
//   }
// }
//
// // Stream function to generate thumbnails one at a time using isolates
// Stream<Uint8List> getThumbnailsStream(List<FileSystemEntity> entities) async* {
//   for (final entity in entities) {
//     if (entity is File) {
//       final String path = entity.path;
//       final ReceivePort receivePort = ReceivePort();
//
//       try {
//         // Spawn an isolate for each video thumbnail
//         await Isolate.spawn(
//           generateThumbnailInIsolate,
//           ThumbnailRequest(path, receivePort.sendPort),
//         );
//
//         // Wait for data from the isolate
//         final result = await receivePort.first;
//
//         if (result is Uint8List) {
//           yield result;
//         } else if (result is Map && result['error'] != null) {
//           print('Error generating thumbnail for $path: ${result['error']}');
//         }
//       } catch (e) {
//         print('Error generating thumbnail for $path: $e');
//       } finally {
//         receivePort.close();
//       }
//     }
//   }
// }