import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:storysaver/Constants/CustomColors.dart';
import 'package:storysaver/Monetization/Ads/Admob/Widget/DisplayBannerAds.dart';
import 'package:storysaver/Monetization/Ads/Admob/adConfig.dart';
import 'package:storysaver/Monetization/Ads/Admob/admob_wrapper.dart';
import 'package:storysaver/Monetization/IAP/RevenueCat/Services/revenueCatUtil.dart';
import 'package:storysaver/Monetization/SubscriptionManager.dart';
import 'package:storysaver/Provider/getStatusProvider.dart';
import 'package:storysaver/Screens/Settings/settings_page.dart';
import 'package:storysaver/Screens/TopNavPages/SavedMedia/saved_media_list.dart';
import 'package:storysaver/Screens/TopNavPages/Images/image.dart';
import 'package:storysaver/Screens/TopNavPages/Video/video.dart';
import 'package:double_tap_to_exit/double_tap_to_exit.dart';
import 'package:storysaver/Utils/checkBusinessMode.dart';
import 'package:storysaver/Services/AppRatingService.dart';
import 'package:storysaver/Services/BatchDownloadService.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController controller;
  final _controller = SidebarXController(selectedIndex: 0, extended: true);
  final _key = GlobalKey<ScaffoldState>();

  final Widget whatsAppsSvgIcon = SvgPicture.asset(
    "assets/icons/whatsapp.svg",
    colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
    // semanticsLabel: 'Red dash paths',
  );

  final Widget businessWhatsAppsSvgIcon = SvgPicture.asset(
    "assets/icons/whatsapp-business.svg",
    colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
    // semanticsLabel: 'Red dash paths',
  );

  void initState() {
    // TODO: implement initState
    super.initState();

    checkIsBusinessMode(context);

    controller = TabController(length: 3, vsync: this);

    AdmobWrapper().addListener(_rebuild);

    // AdmobWrapper().loadBannerAd();
    AdmobWrapper().loadInterstitialAd();

    print(
      "AdConfig time_before_first_insta_ad -> ${AdConfig.time_before_first_insta_ad},"
      "min_insta_ad_interval -> ${AdConfig.min_insta_ad_interval},"
      "min_insta_ad_interval -> ${AdConfig.min_insta_ad_interval}",
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdvancedAppRatingService.showReviewDialogIfEligible(context);
    });
  }

  // Future<void> _enableSessionReplay() async {
  //   await PostHogWrapper.startSessionReplay(record: true);
  // }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    // TODO: implement dispose
    controller.dispose();

    AdmobWrapper().removeListener(_rebuild);
    AdmobWrapper.disposeAds();

    super.dispose();
  }

  List<Widget> pages = const [
    ImageHomePage(),
    VideoHomePage(),
    SavedMediaPage()
  ];

  Future<bool?> _showExitDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Exit App"),
        content: Text("Are you sure you want to leave?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // Stay in app
            child: Text("No"),
          ),
          TextButton(
            onPressed: () => SystemChannels.platform
                .invokeMethod('SystemNavigator.pop'), // Exit app
            child: Text("Yes"),
          ),
        ],
      ),
    );
  }

  RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  void _onRefresh() async {
    // monitor network fetch
    await Future.delayed(Duration(milliseconds: 1000));
    // if failed,use refreshFailed()
    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    // monitor network fetch
    await Future.delayed(Duration(milliseconds: 1000));
    _refreshController.loadComplete();
  }

  @override
  Widget build(BuildContext context) {
    final _isBusinessMode =
        Provider.of<GetStatusProvider>(context, listen: true).isBusinessMode;
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    AdmobWrapper().showInterstitialAd();
    // print(
    //     'RevenueCatService.isSubscriptionActive(): ${RevenueCatService.isSubscriptionActive()}');

    return DoubleTapToExit(
      child: PopScope(
        canPop: false, // Prevents app from closing automatically
        onPopInvoked: (didPop) async {
          if (didPop) return;

          bool exitApp = await _showExitDialog(context) ?? false;
          if (exitApp) {
            SystemChannels.platform.invokeMethod('SystemNavigator.pop');
          }
        },

        child: Scaffold(
            key: _key,
            // drawer: AppSideBar(controller: _controller),
            appBar: AppBar(
              // leading: IconButton(
              //   onPressed: () {
              //     _key.currentState?.openDrawer();
              //     // print("_key.currentState?.isDrawerOpen ${_key.currentState?.isDrawerOpen}");
              //   },
              //   icon: const Icon(Icons.menu),
              // ),
              title: Text(
                  _isBusinessMode == false ? "Story Saver" : "WB Story Saver"),
              automaticallyImplyLeading: false,
              bottom: TabBar(
                  controller: controller,
                  indicatorColor: Colors.white,
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: [
                    Tab(
                      child: Text(
                        'Image',
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ),
                    Tab(
                      child: Text(
                        'Video',
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ),
                    Tab(
                      child: Text(
                        'Gallery',
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ),
                  ]),
              actions: [
                IconButton(
                  onPressed: () {
                    switchToBusinessMode(context);
                  },
                  icon: _isBusinessMode == false
                      ? businessWhatsAppsSvgIcon
                      : whatsAppsSvgIcon,
                  color: Colors.white,
                ),
                IconButton(
                  onPressed: () {
                    // _switchToBusinessMode();
                    // HelpModal().showHelpDialog(context);
                    // Navigator.of(context).push<void>(
                    //   MaterialPageRoute<void>(builder: (_) => SettingsPage()),
                    // );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsPage(),
                      ),
                    );
                  },
                  icon: Icon(Icons.settings, color: Colors.white),
                ),
                !SubscriptionManager().isPremium
                    ? IconButton(
                        onPressed: () {
                          RevenueCatService()
                              .PresentRevenueCatPayWallIfNeeded();
                        },
                        icon: Icon(Icons.diamond_outlined, color: Colors.white),
                      )
                    : IconButton(
                        onPressed: () {
                          final statusProvider = Provider.of<GetStatusProvider>(
                              context,
                              listen: false);
                          List<String> imagePaths = statusProvider.getImages
                              .map((e) => e.path)
                              .toList();
                          List<String> videoPaths = statusProvider.getVideos
                              .map((e) => e.path)
                              .toList();

                          BatchDownloadService.downloadAll(
                              context, imagePaths, videoPaths);
                        },
                        icon: Icon(Icons.download, color: Colors.white),
                        tooltip: "Download All",
                      ),
              ],
              backgroundColor: const Color(CustomColors.AppBarColor),
              foregroundColor: Colors.white,
            ),
            body: Stack(
              children: [
                TabBarView(controller: controller, children: pages),
              ],
            ),
            bottomNavigationBar:
                DisplayBannerAdWidget() //AdmobWrapper().DisplayBannerAdWidget(),

            ),
      ),
    );
  }
}
