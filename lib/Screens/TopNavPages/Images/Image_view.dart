import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:storysaver/Constants/CustomColors.dart';
import 'package:storysaver/Provider/savedMediaProvider.dart';
import 'package:storysaver/Utils/SavedMediaManager.dart';
import 'package:storysaver/Utils/ShareToApp.dart';
import 'package:storysaver/Utils/fileExistsDialog.dart';
import 'package:storysaver/Utils/saveStatus.dart';
import 'package:storysaver/Widget/deleteSavedMediaUtils.dart';

class ImageView extends StatefulWidget {
  final String? imagePath;
  final bool isLoading;
  final isSavedMedia;
  final int? currentIndex;

  const ImageView({
    Key? key,
    this.imagePath,
    this.isLoading = false,
    this.isSavedMedia = false,
    this.currentIndex = null,
  }) : super(key: key);

  @override
  State<ImageView> createState() => _ImageViewState();
}

class _ImageViewState extends State<ImageView> {
  List<Widget> buttonsList = [
    Icon(Icons.arrow_back),
    Icon(Icons.download),
    Icon(Icons.share),
    Icon(Icons.repeat_outlined),
    Icon(Icons.delete),
  ];
  final mediaManager = SavedMediaManager();

  @override
  void initState() {
    super.initState();

    if (!widget.isLoading) if (checkFileExists(widget.imagePath!) == false)
      showErrorDialog(context, "File does not exists");
  }

  void _toggleSavedStatus() async {
    if (checkFileExists(widget.imagePath!) == false) {
      showErrorDialog(context, "Error: Files does not exist");
      return;
    }

    // Handle the click event here
    print("Icon tapped!");
    final result = await mediaManager.saveMedia(widget.imagePath!);

    saveStatus(context, widget.imagePath!);

    // isAlreadySaved = true;
    print('Aready Saved');

    // _showErrorDialog("Status Saved");
  }

  void saveMedia() async {
    if (!widget.isLoading) _toggleSavedStatus();
  }

  void _shareMedia(BuildContext context) {
    // print("share");
    if (!widget.isLoading) {
      Share.shareXFiles([XFile(widget.imagePath!)],
              text: 'Shared From WhatsApp Story Saver')
          .then((value) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Image Sent")));
      });
    }
  }

  void _shareMediaToWhatsapp(BuildContext context) {
    if (!widget.isLoading) {
      // print("share");
      shareToWhatsApp('Shared From Status Saver',
          filePath: widget.imagePath!, context: context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        // decoration: ShapeDecoration(color: Colors.red, shape: isEven),
        color: Colors.black,
        constraints: BoxConstraints(maxHeight: 700),
        child: widget.isLoading == true
            ? Placeholder()
            : PhotoView(
                imageProvider: FileImage(File(widget.imagePath!)),
                minScale: PhotoViewComputedScale.contained, // initial scale
                maxScale: PhotoViewComputedScale.covered * 2, // maximum zoom in
                initialScale:
                    PhotoViewComputedScale.contained, // start at contained size
                scaleStateController: PhotoViewScaleStateController(),
                scaleStateCycle: (actual) {
                  // Only allow zooming in
                  if (actual == PhotoViewScaleState.initial) {
                    return PhotoViewScaleState.zoomedIn;
                  }
                  return PhotoViewScaleState.initial;
                },
              ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 70),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(buttonsList.length, (index) {
            if ((widget.isSavedMedia == false && index != 4) ||
                (widget.isSavedMedia == true && index != 1)) {
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
                      saveMedia();
                      break;

                    case 2:
                      _shareMedia(context);
                      break;

                    case 3:
                      _shareMediaToWhatsapp(context);
                      break;

                    case 4:
                      if (widget.isSavedMedia && widget.currentIndex != null) {
                        final mediaProvider =
                            Provider.of<GetSavedMediaProvider>(context,
                                listen: false);
                        deleteSavedMeidaUtils().confirmFileDeleteDialog(
                          context,
                          'Are you sure you want to delete?',
                          mediaProvider,
                          widget.currentIndex!,
                        );
                      }
                      break;
                  }
                },
                child: buttonsList[index],
              );
            } else
              return Container(
                child: Text(''),
              );
          }),
        ),
      ),
    );
  }
}
