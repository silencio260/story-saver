import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:storysaver/Provider/PermissionProvider.dart';
import 'package:storysaver/Provider/getStatusProvider.dart';
import 'package:storysaver/Screens/GrantStatusFolderAccess/grant_status_access_page.dart';
import 'package:storysaver/Screens/TopNavPages/Widget/LoadStatusUtils.dart';
import 'package:storysaver/Screens/home_page.dart';
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

    final permission = Provider.of<PermissionProvider>(context, listen: false);

    AppStoragePermission().checkIfWeHaveStoragePermission().then((value) {
      setState(() {
        print('hasPermission - $value');
        hasPermission = value;
      });
    });

    AppStoragePermission().isWhatsAppStatusFolderPermissionAvailable().then((value) {

      print('isWhatsAppStatusFolderPermissionAvailable --> $value');

      permission.setIsWhatsAppStatusSafAvailable(value);
    });

    _getWhatsAppStatusFolderPermission();

    _loadStories();

  }

  void _loadStories() {

    final statuses = Provider.of<GetStatusProvider>(context, listen: false);

    // if(statuses.getVideos.isEmpty && statuses.getImages.isEmpty){
    //   // statuses.getAllStatus();
    // }

    statuses.getStatusWithSaf();
  }

  bool _isFetched = false;
  bool hasPermission = false;
  bool? isWhatsAppStatusFolderPermissionGranted = null;

  void _getWhatsAppStatusFolderPermission () async {

    final permission = Provider.of<PermissionProvider>(context, listen: false);
    final isGranted = await AppStoragePermission().isWhatsAppStatusFolderPermissionAvailable();

    print('_getWhatsAppStatusFolderPermission 1 permission ${permission.isWhatsAppStatusSafAvailable}'
        ' isGranted - ${isGranted}');

    if(isGranted == true)
      permission.setIsWhatsAppStatusSafAvailable(true);

    print('_getWhatsAppStatusFolderPermission permission ${permission.isWhatsAppStatusSafAvailable}'
        ' isGranted - ${isGranted}');
      
    //   isWhatsAppStatusFolderPermissionGranted = true;
    // else
    //   isWhatsAppStatusFolderPermissionGranted = false;
  }

  RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  void _onRefresh() async {

    Provider.of<GetStatusProvider>(context, listen: false).getStatusWithSaf();

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

  Widget RequestFolderPermission(BuildContext context) {

    final permission = Provider.of<PermissionProvider>(context, listen: false);

    if(permission.isWhatsAppStatusSafAvailable == false)
    // Trigger navigation after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (_) => WhatsAppStatusFolderPermission(),
        ),
      );
    });

    // Return fallback UI while the navigation is happening
    return Center(
      child: Text('Whatsapp not available/Permission not granted'),
    );
  }



  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Consumer<GetStatusProvider>(
        builder: (context, file, child) {
          final permission = Provider.of<PermissionProvider>(context, listen: false);

          // print('file_length ${file.getImages.length} ${file.getVideos.length}');

          print('_getWhatsAppStatusFolderPermission 3 permission.isWhatsAppStatusSafAvailable -> ${permission.isWhatsAppStatusSafAvailable}');

          return permission.hasStoragePermission != true ?
            GrantPermissionButton(
                context,
                onPermissionGranted: () {
                  // setState(() {
                  //   hasPermission = true;
                  // });
                  _loadStories();
                }
            )
              : permission.isWhatsAppStatusSafAvailable == false ?
            // : await AppStoragePermission().isWhatsAppStatusFolderPermissionAvailable() ?
            // : isWhatsAppStatusFolderPermissionGranted == false ?
            // : permission.hasStoragePermission == true ?
          // (permission.hasStoragePermission != true && (
            //   file.getImages.isEmpty &&
            //   file.getVideos.isEmpty)) ?
                RequestFolderPermission(context)

            : file.isLoading == true && file.getImages.isEmpty
              ? const Center(
                  child: Text('Loading Statuses...'),
                )
              : file.getImages.isEmpty
                ? LoadStatusUtils().TextWithStatusRefresh(
                  context: context,
                  text: "No images available"
                )
                  // ? Center(
                  //     child: Text("No images available"),
                  //   )
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

