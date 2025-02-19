import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:storysaver/Provider/getStatusProvider.dart';
import 'package:storysaver/Screens/BottomNavPages/Images/Image_view.dart';
import 'package:storysaver/Widget/LocalCachedImage.dart';

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

  void _onRefresh() async{

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
                        waterDropColor: Colors.green, // Color of the water drop
                        refresh: CircularProgressIndicator( // Custom loader during refresh
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.green), // Loader color
                        ),
                        complete: Container(), // Customize or leave empty for the "complete" state
                      ),
                      controller: _refreshController,
                      onRefresh: _onRefresh,
                      child: GridView(
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 300, // Each item max width = 150
                          crossAxisSpacing: 5,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.95,
                        ),
                        children: List.generate(
                          file.getImages.length,
                          (index) {
                            final data = file.getImages[index];

                            print('---- ${data.path}');
                            //
                            // File tempFile = File(data.path);
                            //
                            // // Check if the file exists
                            // if (!tempFile.existsSync()) {
                            //
                            //   // file.removeImageAtIndex(index);
                            //
                            //   return Center(
                            //     child: Column(
                            //       mainAxisAlignment: MainAxisAlignment.center,
                            //       children: [
                            //         Icon(Icons.broken_image,
                            //             color: Colors.grey),
                            //         // Text("Image not available", style: TextStyle(color: Colors.grey),)
                            //       ],
                            //     ),
                            //   );
                            // }

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                    builder: (_) =>
                                        ImageView(imagePath: data.path),
                                  ),
                                );

                                // print('--+++--- ' +
                                //     data.toString());
                                // print(
                                //     data);
                                // print('--+++--- ' +
                                //     data.path);
                                // print(
                                //     '--+++ ' + snapshot.data.toString());
                              },
                              child: LocalImageCache(data.path)
                              
                              // Container(
                              //   decoration: BoxDecoration(
                              //       image: DecorationImage(
                              //         image: FileImage(File(data.path)),
                              //         fit: BoxFit.cover,
                              //       ),
                              //       color: const Color.fromARGB(
                              //           255, 255, 255, 255),
                              //       borderRadius: BorderRadius.circular(2)),
                              // ),
                            );
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
