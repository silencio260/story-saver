import 'dart:io';
import 'package:flutter/material.dart';
import 'package:storysaver/Screens/BottomNavPages/Experiments/Widget/video_tile.dart';


class ImageTile extends StatefulWidget {
  final AsyncSnapshot<dynamic>? snapshot;
  const ImageTile({Key? key, this.snapshot}) : super(key: key);

  @override
  State<ImageTile> createState() => _ImageTileState();
}

class _ImageTileState extends State<ImageTile> {
  @override
  Widget build(BuildContext context) {

    if (!widget.snapshot!.hasData || widget.snapshot!.data == null || widget.snapshot!.data is! File ) {
          // print("FileType ${widget.snapshot!.data} ||| ${widget.snapshot!.data} ");
          return VideoTile(snapshot: widget.snapshot);
          }
          // print("path - ${widget.snapshot!.data!.path!}");

          return Container(
              // height: MediaQuery.of(context).size.height * 0.5,
              decoration: BoxDecoration(
                  image: DecorationImage(
                    image: FileImage(File(widget.snapshot!.data!.path!)),
                    fit: BoxFit.cover,
                  ),
                  color: const Color.fromARGB(255, 236, 235, 230),
                  borderRadius: BorderRadius.circular(0),
              ),
              // height: 500,
          );
  }
}
