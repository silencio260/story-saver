import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storysaver/Provider/bottom_nav_provider.dart';
import 'package:storysaver/Provider/getStatusProvider.dart';
import 'package:storysaver/Provider/savedMediaProvider.dart';
import 'package:storysaver/Screens/BottomNavPages/Experiments/ExperimentWithPhotoManager.dart';
import 'package:storysaver/Screens/BottomNavPages/Experiments/ThumbnailExperiment.dart';
import 'package:storysaver/Screens/BottomNavPages/Images/image.dart';
import 'package:storysaver/Screens/BottomNavPages/Video/video.dart';

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
    

    print('init myMainActivity');

    Provider.of<GetStatusProvider>(context, listen: false).getAllStatus();

    Provider.of<GetSavedMediaProvider>(context, listen: false).loadVideos();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        backgroundColor: const Color(0xff154734),
        foregroundColor: Colors.white,
      ),
      body: TabBarView(controller: controller, children: pages),

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
