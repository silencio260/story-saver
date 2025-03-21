import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:storysaver/Screens/BottomNavPages/Images/Image_view.dart';
import 'package:storysaver/Screens/BottomNavPages/Video/video_view.dart';
import 'package:storysaver/Utils/GetAssetEntityPath.dart';



class SavedMediaPhotoViewWrapper extends StatefulWidget {
  SavedMediaPhotoViewWrapper({
    this.loadingBuilder,
    this.backgroundDecoration,
    this.minScale,
    this.maxScale,
    this.initialIndex = 0,
    required this.galleryItems,
    this.isVideoView = false,
    this.scrollDirection = Axis.horizontal,
  }) : pageController = PageController(initialPage: initialIndex);

  final LoadingBuilder? loadingBuilder;
  final BoxDecoration? backgroundDecoration;
  final dynamic minScale;
  final dynamic maxScale;
  final int initialIndex;
  final PageController pageController;
  final List<AssetEntity> galleryItems;
  final isVideoView ;
  final Axis scrollDirection;

  @override
  State<StatefulWidget> createState() {
    return _SavedMediaPhotoViewWrapperState();
  }
}

class _SavedMediaPhotoViewWrapperState extends State<SavedMediaPhotoViewWrapper> {
  late int currentIndex = widget.initialIndex;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  void onPageChanged(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: widget.backgroundDecoration,
        constraints: BoxConstraints.expand(
          height: MediaQuery.of(context).size.height,
        ),
        child: Stack(
          alignment: Alignment.bottomRight,
          children: <Widget>[
            PhotoViewGallery.builder(
              scrollPhysics: const BouncingScrollPhysics(),
              builder: _buildItem,
              itemCount: widget.galleryItems.length,
              loadingBuilder: widget.loadingBuilder,
              backgroundDecoration: widget.backgroundDecoration,
              pageController: widget.pageController,
              onPageChanged: onPageChanged,
              scrollDirection: widget.scrollDirection,
            ),
            Container(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                "Image ${currentIndex + 1}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17.0,
                  decoration: null,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  PhotoViewGalleryPageOptions _buildItem(BuildContext context, int index) {
    final AssetEntity item = widget.galleryItems[index];

    print('SavedMediaPhotoViewWrapper widget.videoFilePath ${item.file}');
    print('video_Index = ${index} - total_length = ${widget.galleryItems.length}');

    return PhotoViewGalleryPageOptions.customChild(
      child: FutureBuilder<dynamic>(
        future: getAssetEntityPath(item),//item.type == AssetType.video ? video.thumbnailData : video.file, // Fetch thumbnail data
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

          // print('SavedMediaPhotoViewWrapper snapshot.data ${snapshot.data}');

          return item.type == AssetType.video ?
          VideoView(videoPath:  snapshot.data)
          : ImageView(imagePath: snapshot.data);
        }
      ),
      // !widget.isVideoView ?
      // ImageView(imagePath: item.relativePath)
            // :
      // VideoView(videoPath:  item.path),
    );
  }
}