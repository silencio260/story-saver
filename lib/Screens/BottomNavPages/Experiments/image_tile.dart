import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'package:storysaver/Utils/GeAssetEntityPath.dart';

class ImageTile extends StatefulWidget {
  final AsyncSnapshot<Uint8List?>? snapshot;
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
            return ListTile(
              leading: Icon(Icons.broken_image),
              title: Text("Image not available"),
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
                    image: MemoryImage(widget.snapshot!.data!),
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
