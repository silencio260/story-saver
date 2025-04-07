import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:provider/provider.dart';
import 'package:storysaver/Provider/savedMediaProvider.dart';
import 'package:storysaver/Screens/TopNavPages/Images/Image_view.dart';
import 'package:storysaver/Screens/TopNavPages/Video/video_view.dart';
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
    this.file,
  }) : pageController = PageController(initialPage: initialIndex);

  final LoadingBuilder? loadingBuilder;
  final BoxDecoration? backgroundDecoration;
  final dynamic minScale;
  final dynamic maxScale;
  final int initialIndex;
  final PageController pageController;
  final List<AssetEntity> galleryItems;
  final isVideoView;
  final Axis scrollDirection;
  final GetSavedMediaProvider? file;

  @override
  State<StatefulWidget> createState() {
    return _SavedMediaPhotoViewWrapperState();
  }
}

class _SavedMediaPhotoViewWrapperState extends State<SavedMediaPhotoViewWrapper> {
  late int currentIndex = widget.initialIndex;
  late String currentFilePath;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    // if(currentIndex == widget.initialIndex)
      _loadFilePath();

  }

  void onPageChanged(int index) async {
    final AssetEntity item = widget.galleryItems[index];
    final filePath = await getAssetEntityPath(item);

    setState(() {
      currentIndex = index;
      currentFilePath = filePath!;
    });
  }

  void _loadFilePath() async {

    final AssetEntity item = widget.galleryItems[currentIndex];
    final filePath = await getAssetEntityPath(item);

    setState(() {
      currentFilePath = filePath!;
    });

  }

  void loadMoreItem () {
    Provider.of<GetSavedMediaProvider>(context, listen: false).loadVMediaInStaggeredBatches();
  }

  void _shouldLoadMoreMedia (int index) {
    if( index >= widget.file!.nextLoadTrigger ){

      if(widget.file!.numLoadedAssets <= widget.file!.totalNumAssets && !widget.file!.isProcessingMedia){
        loadMoreItem();
        widget.file!.setNewLoadTrigger();
        print('Load More Media Files nextLoadTrigger = ${widget.file!.nextLoadTrigger} - numLoadedAssets = ${widget.file!.numLoadedAssets} ');
      }

    }
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
              // wantKeepAlive: true,
            ),
            Container(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                // "Image ${currentIndex + 1} - Files - ${widget!.file!.getMediaFile.length}",
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

    _shouldLoadMoreMedia(index);

    // print('SavedMediaPhotoViewWrapper widget.videoFilePath ${item.file}');
    print('video_Index = ${index} - total_length = ${widget.galleryItems.length}');
    // print('/storage/emulated/0/${item.relativePath}/${item.title} --> ${index}');
    // print('currentFilePath ${currentFilePath} --> ${currentIndex} --> index = ${index}');

    return PhotoViewGalleryPageOptions.customChild(
      child:  FutureBuilder<dynamic>(
        future: getAssetEntityPath(item),//item.type == AssetType.video ? video.thumbnailData : video.file, // Fetch thumbnail data
        builder: (context, snapshot) {

          if (snapshot.hasError) {
            // If there was an error, show an error widget
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          // print('SavedMediaPhotoViewWrapper snapshot.data ${snapshot.data}');
          print('SavedMediaPhotoViewWrapper snapshot.data ${snapshot.data}');

          return item.type == AssetType.video ?
           VideoView(
               videoPath:  snapshot.data,
               isSavedMedia: true,
               currentIndex: index,
               isLoading: snapshot.hasData ? false : true
           )
              :
           ImageView(
               imagePath: snapshot.data,
               isSavedMedia: true,
               currentIndex: index,
               isLoading: snapshot.hasData ? false : true
           );
        }
      ),
    );
  }
}