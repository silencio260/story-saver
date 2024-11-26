import 'package:get_thumbnail_video/index.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';

Future<XFile> getThumbnail(String path) async {
  // XFile thumb = await VideoThumbnail.thumbnailFile(video: path);
  XFile thumb = await VideoThumbnail.thumbnailFile(
    video: path,
    thumbnailPath: (await getTemporaryDirectory()).path,
    imageFormat: ImageFormat.JPEG,
    maxWidth: 128,
    quality: 25,
  );
  // print('Thumbnail generated: ${thumb.path}');
  // print(thumb);
  return thumb;
}
