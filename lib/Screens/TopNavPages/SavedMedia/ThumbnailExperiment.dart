import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storysaver/Provider/getStatusProvider.dart';
import 'package:storysaver/Utils/clearCache.dart';
import 'package:video_compress/video_compress.dart';


Stream<Uint8List> getThumbnails(List<FileSystemEntity> files) async* {
  for (final file in files) {
    try {
      final thumb = await VideoCompress.getByteThumbnail(
        file.path,
        quality: 100,
        position: -1,
      );

      if (thumb != null) {
        yield thumb;
      } else {
        yield* Stream.error('Failed to generate thumbnail for ${file.path}');
      }
    } catch (e) {
      yield* Stream.error('Error generating thumbnail for ${file.path}: $e');
    }
  }
}


class Thumbnailexperiment extends StatefulWidget {
  const Thumbnailexperiment({Key? key}) : super(key: key);


  @override
  State<Thumbnailexperiment> createState() => _ThumbnailexperimentState();
}

class _ThumbnailexperimentState extends State<Thumbnailexperiment> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    // Provider.of<GetStatusProvider>(context, listen: false).getExperimentalStatus('.mp4');
    clearOldCachedFiles();
  }

  bool _isFetched = false;

  String _counter = 'video';
  final String? title = 'vid';


  @override
  Widget build(BuildContext context) {
    return Consumer<GetStatusProvider>(
      builder: (context, provider, child) {
        final videoFiles = provider.getExperimentalFiles;
        return ListView.builder(
          itemCount: videoFiles.length,//provider.thumbnailCacheV2.length + 5 > videoFiles.length ? videoFiles.length : provider.thumbnailCacheV2.length + 5,
          //videoFiles.length, //provider.thumbnailCache.length + 1,
          itemBuilder: (context, index) {
            final videoPath = videoFiles[index].path;
            var thumbnail = provider.thumbnailCacheV2[videoPath];

            // Thumbnail().generate(videoPath);

            if (thumbnail == null) {
              // provider.generateThumbnailsWithExternalIsolates(videoPath);
              provider.generateThumbnailFromListAllVideos(videoPath);
              print(" +++++++++++++++++ index of current image $index ${provider.thumbnailCacheV2[videoPath]}");
              // final result = generateThumbnailInIsolate(videoPath).then((onValue) {

              return ListTile(
                title: Text("Video Loading $index"),
                leading: CircularProgressIndicator(),
              );
              // thumbnail = provider.thumbnailCache[videoPath];
            }



            return ListTile(
              title: Text("Video $index"),
              leading:
              // ThumbnailTile(thumbnailController: ThumbnailController(videoPath: videoFiles[index].path))
               Image.file(File(thumbnail!), fit: BoxFit.cover),
            );
          },
        );
      },
    // ),
    // ),
    );
  }
}















//     return Consumer<GetStatusProvider>(
//       builder: (context, provider, child) {
//         final videoFiles = provider.getExperimentalFiles; // Replace with your list of videos
//
//         return Expanded(
//           child: false//videoFiles.isEmpty
//               ? Center(child: Text('No videos available'))
//               : ListView.builder(
//             itemCount: 100,//videoFiles.length,
//             cacheExtent: 1000,
//             itemBuilder: (context, index) {
//               final videoPath = videoFiles[index].path; // Get the path of the video file
//               return ListTile(
//                 // title: Text(videoPath.split('/').last), // Show video name
//                 key: ValueKey(videoPath[index]),
//                 subtitle: VideoThumbnailWidget(videoPath: videoPath), // Display the thumbnail for the video
//               );
//             },
//           ),
//         );
//       },
//     );
//   }
// }
  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //       body: Consumer<GetStatusProvider>(builder: (context, file, child) {
  //         if (_isFetched == false) {
  //           file.getExperimentalStatus('.mp4');
  //           Future.delayed(const Duration(microseconds: 1), () {
  //             _isFetched = true;
  //           });
  //         }
  //         return file.isWhatsappAvailable == false
  //             ? const Center(
  //           child: Text('Whatsapp not available'),
  //         )
  //             : file.getExperimentalFiles.isEmpty
  //             ? Center(
  //           child: Text("No Videos available"),
  //         )
  //             : Container(
  //           padding: const EdgeInsets.all(20),
  //           child: StreamBuilder<List<Uint8List>>(
  //             stream: getThumbnailsStream(file.getExperimentalFiles),
  //             builder: (context, snapshot) {
  //               if (snapshot.connectionState == ConnectionState.waiting) {
  //                 return CircularProgressIndicator();
  //               }
  //
  //               if (snapshot.hasError) {
  //                 return Text('Error: ${snapshot.error}');
  //               }
  //
  //               if (snapshot.hasData) {
  //                 final thumbnails = snapshot.data!;
  //                 return ListView.builder(
  //                   itemCount: thumbnails.length,
  //                   itemBuilder: (context, index) {
  //                     return Image.memory(thumbnails[index]);
  //                   },
  //                 );
  //               }
  //
  //               return Text('No data');
  //             },
  //           ),
  //
  //
  //         );
  //       }));
  // }
// }

class VideoThumbnailWidget extends StatefulWidget {
  final String videoPath;

  VideoThumbnailWidget({required this.videoPath});

  @override
  _VideoThumbnailWidgetState createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  late Future<Uint8List> _thumbnailFuture;

  @override
  void initState() {
    super.initState();
    _thumbnailFuture = _generateThumbnail();
  }

  Future<Uint8List> _generateThumbnail() async {

    final thumb = await VideoCompress.getByteThumbnail(widget.videoPath,
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

  @override
  Widget build(BuildContext context) {
    // return Container(child: Image.memory(_thumbnailFuture);
    return FutureBuilder<Uint8List>(
      future: _thumbnailFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: Colors.grey[300],  // Placeholder color
            height: 200,              // Adjust height as needed
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error loading thumbnail'));
        }

        if (snapshot.hasData) {
          return Image.memory(snapshot.data!);
        }

        return Center(child: Text('No thumbnail available'));
      },
    );
  }
}