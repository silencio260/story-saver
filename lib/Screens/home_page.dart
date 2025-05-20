import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:share_plus/share_plus.dart';
import 'package:storysaver/Constants/CustomColors.dart';
import 'package:storysaver/Constants/constant.dart';
import 'package:storysaver/Monetization/Ads/admob_helper.dart';
import 'package:storysaver/Provider/getStatusProvider.dart';
import 'package:storysaver/Screens/TopNavPages/SavedMedia/saved_media_list.dart';
import 'package:storysaver/Screens/TopNavPages/Images/image.dart';
import 'package:storysaver/Screens/TopNavPages/Video/video.dart';
import 'package:double_tap_to_exit/double_tap_to_exit.dart';
import 'package:storysaver/Widget/HelpModal.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {

  late TabController controller;
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;

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

    // print('init myHomePage');

    // Provider.of<GetStatusProvider>(context, listen: false).getAllStatus();
    _checkIsBusinessMode();


    controller = TabController(length: 3, vsync: this);

    AdmobWrapper().addListener(_rebuild);

    AdmobWrapper().loadBannerAd();
    AdmobWrapper().loadInterstitialAd();

    // BannerAd(
    //   adUnitId: AdHelper.bannerAdUnitId,
    //   request: AdRequest(),
    //   size: AdSize.banner,
    //   listener: BannerAdListener(
    //     onAdLoaded: (ad) {
    //       setState(() {
    //         _bannerAd = ad as BannerAd;
    //       });
    //     },
    //     onAdFailedToLoad: (ad, err){
    //       print('Failed to load a banner ad: ${err.message}');
    //       ad.dispose();
    //     }
    //   )
    // )..load();
    //
    // InterstitialAd.load(
    //     adUnitId: AdHelper.InterstitialAdUnitId,
    //     request: AdRequest(),
    //     adLoadCallback: InterstitialAdLoadCallback(
    //         onAdLoaded: (ad) {
    //           ad.fullScreenContentCallback = FullScreenContentCallback(
    //             onAdDismissedFullScreenContent: (ad){}
    //           );
    //           setState(() {
    //             _interstitialAd = ad;
    //           });
    //         },
    //         onAdFailedToLoad: (err){
    //           print('Failed to load a InterstitialAd  ad: ${err.message}');
    //           // ad.dispose();
    //         }
    //     )
    // );
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    // TODO: implement dispose
    controller.dispose();

    // _bannerAd!.dispose();
    // _interstitialAd!.dispose();
    AdmobWrapper().removeListener(_rebuild);
    AdmobWrapper.disposeAds();

    super.dispose();
  }

  void _showInterstitialAd() {
    if(_interstitialAd != null){
      _interstitialAd!.show();
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad){
          ad.dispose();

          ////////////
          InterstitialAd.load(
              adUnitId: AdHelper.InterstitialAdUnitId,
              request: AdRequest(),

              adLoadCallback: InterstitialAdLoadCallback(
                  onAdLoaded: (ad) {
                    ad.fullScreenContentCallback = FullScreenContentCallback(
                      onAdFailedToShowFullScreenContent: (ad, err){
                        ad.dispose();

                      },
                        onAdDismissedFullScreenContent: (ad){}
                    );
                    setState(() {
                      _interstitialAd = ad;

                    });
                  },
                  onAdFailedToLoad: (err){
                    print('Failed to load a InterstitialAd  ad: ${err.message}');
                    // ad.dispose();
                  }
              ),

          );

        }
      );

    }
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
            onPressed: () => SystemChannels.platform.invokeMethod('SystemNavigator.pop'), // Exit app
            child: Text("Yes"),
          ),
        ],
      ),
    );
  }

  RefreshController _refreshController = RefreshController(initialRefresh: false);

  void _onRefresh() async{
    // monitor network fetch
    await Future.delayed(Duration(milliseconds: 1000));
    // if failed,use refreshFailed()
    _refreshController.refreshCompleted();
  }

  void _onLoading() async{
    // monitor network fetch
    await Future.delayed(Duration(milliseconds: 1000));
    _refreshController.loadComplete();
  }

  void _shareAppLink(BuildContext context) {
    Share.share('Shared From WhatsApp Status Saver App @ ${AppConstants().GOOGLE_PLAY_STORE_LINK}')
        .then((value) {
      // ScaffoldMessenger.of(context)
      //     .showSnackBar(const SnackBar(content: Text("Image Sent")));
    });
  }

  void _launchPlayStoreLink() async {
    final uri = Uri.parse(AppConstants().GOOGLE_PLAY_STORE_LINK);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch ${uri}';
    }
  }

  void _switchToBusinessMode() {
    final provider = Provider.of<GetStatusProvider>(context, listen: false);

    provider.setIsBusinessMode(!provider.isBusinessMode);
    // Provider.of<GetStatusProvider>(context, listen: false).setIsBusinessMode();

    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext ctx) => const HomePage(),
      ),
    );
  }

  Future<void> _checkIsBusinessMode() async {
    await Provider.of<GetStatusProvider>(context, listen: false).checkIsBusinessMode();

    // print("_checkIsBusinessMode ${Provider.of<GetStatusProvider>(context, listen: false).isBusinessMode}");
  }


  @override
  Widget build(BuildContext context) {
    final _isBusinessMode = Provider.of<GetStatusProvider>(context, listen: true).isBusinessMode;
    // print(object)

    // AdmobWrapper().showInterstitialAd();

    return  DoubleTapToExit(
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
          appBar: AppBar(
            title:
            Text(
                _isBusinessMode == false ?
                "Story Saver" :
                "WB Story Saver"
            ),
            automaticallyImplyLeading: false,
            bottom: TabBar(
              controller: controller,
              indicatorColor: Colors.white,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs:
              [
                Tab(child: Text('Image', style: TextStyle(fontSize: 14, color: Colors.white),),),
                Tab(child: Text('Video', style: TextStyle(fontSize: 14, color: Colors.white),),),
                Tab(child: Text('Gallery', style: TextStyle(fontSize: 14, color: Colors.white),),),
              ]
            ),
            actions: [
              IconButton(onPressed: () {
                _switchToBusinessMode();
              }, icon: _isBusinessMode == false ?
                      businessWhatsAppsSvgIcon :
                      whatsAppsSvgIcon,
                  color: Colors.white,
              ),
              IconButton(onPressed: () {
                // _switchToBusinessMode();
                HelpModal().showHelpDialog(context);
              }, icon: Icon(Icons.help_outline_sharp, color: Colors.white)),
              IconButton(onPressed: () {
                _shareAppLink(context);
              }, icon: Icon(Icons.share, color: Colors.white)),
              IconButton(onPressed: () {
                _launchPlayStoreLink();
              }, icon: Icon(Icons.star_border_purple500_sharp, color: Colors.white)),
            ],
            backgroundColor: const Color(CustomColors.AppBarColor),
            foregroundColor: Colors.white,
          ),
          body: Stack(
            children: [
              TabBarView(controller: controller, children: pages),

              // if (_bannerAd != null)
              //   Align(
              //     alignment: Alignment.bottomCenter,
              //     child: Container(
              //       // padding: EdgeInsets.only(top: 50),
              //       width: _bannerAd!.size.width.toDouble(),
              //       height: _bannerAd!.size.height.toDouble(),
              //       // child: AdWidget(ad: _bannerAd!),
              //     ),
              //   ),
              // if (_interstitialAd != null)
              //   _interstitialAd.show();
            ],
          ),
          bottomNavigationBar: DisplayBannerAdWidget()//AdmobWrapper().DisplayBannerAdWidget(),
          // _bannerAd != null ?
          // SizedBox(
          //   // padding: EdgeInsets.only(top: 50),
          //   width: _bannerAd!.size.width.toDouble(),
          //   height: _bannerAd!.size.height.toDouble(),
          //   child: _bannerAd != null? AdWidget(ad: _bannerAd!) : Container(),
          // ) : null

          // body: TabBarView(controller: controller, children: pages),

        ),
      ),
    );
  }
}
