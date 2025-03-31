import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter_isolate/flutter_isolate.dart';
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


  return thumb;
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


  try {
    // Generate the thumbnail using the async library function
    final thumbnail = await VideoCompress.getByteThumbnail(
      videoPath,
      quality: 100, // Adjust quality if needed
      position: -1, // Default position
    );

    print("thumb in isolate generated ");
    // Send the result back to the main isolate
    sendPort.send(thumbnail);
  } catch (e) {
    print("Error generating thumbnail 2: $e");
    sendPort.send(null);
  }
}

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
