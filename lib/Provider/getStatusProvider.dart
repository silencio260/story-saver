import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:storysaver/Constants/constant.dart';

class GetStatusProvider extends ChangeNotifier {
  List<FileSystemEntity> _getImages = [];
  List<FileSystemEntity> _getVideos = [];

  bool _isWhatsappAvailable = false;

  List<FileSystemEntity> get getImages => _getImages;
  List<FileSystemEntity> get getVideos => _getVideos;

  bool get isWhatsappAvailable => _isWhatsappAvailable;

  void getStatus(String ext) async {
    if (await getStoragePermission() == true) {
      final directory = Directory(AppConstants.WHATSAPP_PATH);
      // print('++++++++++++++++++');
      // print(directory.existsSync());
      if (directory.existsSync()) {
        final items = directory.listSync();

        // print('++++++++++++++++++');
        // print(items.toString());

        if (ext == ".mp4") {
          _getVideos =
              items.where((element) => element.path.endsWith(ext)).toList();
          notifyListeners();
        } else {
          _getImages =
              items.where((element) => element.path.endsWith('.jpg')).toList();
          notifyListeners();
        }
      }
      _isWhatsappAvailable = true;
      notifyListeners();
    } else {
      // if (getStoragePermission() == false) {
      //   _isWhatsappAvailable = false;
      //   notifyListeners();
      // }
    }
  }

  void getDirectoryItems() {
    final directory = Directory(AppConstants.WHATSAPP_PATH);

    if (directory.existsSync()) {
      final items = directory
          .listSync()
          .where((element) => element.path.endsWith('.jpg'));
      print('++++++++++++++++++');
      print(items.toString());
    } else {
      print('++++++++++++++++++');
      print('no whatsapp found');
    }
  }

  Future<bool> getStoragePermission() async {
    print('----------------- being called');
    final status = await Permission.storage.request();
    print('++++++++++++++++++++++++ $status');

    Directory? directory = await getExternalStorageDirectory();
    print(directory?.path);

    if (status.isDenied) {
      Permission.storage.request();
      print("================ Permission denied");
    }

    if (status.isGranted) {
      // Permission.storage.request();
      // print("================ Permission Granted");
      // print(directory?.path);
      // getDirectoryItems();
      return true;
    } else {
      // For Android 11+ (MANAGE_EXTERNAL_STORAGE)
      final storagePermission = await Permission.manageExternalStorage;

      print(
          '------------ is denied ${await storagePermission.isDenied} ------    is granted ${await storagePermission.isGranted} --- status ${await storagePermission.status}');

      if (await Permission.manageExternalStorage.isGranted) {
        print("--------------------- Permission alredy granted");
        // getDirectoryItems();
        return true;
      } else if (await Permission.manageExternalStorage.isDenied) {
        PermissionStatus manageStatus =
            await Permission.manageExternalStorage.request();
        if (manageStatus.isGranted) {
          print(
              "--------------------- Manage External Storage permission granted");
          // getDirectoryItems();
          return true;
        } else {
          print(
              "----------------------- Manage External Storage permission denied");
          openAppSettings(); // Optionally prompt user to open settings for manual permission
        }
      }

      // print("================---------- ${directory?.path}");
      // print();
      return false;
    }
  }
}
