import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:storysaver/Provider/getStatusProvider.dart';
import 'package:storysaver/Screens/BottomNavPages/Images/Image_view.dart';
import 'package:storysaver/Utils/SavedMediaManager.dart';
import 'package:storysaver/Widget/LocalCachedImage.dart';
import 'package:storysaver/Widget/MediaListItem.dart';

class ImageHomePage extends StatefulWidget {
  const ImageHomePage({Key? key}) : super(key: key);

  @override
  State<ImageHomePage> createState() => _ImageHomePageState();
}

class _ImageHomePageState extends State<ImageHomePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    // Provider.of<GetStatusProvider>(context, listen: false).getStatus('.jpg');
  }

  bool _isFetched = false;

  RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  void _onRefresh() async {
    Provider.of<GetStatusProvider>(context, listen: false).getStatus('.jpg');
    Provider.of<GetStatusProvider>(context, listen: false).getStatus('.mp4');

    _refreshController.refreshCompleted();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Consumer<GetStatusProvider>(
        builder: (context, file, child) {
          return file.isWhatsappAvailable == false
              ? const Center(
                  child: Text('Whatsapp not available'),
                )
              : file.getImages.isEmpty
                  ? Center(
                      child: Text("No images available"),
                    )
                  : Container(
                      padding: const EdgeInsets.all(5),
                      child: SmartRefresher(
                        enablePullDown: true,
                        // enablePullUp: true,
                        header: WaterDropHeader(
                          waterDropColor:
                              Colors.green, // Color of the water drop
                          refresh: CircularProgressIndicator(
                            // Custom loader during refresh
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.green), // Loader color
                          ),
                          complete:
                              Container(), // Customize or leave empty for the "complete" state
                        ),
                        controller: _refreshController,
                        onRefresh: _onRefresh,
                        child: GridView(
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent:
                                300, // Each item max width = 150
                            crossAxisSpacing: 5,
                            mainAxisSpacing: 8,
                            childAspectRatio: 0.95,
                          ),
                          children: List.generate(
                            file.getImages.length,
                            (index) {
                              final data = file.getImages[index];

                              print('---- ${data.path}');
                              // final mediaManager = SavedMediaManager();

                              // bool isSaved = mediaManager.isMediaSaved(data.path);

                              return MediaListItem(mediaPath: data.path);


                              // return FutureBuilder<bool>(
                              //     future: mediaManager.isMediaSaved(data.path),
                              //   builder: (context, snapshot) {
                              //
                              //       // bool isAlreadySaved = snapshot.data!;
                              //
                              //     return GestureDetector(
                              //         onTap: () {
                              //           Navigator.push(
                              //             context,
                              //             CupertinoPageRoute(
                              //               builder: (_) =>
                              //                   ImageView(imagePath: data.path),
                              //             ),
                              //           );
                              //
                              //           // print('--+++--- ' +
                              //           //     data.toString());
                              //           // print(
                              //           //     data);
                              //           // print('--+++--- ' +
                              //           //     data.path);
                              //           // print(
                              //           //     '--+++ ' + snapshot.data.toString());
                              //         },
                              //         child: Stack(
                              //           children: [
                              //             Positioned.fill(
                              //               child: LocalImageCache(
                              //                 data.path, // Cached image widget
                              //               ),
                              //             ),
                              //             Positioned(
                              //               // top: 10, // Adjust the position as needed
                              //               right: 10,
                              //               bottom: 10,
                              //               child: GestureDetector(
                              //                 onTap: () async {
                              //                   // Handle the click event here
                              //                   print("Icon tapped!");
                              //                   final result = await mediaManager.saveMedia(data.path);
                              //
                              //                   // isAlreadySaved = true;
                              //                   print('Aready Saved');
                              //
                              //                 },
                              //                 child: Container(
                              //                   // color: isAlreadySaved ? Colors.green : Colors.grey,
                              //                   width: 40,
                              //                   height: 40,
                              //                   child: Icon(
                              //                     Icons.download, // Replace with your desired icon
                              //                     color: const Color.fromARGB(255, 236, 235, 230),
                              //                     size: 20,
                              //                   ),
                              //                 ),
                              //
                              //               ),
                              //             ),
                              //           ],
                              //         ),
                              //
                              //
                              //       // Container(
                              //         //   decoration: BoxDecoration(
                              //         //       image: DecorationImage(
                              //         //         image: FileImage(File(data.path)),
                              //         //         fit: BoxFit.cover,
                              //         //       ),
                              //         //       color: const Color.fromARGB(
                              //         //           255, 255, 255, 255),
                              //         //       borderRadius: BorderRadius.circular(2)),
                              //         // ),
                              //         );
                              //   }
                              // );
                            },
                          ),
                        ),
                      ),
                    );
        },
      ),
    );
  }
}
