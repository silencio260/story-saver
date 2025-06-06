

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'package:storysaver/Provider/savedMediaProvider.dart';
import 'package:storysaver/Screens/BottomNavPages/Experiments/Widget/image_tile.dart';
import 'package:storysaver/Screens/BottomNavPages/Experiments/Widget/video_tile.dart';

class SavedMediaGridItem extends StatefulWidget {
  final AssetEntity video;

  const SavedMediaGridItem({required this.video, Key? key}) : super(key: key);

  @override
  _SavedMediaGridItemState createState() => _SavedMediaGridItemState();
}

class _SavedMediaGridItemState extends State<SavedMediaGridItem> {
  Future<dynamic>? _thumbnailFuture;
  GetSavedMediaProvider? mediaProvider;
  late final lotsOfData = _shouldRebuildCachedItem();

  @override
  void initState() {
    super.initState();
    // Cache the Future in initState
    _thumbnailFuture = _getThumbnail();

    mediaProvider = Provider.of<GetSavedMediaProvider>(context, listen: false);
  }

  Future<dynamic> _getThumbnail() async {
    if (widget.video.type == AssetType.video) {
      return await widget.video.thumbnailDataWithSize(const ThumbnailSize(500, 500)); // Fetch video thumbnail
    } else {
      return await widget.video.file; // Fetch video file
    }
  }

  dynamic fetchItem()  {

    return _shouldRebuildCachedItem();
  }


    Future<dynamic> _shouldRebuildCachedItem() async {

    // final mediaProvider = Provider.of<GetSavedMediaProvider>(context, listen: false);

    if (mediaProvider!.buildCachedFirstItem &&
        mediaProvider!.prevFirstItem!.title != mediaProvider!.getMediaFile[0].title) {
      print('buildCachedFirstItem');
      mediaProvider!.reSetBuildVariables();

      // WidgetsBinding.instance.addPostFrameCallback((_) {
      //   if (mounted) {
      //     mediaProvider!.reSetBuildVariables();
      //   }
      // });

      return await _getThumbnail(); // Fetch video thumbnail
    } else {
      return _thumbnailFuture; // Fetch video file
    }
    // return _thumbnailFuture;
  }

  // Future<dynamic> _shouldRebuildCachedItem() async {
  //   // _cachedThumbnailFuture ??= _thumbnailFuture; // ✅ Reuse cached Future
  //   return _thumbnailFuture!;
  // }


  @override
  Widget build(BuildContext context) {
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (mounted) { // ✅ Prevent unnecessary state updates
    //     fetchItem();
    //   }
    // });

    return FutureBuilder<dynamic>(
      future: _thumbnailFuture, // Use cached Future
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError || snapshot.data == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, color: Colors.red),
                Text(snapshot.error.toString()),
              ],),
          );
        } else if (snapshot.hasData && snapshot.data != null) {
          // If video thumbnail, display it
          if (widget.video.type == AssetType.video) {
            return VideoTile(snapshot: snapshot);
            // return Image.memory(
            //   snapshot.data!,
            //   fit: BoxFit.cover,
            // );
          } else {
            // If not a video, display file
            return ImageTile(snapshot: snapshot);
            return Image.file(
              snapshot.data!,
              fit: BoxFit.cover,
            );
          }
        }
        return const SizedBox();
      },
    );
  }
}
