// import 'package:get_thumbnail_video/index.dart';
// import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:flutter_video_thumbnail_plus/flutter_video_thumbnail_plus.dart';
import 'package:video_compress/video_compress.dart';

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
