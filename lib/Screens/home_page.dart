import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:share_plus/share_plus.dart';
import 'package:storysaver/Constants/CustomColors.dart';
import 'package:storysaver/Constants/constant.dart';
import 'package:storysaver/Provider/getStatusProvider.dart';
import 'package:storysaver/Screens/TopNavPages/SavedMedia/saved_media_list.dart';
import 'package:storysaver/Screens/TopNavPages/Images/image.dart';
import 'package:storysaver/Screens/TopNavPages/Video/video.dart';
import 'package:double_tap_to_exit/double_tap_to_exit.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {

  late TabController controller;

  void initState() {
    // TODO: implement initState
    super.initState();

    // print('init myHomePage');

    Provider.of<GetStatusProvider>(context, listen: false).getAllStatus();


    controller = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    controller.dispose();

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




  @override
  Widget build(BuildContext context) {  //WillPopScope
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
            title: Text("Story Saver"),
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
              IconButton(onPressed: () {}, icon: Icon(Icons.help_outline_sharp, color: Colors.white)),
              IconButton(onPressed: () {
                _shareAppLink(context);
              }, icon: Icon(Icons.share, color: Colors.white)),
              IconButton(onPressed: () {}, icon: Icon(Icons.more_vert, color: Colors.white)),
            ],
            backgroundColor: const Color(CustomColors.AppBarColor),
            foregroundColor: Colors.white,
          ),
          body: TabBarView(controller: controller, children: pages),

        ),
      ),
    );
  }
}
