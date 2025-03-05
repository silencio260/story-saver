import 'dart:io';

import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:storysaver/Screens/BottomNavPages/Images/Image_view.dart';
// import 'package:photo_view_example/screens/common/app_bar.dart';
// import 'package:photo_view_example/screens/examples/gallery/gallery_example_item.dart';

//
// class GalleryScrollView extends StatefulWidget {
//   const GalleryScrollView({Key? key,}) : super(key: key);
//
//   @override
//   State<GalleryScrollView> createState() => _GalleryScrollViewState();
// }
//
// class _GalleryScrollViewState extends State<GalleryScrollView> {
//   @override
//   Widget build(BuildContext context) {
//     return const Placeholder();
//   }
// }


class GalleryPhotoViewWrapper extends StatefulWidget {
  GalleryPhotoViewWrapper({
    this.loadingBuilder,
    this.backgroundDecoration,
    this.minScale,
    this.maxScale,
    this.initialIndex = 0,
    required this.galleryItems,
    this.scrollDirection = Axis.horizontal,
  }) : pageController = PageController(initialPage: initialIndex);

  final LoadingBuilder? loadingBuilder;
  final BoxDecoration? backgroundDecoration;
  final dynamic minScale;
  final dynamic maxScale;
  final int initialIndex;
  final PageController pageController;
  final List<FileSystemEntity> galleryItems;
  final Axis scrollDirection;

  @override
  State<StatefulWidget> createState() {
    return _GalleryPhotoViewWrapperState();
  }
}

class _GalleryPhotoViewWrapperState extends State<GalleryPhotoViewWrapper> {
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
    final FileSystemEntity item = widget.galleryItems[index];

    return PhotoViewGalleryPageOptions.customChild(
          child: ImageView(imagePath: item.path!),
    );

    //   return PhotoViewGalleryPageOptions(
    //   imageProvider: FileImage(File(item.path)),//FileImage(item),
    //   initialScale: PhotoViewComputedScale.contained,
    //   minScale: PhotoViewComputedScale.contained * (0.5 + index / 10),
    //   maxScale: PhotoViewComputedScale.covered * 4.1,
    //   // heroAttributes: PhotoViewHeroAttributes(tag: item.id),
    // );
    // return item.isSvg
    //     ? PhotoViewGalleryPageOptions.customChild(
    //   child: Container(
    //     width: 300,
    //     height: 300,
    //     child: Icon(Icons.abc)
    //   ),
    //   childSize: const Size(300, 300),
    //   initialScale: PhotoViewComputedScale.contained,
    //   minScale: PhotoViewComputedScale.contained * (0.5 + index / 10),
    //   maxScale: PhotoViewComputedScale.covered * 4.1,
    //   heroAttributes: PhotoViewHeroAttributes(tag: item.id),
    // )
    //     : PhotoViewGalleryPageOptions(
    //   imageProvider: AssetImage(item.resource),
    //   initialScale: PhotoViewComputedScale.contained,
    //   minScale: PhotoViewComputedScale.contained * (0.5 + index / 10),
    //   maxScale: PhotoViewComputedScale.covered * 4.1,
    //   heroAttributes: PhotoViewHeroAttributes(tag: item.id),
    // );
  }
}