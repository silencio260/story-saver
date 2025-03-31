import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:storysaver/Provider/getStatusProvider.dart';
import 'package:storysaver/Utils/getStoragePermission.dart';
import 'package:storysaver/Widget/GrantPermissionButton.dart';
import 'package:storysaver/Widget/MediaListItem.dart';
import 'package:storysaver/Widget/MyRouteObserver.dart';

class ImageHomePage extends StatefulWidget {
  const ImageHomePage({Key? key}) : super(key: key);

  @override
  State<ImageHomePage> createState() => _ImageHomePageState();
}

class _ImageHomePageState extends State<ImageHomePage>
    with AutomaticKeepAliveClientMixin, RouteAware {
  @override
  bool get wantKeepAlive => true;

  // final GlobalKey<MediaListItem> mediaListItemKey = GlobalKey();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkIfWeHaveStoragePermission().then((value) {
      setState(() {
        print('hasPermission - $value');
        hasPermission = value;
      });
    });

  }

  bool _isFetched = false;
  bool hasPermission = false;


  RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  void _onRefresh() async {

    Provider.of<GetStatusProvider>(context, listen: false).getAllStatus();

    _refreshController.refreshCompleted();
  }


  final MyRouteObserver routeObserver = MyRouteObserver();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);

  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    print('unSubscribing');
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Consumer<GetStatusProvider>(
        builder: (context, file, child) {
          return hasPermission != true ?
            GrantPermissionButton(
                context,
                onPermissionGranted: () {
                  setState(() {
                    hasPermission = true;
                  });
                }
            )
            :
            file.isWhatsappAvailable == false
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

                              return MediaListItem(
                                // key: mediaListItemKey,
                                // key: ValueKey(index),
                                mediaPath: data.path, currentIndex: index,
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

