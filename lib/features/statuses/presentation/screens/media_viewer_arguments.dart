class MediaViewerArguments {
  const MediaViewerArguments({
    required this.paths,
    required this.initialIndex,
    required this.isVideo,
    this.allowSave = true,
    this.videoFlags,
  });

  final List<String> paths;
  final int initialIndex;
  final bool isVideo;
  final bool allowSave;
  final List<bool>? videoFlags;

  bool isVideoAt(int index) => videoFlags?[index] ?? isVideo;
}
