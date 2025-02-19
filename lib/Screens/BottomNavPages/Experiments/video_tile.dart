import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VideoTile extends StatefulWidget {
  final AsyncSnapshot<dynamic>? snapshot;
  const VideoTile({Key? key, this.snapshot}) : super(key: key);

  @override
  State<VideoTile> createState() => _VideoTileState();
}

class _VideoTileState extends State<VideoTile> {
  @override
  Widget build(BuildContext context) {

      if (!(widget.snapshot!.hasData) || widget.snapshot!.data == null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            Icon(Icons.broken_image, color: Colors.grey),
            Text("Thumbnail not available", style: TextStyle(color: Colors.grey),)
          ],),
        );
      }

    return GestureDetector(
        onTap: () {


          // print('--+++--- ' +
          //     data.toString());
          // print(
          //     data);
          // print('--+++--- ' +
          //     data.path);
          // print(
          //     '--+++ ' + snapshot.data!);
          print(
              "--+++ ---- ${widget.snapshot!}");
        },
        child:  Container(
          // height: MediaQuery.of(context).size.height * 0.5,
          decoration: BoxDecoration(
              image: DecorationImage(
                image: MemoryImage(widget.snapshot!.data!),
                fit: BoxFit.cover,
              ),
              color: const Color.fromARGB(255, 236, 235, 230),
              borderRadius: BorderRadius.circular(2)),

          child: Stack(
            children: [
              // Your image is already inside the container with the decoration

              // Positioned widget for the video icon
              Positioned(
                top: 10, // Adjust to your preference
                right: 10, // Adjust to your preference
                child: Icon(
                  Icons.videocam_sharp, // You can replace it with any other video icon
                  color: Colors.white, // Icon color
                  size: 20, // Icon size
                ),
              ),
            ],
          ),
          // height: 500,
        ),
      );;
  }
}
