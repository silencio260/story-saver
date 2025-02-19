import 'dart:isolate';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_isolate/flutter_isolate.dart';
import 'package:provider/provider.dart';
import 'package:storysaver/Provider/savedMediaProvider.dart';
import 'package:storysaver/Screens/main_activity.dart';
import 'package:storysaver/Services/AppRatingService.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    // Isolate.spawn((message) {
    //   print("Hello from isolate: $message");
    // }, "Test Message");

    Provider.of<GetSavedMediaProvider>(context, listen: false).loadVideosSegmented();
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   Provider.of<GetSavedMediaProvider>(context, listen: false).loadVideos();
    // });


    navigate();
  }

  void navigate() {
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushAndRemoveUntil(
          context,
          CupertinoPageRoute(builder: (_) => const MainActivity()),
          (route) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: FlutterLogo(),
      ),
    );
  }
}
