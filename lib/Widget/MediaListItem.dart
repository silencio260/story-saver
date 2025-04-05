import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storysaver/Provider/getStatusProvider.dart';
import 'package:storysaver/Utils/SavedMediaManager.dart';
import 'package:storysaver/Utils/saveStatus.dart';
import 'package:storysaver/Widget/GalleryPhotoViewWrapper.dart';
import 'package:storysaver/Widget/LocalCachedImage.dart';

class MediaListItem extends StatefulWidget {
  final String mediaPath;
  final bool isVideo;
  final String? videoFilePath;
  final int? currentIndex;
  // final Future<bool> Function(String mediaPath) checkMediaSaved;

  const MediaListItem({Key? key,
      required this.mediaPath,
      this.isVideo = false,
      this.videoFilePath = null,
      this.currentIndex = 0,
      // required this.checkMediaSaved,
      })
      : super(key: key);

  @override
  _MediaListItemState createState() => _MediaListItemState();
}

class _MediaListItemState extends State<MediaListItem> with AutomaticKeepAliveClientMixin {
  late bool isAlreadySaved;
  late Future<bool> _future;
  final mediaManager = SavedMediaManager();

  bool get wantKeepAlive => false;

  @override
  void initState() {
    super.initState();
    _future = mediaManager.isMediaSaved(
        widget.mediaPath); //widget.checkMediaSaved(widget.mediaPath);
    isAlreadySaved = false;
  }

  void _toggleSavedStatus() async {

    if(_checkFileExists() == false){
      // _showErrorDialog("Error: Files does not exist");
      return;
    }

    // Handle the click event here
    print("Icon tapped!");
    final result = await mediaManager.saveMedia(
        widget.videoFilePath != null ?
        widget.videoFilePath! :
        widget.mediaPath)
    ;

    saveStatus(context, widget.mediaPath);

    // isAlreadySaved = true;
    print('Aready Saved');
    setState(() {
      isAlreadySaved = !isAlreadySaved; // Toggle the state
    });

    // _showErrorDialog("Status Saved");
  }

  void saveMedia () async {
    _toggleSavedStatus();
  }

  bool _checkFileExists()  {
    if (widget.mediaPath == null || widget.mediaPath!.isEmpty) {
      _showErrorDialog("Media path is missing!");
      return false;
    }

    File file = File(widget.mediaPath!);
    bool exists =  file.existsSync();

    if (!exists) {
      _showErrorDialog("File does not exist at the given path!");
      return false;
    }

    return true;
  }

  void _showErrorDialog(String message) {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<bool>(
        future: widget.videoFilePath != null ?
          mediaManager.isMediaSaved(widget.videoFilePath!) :
          mediaManager.isMediaSaved(widget.mediaPath),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              !snapshot.hasData) {
            return Container();
          }

          if (snapshot.hasError) {
            // If there was an error, show an error widget
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          bool isAlreadySaved = snapshot.data ?? false;

          print('widget.videoFilePath ${snapshot.data} $isAlreadySaved - ${widget.videoFilePath}');
          return GestureDetector(
            onTap: () {

              if (widget.isVideo) {
                print('widget.videoFilePath $isAlreadySaved - ${widget.videoFilePath}');
                if(widget.videoFilePath != null)
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (_) =>
                        GalleryPhotoViewWrapper(initialIndex: widget.currentIndex!, isVideoView: true,
                        galleryItems: Provider.of<GetStatusProvider>(context, listen: false).getVideos)
                    // VideoView(videoPath: widget.videoFilePath),
                  ),
                );
              } else {
                // print('widget.ImagePath $isAlreadySaved - ${widget.mediaPath}');
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (_) => GalleryPhotoViewWrapper(initialIndex: widget.currentIndex!,
                        galleryItems: Provider.of<GetStatusProvider>(context, listen: false).getImages)
                    //ImageView(imagePath: widget.mediaPath),
                  ),
                );
              }
            },
            child: Stack(
              children: [
                Positioned.fill(
                  child: LocalImageCache(
                    widget.mediaPath, // Cached image widget
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      color: Color.fromRGBO(0, 0, 0, 0.3),
                      width: 200,
                      height: 50,
                      // child: Placeholder(),
                      // child: Text('data'),
                    ),
                  ),
                ),
                Positioned(
                  // top: 10, // Adjust the position as needed
                  right: 0,
                  bottom: 0,
                  child: Container(
                    // color: Colors.blue,//Color.fromRGBO(0, 0, 0, 0.3),
                    width: 80,
                    child: GestureDetector(
                      onTap: () async {
                        _toggleSavedStatus();
                      },
                      child: Container(
                        // color: Colors.red,
                        alignment: Alignment.bottomRight,
                        child: Container(
                          constraints: BoxConstraints(maxWidth: 50, maxHeight: 50),
                          width: 50,
                          height: 50,
                          child: !isAlreadySaved ? Icon(
                            Icons.download, // Replace with your desired icon
                            color: const Color.fromARGB(255, 236, 235, 230),
                            size: 20,
                          ) :
                          Icon(
                            Icons.done_all, // Replace with your desired icon
                            color:  Colors.green,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.isVideo)
                  Positioned(
                    top: 10, // Adjust to your preference
                    left: 10, // Adjust to your preference
                    child: Icon(
                      Icons
                          .videocam_sharp, // You can replace it with any other video icon
                      color: Colors.white, // Icon color
                      size: 20, // Icon size
                    ),
                  ),
              ],
            ),
          );
        });
  }
}

