import 'dart:io';
import 'dart:math';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:flutter/material.dart';
import 'package:storysaver/Constants/CustomColors.dart';

class ImageView extends StatefulWidget {
  final String? imagePath;
  const ImageView({Key? key, this.imagePath}) : super(key: key);

  @override
  State<ImageView> createState() => _ImageViewState();
}

class _ImageViewState extends State<ImageView> {
  List<Widget> buttonsList = [
    Icon(Icons.arrow_back),
    Icon(Icons.download),
    Icon(Icons.share),
    Icon(Icons.repeat_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        constraints: BoxConstraints(
          maxHeight: 700
        ),
        decoration: BoxDecoration(
          color: Colors.black,
          image: DecorationImage(
            image: FileImage(File(widget.imagePath!)),
            fit: BoxFit.contain,
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 70),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,

          children: List.generate(buttonsList.length, (index) {
            return FloatingActionButton(
              foregroundColor: Colors.white,
              backgroundColor: const Color(CustomColors.ButtonColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(70), // Adjust radius here
              ),
              elevation: 0,
              heroTag: '$index',
              onPressed: () async {
                switch (index) {
                  case 0:
                    Navigator.pop(context);
                    break;
                  case 1:
                    print("download");
                    ImageGallerySaver.saveFile(widget.imagePath!).then((value) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Image Saved")));
                    });
                    break;
                  case 2:
                    print("share");
                    break;
                }
              },
              child: buttonsList[index],
            );
          }),
        ),
      ),
    );
  }
}
