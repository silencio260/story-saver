

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class VideoThumbnailWidget extends StatefulWidget {
  final AssetEntity video;

  const VideoThumbnailWidget({required this.video, Key? key}) : super(key: key);

  @override
  _VideoThumbnailWidgetState createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  Future<dynamic>? _thumbnailFuture;

  @override
  void initState() {
    super.initState();
    // Cache the Future in initState
    _thumbnailFuture = _getThumbnail();
  }

  Future<dynamic> _getThumbnail() async {
    if (widget.video.type == AssetType.video) {
      return widget.video.thumbnailData; // Fetch video thumbnail
    } else {
      return widget.video.file; // Fetch video file
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: _thumbnailFuture, // Use cached Future
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Icon(Icons.error));
        } else if (snapshot.hasData) {
          // If video thumbnail, display it
          if (widget.video.type == AssetType.video) {
            return Image.memory(
              snapshot.data!,
              fit: BoxFit.cover,
            );
          } else {
            // If not a video, display file
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
