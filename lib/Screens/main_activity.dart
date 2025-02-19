import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:storysaver/Constants/CustomColors.dart';
import 'package:storysaver/Provider/bottom_nav_provider.dart';
import 'package:storysaver/Provider/getStatusProvider.dart';
import 'package:storysaver/Provider/savedMediaProvider.dart';
import 'package:storysaver/Screens/BottomNavPages/Experiments/ExperimentWithPhotoManager.dart';
import 'package:storysaver/Screens/BottomNavPages/Experiments/ThumbnailExperiment.dart';
import 'package:storysaver/Screens/BottomNavPages/Images/image.dart';
import 'package:storysaver/Screens/BottomNavPages/Video/video.dart';
import 'package:double_tap_to_exit/double_tap_to_exit.dart';
import 'package:storysaver/Services/AppRatingService.dart';

class MainActivity extends StatefulWidget {
  const MainActivity({Key? key}) : super(key: key);

  @override
  State<MainActivity> createState() => _MainActivityState();
}

class _MainActivityState extends State<MainActivity> with SingleTickerProviderStateMixin {

  late TabController controller;

  void initState() {
    // TODO: implement initState
    super.initState();

    // print('init myMainActivity');

    Provider.of<GetStatusProvider>(context, listen: false).getAllStatus();

    // Provider.of<GetSavedMediaProvider>(context, listen: false).loadVideos();



    controller = TabController(length: 3, vsync: this);
    // controller.addListener(() {
    //   setState(() {
    //
    //   });
    // });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    controller.dispose();

    super.dispose();
  }

  List<Widget> pages = const [ImageHomePage(), VideoHomePage(), MediaStoreVideos()];

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
    // if failed,use loadFailed(),if no data return,use LoadNodata()
    // items.add((items.length+1).toString());
    // if(mounted)
    //   setState(() {
    //
    //   });
    _refreshController.loadComplete();
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
          // floatingActionButton: FloatingActionButton(onPressed: (){
          //   print('in app review click');
          //   AppRatingService.init();
          // }),
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
              IconButton(onPressed: () {}, icon: Icon(Icons.share, color: Colors.white)),
              IconButton(onPressed: () {}, icon: Icon(Icons.more_vert, color: Colors.white)),
            ],
            backgroundColor: const Color(CustomColors.AppBarColor),
            foregroundColor: Colors.white,
          ),
          body:
          // CustomPullToRefresh(
          //   onRefresh: _handleRefresh,
          //   child: ListView.builder(
          //     itemCount: _items.length,
          //     itemBuilder: (context, index) => ListTile(
          //       title: Text(_items[index]),
          //     ),
          //   ),
          // ),
          TabBarView(controller: controller, children: pages),

        ),
      ),
    );

    //   Consumer<BottomNavProvider>(builder: (context, nav, child) {
    //   return Scaffold(
    //     body: pages[nav.currentIndex],
    //     bottomNavigationBar: BottomNavigationBar(
    //         onTap: (value) {
    //           nav.changeIndex(value);
    //         },
    //         currentIndex: nav.currentIndex,
    //         items: const [
    //           BottomNavigationBarItem(icon: Icon(Icons.image), label: "Image"),
    //           BottomNavigationBarItem(
    //               icon: Icon(Icons.video_call), label: "Video"),
    //           BottomNavigationBarItem(icon: Icon(Icons.access_alarm_outlined), label: "Experiments"),
    //           // BottomNavigationBarItem(icon: Icon(Icons.access_alarm_outlined), label: "PhotoManger"),
    //         ],
    //     ),
    //   );
    // });
  }
}
