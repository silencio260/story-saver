import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:storysaver/Screens/splash_screen.dart';
import 'package:storysaver/Utils/getStoragePermission.dart';

Widget GrantPermissionButton(BuildContext context, {VoidCallback? onPermissionGranted}) {

  void refreshApp(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    // Navigator.of(context).push(SplashScreen());
    // Navigator.(
    //   context,
    //   CupertinoPageRoute(
    //       builder: (_) => SplashScreen(),
    //   ),
    // );
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SplashScreen()),
          (route) => false,
    );

  }


  Future<void> _requestPermission() async {

    //works for android 11+
    final status = await getStoragePermission(); //await Permission.manageExternalStorage.request(); //await Permission.storage.request();

    refreshApp(context);


    if (status == true) {
      onPermissionGranted?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Permission Granted ✅")),
      );

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Permission Denied ❌")),
      );
    }
  }

  return Center(
    child: ElevatedButton(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all<Color>(Colors.green),
      ),
      onPressed: _requestPermission,
      child: Text("Grant Permission", style: TextStyle(color: Colors.white)),
    ),
  );
}

