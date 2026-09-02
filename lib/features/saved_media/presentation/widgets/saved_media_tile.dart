import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/saved_media.dart';
import '../bloc/saved_media_bloc/saved_media_bloc.dart';

class SavedMediaTile extends StatefulWidget {
  const SavedMediaTile({
    required this.media,
    required this.onTap,
    required this.onDelete,
    super.key,
  });

  final SavedMedia media;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  State<SavedMediaTile> createState() => _SavedMediaTileState();
}

class _SavedMediaTileState extends State<SavedMediaTile> {
  @override
  void initState() {
    super.initState();
    context.read<SavedMediaBloc>().add(
      SavedMediaThumbnailRequested(widget.media.id),
    );
  }

  @override
  Widget build(BuildContext context) => Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
    child: Column(
      children: <Widget>[
        Expanded(
          child: GestureDetector(
            onTap: widget.onTap,
            child: BlocBuilder<SavedMediaBloc, SavedMediaState>(
              buildWhen:
                  (previous, current) =>
                      previous.thumbnails[widget.media.id] !=
                          current.thumbnails[widget.media.id] ||
                      previous.thumbnailFailures.contains(widget.media.id) !=
                          current.thumbnailFailures.contains(widget.media.id),
              builder: (context, state) {
                final bytes = state.thumbnails[widget.media.id];
                if (bytes == null) {
                  if (state.thumbnailFailures.contains(widget.media.id)) {
                    return const Center(
                      child: Icon(Icons.broken_image, color: Colors.grey),
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                }
                return Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    Image.memory(bytes, fit: BoxFit.cover),
                    if (widget.media.isVideo)
                      const Positioned(
                        top: 10,
                        right: 10,
                        child: Icon(
                          Icons.videocam_sharp,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
        GestureDetector(
          onTap: widget.onDelete,
          child: const Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: EdgeInsets.all(3),
              child: Icon(Icons.delete, color: Colors.black, size: 20),
            ),
          ),
        ),
      ],
    ),
  );
}
