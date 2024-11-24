import 'package:flutter/material.dart';

class VideoView extends StatefulWidget {
  const VideoView({Key? key}) : super(key: key);

  @override
  State<VideoView> createState() => _VideoViewState();
}

class _VideoViewState extends State<VideoView> {
  List<Widget> buttonsList = [
    Icon(Icons.download),
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
