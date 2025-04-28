import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:storysaver/Provider/PermissionProvider.dart';
import 'package:storysaver/Provider/getStatusProvider.dart';
import 'package:storysaver/Screens/GrantStatusFolderAccess/grant_business_status_access_page.dart';
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

    // final permission = Provider.of<PermissionProvider>(context, listen: false);

    // AppStoragePermission().checkIfWeHaveStoragePermission().then((value) {
    //   setState(() {
    //     print('hasPermission - $value');
    //     hasPermission = value;
    //   });
    // });
    //
    // AppStoragePermission().isWhatsAppStatusFolderPermissionAvailable().then((value) {
    //
    //   print('isWhatsAppStatusFolderPermissionAvailable --> $value');
    //
    //   permission.setIsWhatsAppStatusSafAvailable(value);
    // });
    //
    // _getWhatsAppStatusFolderPermission();

    getStatusesFoldersPermissions();

    _loadStories();

  }

  void getStatusesFoldersPermissions () async {

    final statuses = Provider.of<GetStatusProvider>(context, listen: false);
    final permission = Provider.of<PermissionProvider>(context, listen: false);

    AppStoragePermission().checkIfWeHaveStoragePermission().then((value) {
      setState(() {
        print('hasPermission - $value');
        hasPermission = value;
      });
    });

    await statuses.checkIsBusinessMode();

    if(statuses.isBusinessMode == false){

      AppStoragePermission().isWhatsAppStatusFolderPermissionAvailable().then((value) {

        print('isWhatsAppStatusFolderPermissionAvailable --> $value');

        permission.setIsWhatsAppStatusSafAvailable(value);
      });

      _getWhatsAppStatusFolderPermission();
    } else {

      AppStoragePermission().isWhatsAppStatusFolderPermissionAvailable(isBusinessMode: true).then((value) {

        print('isWhatsAppStatusFolderPermissionAvailable --> $value');

        permission.setIsBusinessWhatsAppStatusSafAvailable(value);
      });

      _getBusinessWhatsAppStatusFolderPermission();
    }
  }


  void _loadStories() {

    final statuses = Provider.of<GetStatusProvider>(context, listen: false);

    // if(statuses.getVideos.isEmpty && statuses.getImages.isEmpty){
    //   // statuses.getAllStatus();
    // }

    statuses.getAllStatusesWithSaf();
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

  void _getBusinessWhatsAppStatusFolderPermission () async {

    final permission = Provider.of<PermissionProvider>(context, listen: false);
    final isGranted = await AppStoragePermission().isWhatsAppStatusFolderPermissionAvailable(isBusinessMode: true);

    print('_getWhatsAppStatusFolderPermission 1 permission ${permission.isBusinessWhatsAppStatusSafAvailable}'
        ' isGranted - ${isGranted}');

    if(isGranted == true)
      permission.setIsBusinessWhatsAppStatusSafAvailable(true);

    print('_getWhatsAppStatusFolderPermission permission ${permission.isBusinessWhatsAppStatusSafAvailable}'
        ' isGranted - ${isGranted}');
  }

  RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  void _onRefresh() async {

    Provider.of<GetStatusProvider>(context, listen: false).getAllStatusesWithSaf();

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

  Widget RequestWhatsappFolderPermission(BuildContext context) {

    final permission = Provider.of<PermissionProvider>(context, listen: false);

    void _goToSafPage () {
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
    }

    // Return fallback UI while the navigation is happening
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Grant Access To Business Whatsapp .Statuses Folder.'),
          ElevatedButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(Colors.green),
            ),
            onPressed: _goToSafPage,
            child: Text("Grant Permission", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget RequestBusinessWhatsappFolderPermission(BuildContext context) {

    final permission = Provider.of<PermissionProvider>(context, listen: false);

    void _goToSafPage () {
      if(permission.isBusinessWhatsAppStatusSafAvailable == false)
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
              backgroundColor: MaterialStateProperty.all<Color>(Colors.green),
            ),
            onPressed: _goToSafPage,
            child: Text("Grant Permission", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
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
            :
          file.isBusinessMode == true &&
              permission.isBusinessWhatsAppStatusSafAvailable == false ?
                // Center(child: Text("Is in business mode now ${file.isBusinessMode}"))
                RequestBusinessWhatsappFolderPermission(context)


            : permission.isWhatsAppStatusSafAvailable == false ?
                RequestWhatsappFolderPermission(context)

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

