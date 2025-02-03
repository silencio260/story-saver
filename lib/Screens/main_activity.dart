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

class _MainActivityState extends State<MainActivity> {

  void initState() {
    // TODO: implement initState
    super.initState();

    Provider.of<GetStatusProvider>(context, listen: false).getAllStatus();

    Provider.of<GetSavedMediaProvider>(context, listen: false).loadVideos();
  }

  List<Widget> pages = const [ImageHomePage(), VideoHomePage(), MediaStoreVideos()];

  @override
  Widget build(BuildContext context) {
    return Consumer<BottomNavProvider>(builder: (context, nav, child) {
      return Scaffold(
        body: pages[nav.currentIndex],
        bottomNavigationBar: BottomNavigationBar(
            onTap: (value) {
              nav.changeIndex(value);
            },
            currentIndex: nav.currentIndex,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.image), label: "Image"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.video_call), label: "Video"),
              BottomNavigationBarItem(icon: Icon(Icons.access_alarm_outlined), label: "Experiments"),
              // BottomNavigationBarItem(icon: Icon(Icons.access_alarm_outlined), label: "PhotoManger"),
            ],
        ),
      );
    });
  }
}
