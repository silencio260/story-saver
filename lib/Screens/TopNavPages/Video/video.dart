import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:storysaver/Provider/PermissionProvider.dart';
import 'package:storysaver/Provider/getStatusProvider.dart';
import 'package:storysaver/Screens/GrantStatusFolderAccess/grant_business_status_access_page.dart';
import 'package:storysaver/Screens/GrantStatusFolderAccess/grant_status_access_page.dart';
import 'package:storysaver/Screens/TopNavPages/Widget/LoadStatusUtils.dart';
import 'package:storysaver/Utils/clearCache.dart';
import 'package:storysaver/Utils/getStoragePermission.dart';
import 'package:storysaver/Widget/GrantPermissionButton.dart';
import 'package:storysaver/Widget/MediaListItem.dart';
import 'package:storysaver/Widget/MyRouteObserver.dart';

class VideoHomePage extends StatefulWidget {
  const VideoHomePage({Key? key}) : super(key: key);

  @override
  State<VideoHomePage> createState() => _VideoHomePageState();
}

class _VideoHomePageState extends State<VideoHomePage>
    with AutomaticKeepAliveClientMixin, RouteAware {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    print('init in video ');
    clearOldCachedFiles();
    print('end of init video ');
  }

  bool _isFetched = false;

  String _counter = 'video';
  final String? title = 'vid';

  RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  Future<void> _onRefresh() async {
    // await Provider.of<GetStatusProvider>(context, listen: false).getAllStatusesWithSaf();

    // _refreshController.refreshCompleted();

    Provider.of<GetStatusProvider>(context, listen: false)
        .getAllStatusesWithSaf(onComplete: () {
      _refreshController.refreshCompleted();
    });
    // _refreshController.refreshCompleted();
  }

  final MyRouteObserver routeObserver = MyRouteObserver();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);

    print('Subscribing2');
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    print('unSubscribing');
    super.dispose();
  }

  Widget RequestWhatsappFolderPermission(BuildContext context) {
    final permission = Provider.of<PermissionProvider>(context, listen: false);

    void _goToSafPage() {
      if (permission.isWhatsAppStatusSafAvailable == false)
        // Trigger navigation after build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (_) => WhatsAppStatusFolderPermission(),
            ),
          );
        });
    }

    // Return fallback UI while the navigation is happening
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Grant Access To Android/Media Folder'),
          Text('or The Whatsapp .Statuses Folder.'),
          ElevatedButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all<Color>(Colors.green),
            ),
            onPressed: _goToSafPage,
            child:
                Text("Grant Permission", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget RequestBusinessWhatsappFolderPermission(BuildContext context) {
    final permission = Provider.of<PermissionProvider>(context, listen: false);

    void _goToSafPage() {
      if (permission.isBusinessWhatsAppStatusSafAvailable == false)
        // Trigger navigation after build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (_) => BusinessWhatsAppStatusFolderPermission(),
            ),
          );
        });
    }

    // Return fallback UI while the navigation is happening
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Grant Access To Business Whatsapp .Statuses Folder.'),
          ElevatedButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all<Color>(Colors.green),
            ),
            onPressed: _goToSafPage,
            child:
                Text("Grant Permission", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Consumer<GetStatusProvider>(builder: (context, file, child) {
        final permission =
            Provider.of<PermissionProvider>(context, listen: false);

        return permission.hasStoragePermission != true
            ? const Center(
                child: Text('No Storage Permission'),
              )
            : file.isBusinessMode == true &&
                    permission.isBusinessWhatsAppStatusSafAvailable == false
                ?
                // Center(child: Text("Is in business mode now ${file.isBusinessMode}"))
                RequestBusinessWhatsappFolderPermission(context)
                : file.isBusinessMode == true &&
                        file.isWhatsappAvailable == false
                    ? LoadStatusUtils().TextWithStatusRefresh(
                        context: context, text: "WB Whatsapp not available")
                    : file.isWhatsappAvailable == false
                        ? LoadStatusUtils().TextWithStatusRefresh(
                            context: context, text: "Whatsapp not available")
                        : file.isBusinessMode == false &&
                                permission.isWhatsAppStatusSafAvailable == false
                            ? RequestWhatsappFolderPermission(context)

                            // const Center(
                            //       child: Text('Whatsapp not available'),
                            //     )
                            : file.isLoading == true && file.getVideos.isEmpty
                                ? const Center(
                                    child: Text('Loading Statuses...'),
                                  )
                                : file.getVideos.isEmpty
                                    ? LoadStatusUtils().TextWithStatusRefresh(
                                        context: context,
                                        text: "No Videos Found")
                                    //TextWithStatusRefresh("No Videos available")
                                    // ? Center(
                                    //     child: Text("No Videos available"),

                                    //   )
                                    : Container(
                                        padding: const EdgeInsets.all(5),
                                        child: SmartRefresher(
                                          // enablePullDown: true,
                                          // enablePullUp: true,
                                          // header: WaterDropHeader(
                                          //   waterDropColor:
                                          //   Colors.green, // Color of the water drop
                                          //   refresh: CircularProgressIndicator(
                                          //     // Custom loader during refresh
                                          //     valueColor: AlwaysStoppedAnimation<Color>(
                                          //         Colors.green), // Loader color
                                          //   ),
                                          //   complete:
                                          //   Container(), // Customize or leave empty for the "complete" state
                                          // ),
                                          physics: ClampingScrollPhysics(),
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
                                              file.getVideos.length,
                                              (index) {
                                                // print('---------------------');
                                                // print(file.getVideos.length);
                                                final data =
                                                    file.getVideos[index];
                                                return FutureBuilder<String>(
                                                    future: file
                                                        .generateThumbnailFromListAllVideosForFutureBuilder(
                                                            data.path),
                                                    builder:
                                                        (context, snapshot) {
                                                      print(
                                                          'video File path - snapshot.data.toString() -> ${snapshot.data.toString()}'
                                                          ' - videoFilePath -> ${data.path}');

                                                      return snapshot.hasData
                                                          ? MediaListItem(
                                                              currentIndex:
                                                                  index,
                                                              mediaPath: snapshot
                                                                  .data
                                                                  .toString(),
                                                              isVideo: true,
                                                              videoFilePath:
                                                                  data.path)
                                                          : Center(
                                                              child: Column(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .center,
                                                                children: [
                                                                  Icon(
                                                                      Icons
                                                                          .broken_image,
                                                                      color: Colors
                                                                          .grey),
                                                                  // Text("Thumbnail not available", style: TextStyle(color: Colors.grey),)
                                                                ],
                                                              ),
                                                            );
                                                    });
                                              },
                                            ),
                                          ),
                                        ),
                                      );
      }),
    );
  }
}
