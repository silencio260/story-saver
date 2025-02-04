import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:storysaver/Constants/CustomColors.dart';
import 'package:storysaver/Utils/ShareToApp.dart';
import 'package:video_player/video_player.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

class VideoView extends StatefulWidget {
  final String? videoPath;
  const VideoView({Key? key, this.videoPath}) : super(key: key);

  @override
  State<VideoView> createState() => _VideoViewState();
}

class _VideoViewState extends State<VideoView> {
  List<Widget> buttonsList = [
    Icon(Icons.arrow_back),
    Icon(Icons.download),
    Icon(Icons.share),
    Icon(Icons.repeat_outlined),
  ];

  ChewieController? _chewieController;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _chewieController = ChewieController(
        videoPlayerController:
            VideoPlayerController.file(File(widget.videoPath!)),
        autoInitialize: true,
        autoPlay: true,

        // looping: true,
        aspectRatio: 1,
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color( CustomColors.ButtonColor), // Color of the played portion
          handleColor: const Color( CustomColors.ButtonColor), // Color of the draggable handle
          bufferedColor: Colors.grey, // Color of the buffered portion
          backgroundColor: Colors.black, // Color of the remaining part
        ),

        errorBuilder: ((context, errorMessage) {
          return Center(
            child: Text(errorMessage),
          );
        }));
  }

  @override
  void dispose() {
    // TODO: implement dispose

    _chewieController!.pause();
    _chewieController!.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        constraints: BoxConstraints(
            maxHeight: 700
        ),
        child:  Chewie(controller: _chewieController!),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 70),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(buttonsList.length, (index) {
            return FloatingActionButton(
              foregroundColor: Colors.white,
              backgroundColor: const Color( CustomColors.ButtonColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(70), // Adjust radius here
              ),
              elevation: 0,
              heroTag: '$index',
              onPressed: () {
                switch (index) {
                  case 0:
                    Navigator.pop(context);
                    break;
                  case 1:
                    print("download");
                    ImageGallerySaver.saveFile(widget.videoPath!).then((value) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Image Saved")));
                    });
                    break;
                  case 2:
                    print("share");
                    Share.shareXFiles([XFile(widget.videoPath!)],
                        text: 'Shared From WhatsApp Story Saver').then((value) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Video Sent")));
                    });
                    break;

                  case 3:
                    print("share");
                    shareToWhatsApp('Shared From Status Saver', filePath: widget.videoPath!, context: context);
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
