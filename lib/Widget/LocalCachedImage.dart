import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class LocalImageCache extends StatelessWidget {
  final String localImagePath;

  LocalImageCache(this.localImagePath);

  @override
  Widget build(BuildContext context) {

    File tempFile = File(localImagePath);

    if (!tempFile.existsSync()) {

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image,
                color: Colors.grey),
            // Text("Image not available", style: TextStyle(color: Colors.grey),)
          ],
        ),
      );
    }

    return FutureBuilder<File>(
      future: DefaultCacheManager().putFile(localImagePath, File(localImagePath).readAsBytesSync()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData && snapshot.data != null) {
          return Image.file(snapshot.data!, fit: BoxFit.cover);
        } else {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image,
                    color: Colors.grey),
                // Text("Image not available", style: TextStyle(color: Colors.grey),)
              ],
            ),
          );
        }
      },
    );
  }
}
