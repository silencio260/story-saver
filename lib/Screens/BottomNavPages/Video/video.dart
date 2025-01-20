import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:provider/provider.dart';
import 'package:storysaver/Provider/getStatusProvider.dart';
import 'package:storysaver/Screens/BottomNavPages/Images/Image_view.dart';
import 'package:storysaver/Screens/BottomNavPages/Video/video_view.dart';
import 'package:storysaver/Utils/getThumbnails.dart';

// import 'package:file_selector/file_selector.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:video_compress/video_compress.dart';
// import 'package:video_compress_example/video_thumbnail.dart';

class VideoHomePage extends StatefulWidget {
  const VideoHomePage({Key? key}) : super(key: key);

  @override
  State<VideoHomePage> createState() => _VideoHomePageState();
}

class _VideoHomePageState extends State<VideoHomePage> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    Provider.of<GetStatusProvider>(context, listen: false).getStatus('.jpg');
  }

  bool _isFetched = false;

  String _counter = 'video';
  final String? title = 'vid';

//   Future<void> _compressVideo() async {
//     var file;
//     if (Platform.isMacOS) {
//       final typeGroup = XTypeGroup(label: 'videos', extensions: ['mov', 'mp4']);
//       file = await openFile(acceptedTypeGroups: [typeGroup]);
//     } else {
//       final picker = ImagePicker();
//       var pickedFile = await picker.pickVideo(source: ImageSource.gallery);
//       file = File(pickedFile!.path);
//     }
//     if (file == null) {
//       return;
//     }
//     await VideoCompress.setLogLevel(0);
//     final info = await VideoCompress.compressVideo(
//       file.path,
//       quality: VideoQuality.MediumQuality,
//       deleteOrigin: false,
//       includeAudio: true,
//     );
//     print(info!.path);
//     setState(() {
//       _counter = info.path!;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(title!),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             Text(
//               'You have pushed the button this many times:',
//             ),
//             Text(
//               '$_counter',
//               style: Theme.of(context).textTheme.headlineMedium,
//             ),
//             InkWell(
//                 child: Icon(
//                   Icons.cancel,
//                   size: 55,
//                 ),
//                 onTap: () {
//                   VideoCompress.cancelCompression();
//                 }),
//             ElevatedButton(
//               onPressed: () {
//                 // Navigator.push(
//                 //   context,
//                 //   MaterialPageRoute(builder: (context) => VideoThumbnail()),
//                 // );
//               },
//               child: Text('Test thumbnail'),
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () async => _compressVideo(),
//         tooltip: 'Increment',
//         child: Icon(Icons.add),
//       ),
//     );
//   }
// }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Consumer<GetStatusProvider>(builder: (context, file, child) {
      if (_isFetched == false) {
        file.getStatus('.mp4');
        Future.delayed(const Duration(microseconds: 1), () {
          _isFetched = true;
        });
      }
      return file.isWhatsappAvailable == false
          ? const Center(
              child: Text('Whatsapp not available'),
            )
          : file.getImages.isEmpty
              ? Center(
                  child: Text("No Videos available"),
                )
              : Container(
                  padding: const EdgeInsets.all(20),
                  child: GridView(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8),
                    children: List.generate(file.getVideos.length, (index) {
                      // print('---------------------');
                      // print(file.getVideos.length);
                      final data = file.getVideos[index];
                      return FutureBuilder<Uint8List>(
                          future: getThumbnail(data.path),
                          builder: (context, snapshot) {
                            print('----- in Video future builder');
                            print('-----    ----- ' + data.path);
                            // print(data);
                            print(snapshot.data);
                            print( snapshot.hasData);
                            print('-----    ----- ');
                            return
                              // snapshot.hasData
                              //   ?
                            GestureDetector(
                                    onTap: () {
                                      // Navigator.push(
                                      //     context,
                                      //     CupertinoPageRoute(
                                      //         builder: (_) => VideoView(
                                      //               videoPath: data.path,
                                      //             )));
                                      print('--+++--- in gesture' +
                                          snapshot.data.toString());
                                      print(
                                          '--+++ ' + snapshot.data.toString());
                                    },
                                    child: Center(
                                      child:
                                      // snapshot.hasData
                                      //     ? CircularProgressIndicator()
                                      //     : snapshot.data != null
                                      //     ?
                                      Image.memory(
                                        snapshot.data!,
                                        // width: 300,
                                        // height: 300,
                                        // fit: BoxFit.contain,
                                      )
                                    //       : Text('Failed to load image'),
                                    ),
                            );

                                  //   Container(
                                  //     decoration: BoxDecoration(
                                  //         image: DecorationImage(
                                  //           image: FileImage(File(snapshot.data
                                  //               .toString())), //FileImage(File(data.path)),
                                  //           fit: BoxFit.cover,
                                  //         ),
                                  //         color: const Color.fromARGB(
                                  //             255, 236, 235, 230),
                                  //         borderRadius:
                                  //             BorderRadius.circular(10)),
                                  //   ),
                                  // )

                                // : Center(
                                //     child: CircularProgressIndicator(),
                                //   );
                          });
                    }),
                  ),
                );
    }));
  }
}
