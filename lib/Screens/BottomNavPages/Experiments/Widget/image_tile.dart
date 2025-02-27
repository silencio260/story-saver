import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'package:storysaver/Utils/GetAssetEntityPath.dart';

class ImageTile extends StatefulWidget {
  final AsyncSnapshot<dynamic>? snapshot;
  const ImageTile({Key? key, this.snapshot}) : super(key: key);

  @override
  State<ImageTile> createState() => _ImageTileState();
}

class _ImageTileState extends State<ImageTile> {
  @override
  Widget build(BuildContext context) {
    // final filePath = getAssetEntityPath(widget.entity!);

    // if (widget.entity == null) {
    //   return ListTile(
    //     leading: Icon(Icons.broken_image),
    //     title: Text("Image not available"),
    //   );
    // }

          if (!widget.snapshot!.hasData || widget.snapshot!.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                Icon(Icons.broken_image, color: Colors.grey),
                // Text("Image not available", style: TextStyle(color: Colors.grey),)
              ],),
            );
          }

          return GestureDetector(
            onTap: () {
              // print(
              //     "--+++ ---- ${widget.snapshot!}");
            },
            child: Container(
              // height: MediaQuery.of(context).size.height * 0.5,
              decoration: BoxDecoration(
                  image: DecorationImage(
                    image: FileImage(File(widget.snapshot!.data!.path)),
                    // image: MemoryImage(widget.snapshot!.data.path!),
                    // image: FileImage(File(snapshot.data!)),
                    fit: BoxFit.cover,
                  ),
                  color: const Color.fromARGB(255, 236, 235, 230),
                  borderRadius: BorderRadius.circular(2)),

              // height: 500,
            ),
          );
  }
}
