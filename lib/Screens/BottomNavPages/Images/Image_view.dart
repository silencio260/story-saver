import 'dart:math';

import 'package:flutter/material.dart';

class ImageView extends StatefulWidget {
  const ImageView({Key? key}) : super(key: key);

  @override
  State<ImageView> createState() => _ImageViewState();
}

class _ImageViewState extends State<ImageView> {
  List<Widget> buttonsList = [
    Icon(Icons.download),
    Icon(Icons.print),
    Icon(Icons.share),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: Colors.grey),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(left: 25),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(buttonsList.length, (index) {
            return FloatingActionButton(
              foregroundColor: Colors.white,
              backgroundColor: Colors.green,
              elevation: 0,
              heroTag: '$index',
              onPressed: () {
                switch (index) {
                  case 0:
                    print("download");
                    break;
                  case 1:
                    print("print");
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
