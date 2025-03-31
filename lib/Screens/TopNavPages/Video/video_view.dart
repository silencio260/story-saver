import 'dart:io';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:storysaver/Constants/CustomColors.dart';
import 'package:storysaver/Utils/SavedMediaManager.dart';
import 'package:storysaver/Utils/ShareToApp.dart';
import 'package:storysaver/Utils/fileExistsDialog.dart';
import 'package:storysaver/Utils/saveStatus.dart';
import 'package:video_player/video_player.dart';

class VideoView extends StatefulWidget {
  final String? videoPath;
  final bool isLoading;
  const VideoView({Key? key, this.videoPath, this.isLoading = false}) : super(key: key);

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
  final mediaManager = SavedMediaManager();

  ChewieController? _chewieController;
  late VideoPlayerController _videoPlayerController;

  void _toggleSavedStatus() async {

    if(checkFileExists(widget.videoPath!) == false){
      showErrorDialog(context, "Error: Files does not exist");
      return;
    }

    // Handle the click event here
    print("Icon tapped!");
    final result = await mediaManager.saveMedia(widget.videoPath!);

    saveStatus(context, widget.videoPath!);

    // isAlreadySaved = true;
    print('Aready Saved');


    // _showErrorDialog("Status Saved");
  }

  void saveMedia () async {
    if(!widget.isLoading)
    _toggleSavedStatus();
  }

  void _shareMedia(BuildContext context){
    if(!widget.isLoading) {
      // print("share");
      Share.shareXFiles([XFile(widget.videoPath!)],
          text: 'Shared From WhatsApp Story Saver').then((value) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Video Sent")));
      });
    }
  }

  void _shareMediaToWhatsapp(BuildContext context){
    if(!widget.isLoading) {
      // print("share");
      shareToWhatsApp('Shared From Status Saver', filePath: widget.videoPath!, context: context);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _onStart();
  }

  void _onStart() {
    if(!widget.isLoading) {
      if (checkFileExists(widget.videoPath!) == false)
        showErrorDialog(context, "File does not exists");


      if (widget.videoPath != null && widget.videoPath!.isNotEmpty) {
        _initializePlayer();
      }
    }
  }

  Future<void> _initializePlayer() async {
    print('_initializePlayer ------- ');
    _videoPlayerController = VideoPlayerController.file(File(widget.videoPath!));

    await _videoPlayerController.initialize();

    setState(() {
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoInitialize: true,
        autoPlay: true,
        aspectRatio: _videoPlayerController.value.aspectRatio, // Fixed aspect ratio issue
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(CustomColors.ButtonColor),
          handleColor: const Color(CustomColors.ButtonColor),
          bufferedColor: Colors.grey,
          backgroundColor: Colors.black,
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(errorMessage),
          );
        },
      );
    });
  }


  @override
  void didUpdateWidget(VideoView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isLoading != widget.isLoading) {
      _onStart();
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    print('Dipose');
    _chewieController!.pause();
    _videoPlayerController.dispose();
    // _chewieController!.videoPlayerController.dispose();
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
        child: !widget.isLoading ?
        (_chewieController != null
            ? Chewie(controller: _chewieController!)
            : const Center(child: CircularProgressIndicator())
        )
            : Placeholder(),
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
                    print("Save");
                    saveMedia();
                    break;

                  case 2:
                    _shareMedia(context);
                    break;

                  case 3:
                   _shareMediaToWhatsapp(context);
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
