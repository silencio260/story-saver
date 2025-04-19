import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:provider/provider.dart';
import 'package:saf/saf.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storysaver/Constants/constant.dart';
import 'package:storysaver/Provider/PermissionProvider.dart';
import 'package:storysaver/Screens/home_page.dart';
import 'package:storysaver/Screens/splash_screen.dart';
import 'package:storysaver/Utils/getStoragePermission.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class WhatsAppStatusFolderPermission extends StatefulWidget {
  const WhatsAppStatusFolderPermission({Key? key}) : super(key: key);

  @override
  State<WhatsAppStatusFolderPermission> createState() => _WhatsAppStatusFolderPermissionState();
}

class _WhatsAppStatusFolderPermissionState extends State<WhatsAppStatusFolderPermission> {

  bool _loading = false;

  void navigate() {
    Future.delayed(const Duration(microseconds: 1), () {
      // Navigator.pop(context);
      Navigator.pushAndRemoveUntil(
          context,
          CupertinoPageRoute(builder: (_) => const HomePage()),
              (route) => false
      );
    },);
  }

  Future<void> _requestPermission(BuildContext context) async {
    try {

      // context.loaderOverlay.show();

      await AppStoragePermission().pickWhatsAppStatusFolder();

      // context.loaderOverlay.show();

      // final prefs = await SharedPreferences.getInstance();
      // bool? granted =  prefs.getBool(AppConstants().IS_WHATSAPP_STATUS_PERMISSION);
      final permission = Provider.of<PermissionProvider>(context, listen: false);

      bool granted = await AppStoragePermission().isWhatsAppStatusFolderPermissionAvailable();

      print("isGranted in _requestPermission 001 -->  $granted");

      if (granted != null && granted == true) {
        // Permission granted
        print("isGranted in _requestPermission  $granted");

        permission.setIsWhatsAppStatusSafAvailable(true);

        navigate();

        print('After Nav');

      } else {
        // Show error or retry message
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Permission denied ❌. Please try again.'))
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'))
      );
    }
    // await Future.delayed(const Duration(seconds: 3));
    // context.loaderOverlay.hide();
  }


  Widget _buildStep(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 30, right: 20, bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF00574B),
        title: Text(
          'Storage Permission Request',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: LoaderOverlay(
        // useDefaultLoading: false,
        overlayWidgetBuilder: (_) { //ignored progress for the moment
          return Center(
            child: SpinKitCubeGrid(
              color: Color(0xFF00574B),
              size: 50.0,
            ),
          );
        },
        child: Container(
        color: Colors.white,
        child: Column(
          children: [
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Allow permission Status Saver for Whatsapp Download to Access your photos and media from the .Statuses Folder.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 40),
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                'Steps',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildStep('1. Click on Allow Storage permission.'),
            _buildStep('2. Use .Statuses Folder.'),
            _buildStep('3. Allow To Folder Permission.'),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    context.loaderOverlay.show();
                    await _requestPermission(context);
                    // await Future.delayed(const Duration(seconds: 5));
                    context.loaderOverlay.hide();
                  },
                  child: const Text(
                    'Allow Permission',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF00574B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

}
