import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:storysaver/Provider/getStatusProvider.dart';
import 'package:storysaver/Provider/savedMediaProvider.dart';
import 'package:storysaver/Screens/BottomNavPages/Images/Image_view.dart';
import 'package:storysaver/Screens/BottomNavPages/Video/video_view.dart';
import 'package:storysaver/Utils/clearCache.dart';
import 'package:storysaver/Utils/getThumbnails.dart';
import 'package:storysaver/Widget/MediaListItem.dart';

// import 'package:file_selector/file_selector.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:video_compress/video_compress.dart';
// import 'package:video_compress_example/video_thumbnail.dart';

class VideoHomePage extends StatefulWidget {
  const VideoHomePage({Key? key}) : super(key: key);

  @override
  State<VideoHomePage> createState() => _VideoHomePageState();
}

class _VideoHomePageState extends State<VideoHomePage>  with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    // Provider.of<GetStatusProvider>(context, listen: false).getStatus('.mp4');
    // print("Provider_2 ${Provider.of<GetSavedMediaProvider>(context, listen: false).loadVideos()}");

    print('init in video ');
    clearOldCachedFiles();
    print('end of init video ');
  }

  bool _isFetched = false;

  String _counter = 'video';
  final String? title = 'vid';

  RefreshController _refreshController =
  RefreshController(initialRefresh: false);

  void _onRefresh() async{

    Provider.of<GetStatusProvider>(context, listen: false).getStatus('.jpg');
    Provider.of<GetStatusProvider>(context, listen: false).getStatus('.mp4');

    _refreshController.refreshCompleted();
  }

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
    super.build(context);
    return Scaffold(
        body: Consumer<GetStatusProvider>(builder: (context, file, child) {
      // if (_isFetched == false) {
      //   file.getStatus('.mp4');
      //   Future.delayed(const Duration(microseconds: 1), () {
      //     _isFetched = true;
      //   });
      // }

          // final videoFiles = file.getExperimentalFiles;

      return file.isWhatsappAvailable == false
          ? const Center(
              child: Text('Whatsapp not available'),
            )
          : file.getImages.isEmpty
              ? Center(
                  child: Text("No Videos available"),
                )
              :   Container(
                  padding: const EdgeInsets.all(5),
                  child: SmartRefresher(
          enablePullDown: true,
          // enablePullUp: true,
          header: WaterDropHeader(
          waterDropColor: Colors.green, // Color of the water drop
          refresh: CircularProgressIndicator( // Custom loader during refresh
          valueColor: AlwaysStoppedAnimation<Color>(Colors.green), // Loader color
          ),
          complete: Container(), // Customize or leave empty for the "complete" state
          ),
          controller: _refreshController,
          onRefresh: _onRefresh,
          child:
                  GridView(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 300, // Each item max width = 150
                          crossAxisSpacing: 5,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.95,
                        ),
                    children: List.generate(file.getVideos.length, (index) {
                      // print('---------------------');
                      // print(file.getVideos.length);
                      final data = file.getVideos[index];
                      return FutureBuilder<String>(
                          future: file.generateThumbnailFromListAllVideosForFutureBuilder(data.path),
                          builder: (context, snapshot) {

                            print(snapshot.data.toString());

                            return
                              snapshot.hasData
                                ?
                             MediaListItem(mediaPath: snapshot.data.toString(), isVideo: true, videoFilePath: data.path)

                            // GestureDetector(
                            //         onTap: () {
                            //           Navigator.push(
                            //               context,
                            //               CupertinoPageRoute(
                            //                   builder: (_) => VideoView(
                            //                         videoPath: data.path,
                            //                       ),),);
                            //
                            //           // print('--+++--- in gesture' +
                            //           //     snapshot.data.toString());
                            //           // print(
                            //           //     '--+++ ' + snapshot.data.toString());
                            //           // print(snapshot.data!);
                            //
                            //           // print("Provider_2 ${Provider.of<GetSavedMediaProvider>(context, listen: false).getMediaFile}");
                            //
                            //         },
                            //         child: Container(
                            //           // height: MediaQuery.of(context).size.height * 0.5,
                            //           decoration: BoxDecoration(
                            //               image: DecorationImage(
                            //                 image: FileImage(File(snapshot.data.toString())),
                            //                 fit: BoxFit.cover,
                            //               ),
                            //               color: const Color.fromARGB(255, 236, 235, 230),
                            //               borderRadius: BorderRadius.circular(2)),
                            //
                            //           child: Stack(
                            //             children: [
                            //               // Your image is already inside the container with the decoration
                            //
                            //               // Positioned widget for the video icon
                            //               Positioned(
                            //                 top: 10, // Adjust to your preference
                            //                 right: 10, // Adjust to your preference
                            //                 child: Icon(
                            //                   Icons.videocam_sharp, // You can replace it with any other video icon
                            //                   color: Colors.white, // Icon color
                            //                   size: 20, // Icon size
                            //                 ),
                            //               ),
                            //             ],
                            //           ),
                            //               // height: 500,
                            //         ),
                            //         // Image.memory(
                            //         //   snapshot.data!,
                            //         //
                            //         //   fit: BoxFit.cover,
                            //         // )
                            //         // new Center(
                            //         //   child:
                            //   // new Container(
                            //   //             decoration: new BoxDecoration(
                            //   //
                            //   //               color: Colors.purple,
                            //   //             ),
                            //   //             child: new  Image.memory(
                            //   //               snapshot.data!,
                            //   //               width: 700,
                            //   //               height: 1300,
                            //   //               fit: BoxFit.cover,
                            //   //             )
                            //   //         // ),
                            //   //       )
                            //
                            //   // Container(
                            //         //       decoration: BoxDecoration(
                            //         //           image: DecorationImage(
                            //         //             image: FileImage(File(snapshot.data
                            //         //                 .toString())), //FileImage(File(data.path)),
                            //         //             fit: BoxFit.cover,
                            //         //           ),
                            //         //           color: const Color.fromARGB(
                            //         //               255, 236, 235, 230),
                            //         //           borderRadius:
                            //         //               BorderRadius.circular(10)),
                            //         //     ),
                            //         //   )
                            //
                            //         //   Container(
                            //         //     decoration: BoxDecoration(
                            //         //         image: DecorationImage(
                            //         //           image: FileImage(File(snapshot.data
                            //         //               .toString())), //FileImage(File(data.path)),
                            //         //           fit: BoxFit.cover,
                            //         //         ),
                            //         //         color: const Color.fromARGB(
                            //         //             255, 236, 235, 230),
                            //         //         borderRadius:
                            //         //             BorderRadius.circular(10)),
                            //         //   ),
                            //         // )
                            //
                            //         // Center(
                            //         //   child:
                            //         //   // snapshot.hasData
                            //         //   //     ? CircularProgressIndicator()
                            //         //   //     : snapshot.data != null
                            //         //   //     ?
                            //         //   Image.memory(
                            //         //     snapshot.data!,
                            //         //     // width: 300,
                            //         //     // height: 300,
                            //         //     fit: BoxFit.contain,
                            //         //   )
                            //         // //       : Text('Failed to load image'),
                            //         // ),
                            // )
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image, color: Colors.grey),
                                    // Text("Thumbnail not available", style: TextStyle(color: Colors.grey),)
                                  ],),
                              );
                          });
                    },),
                  ),
                  ),
                );
    }));
  }
}
