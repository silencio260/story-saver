part of 'saved_media_bloc.dart';

enum SavedMediaViewStatus { initial, loading, success, failure }

class SavedMediaState extends Equatable {
  const SavedMediaState({
    this.status = SavedMediaViewStatus.initial,
    this.items = const <SavedMedia>[],
    this.hasMore = true,
    this.isLoadingMore = false,
    this.thumbnails = const <String, Uint8List>{},
    this.thumbnailFailures = const <String>{},
    this.savedSourcePaths = const <String>{},
    this.resolvedPath,
    this.resolvedIsVideo = false,
    this.resolvedGalleryPaths = const <String>[],
    this.resolvedGalleryVideoFlags = const <bool>[],
    this.resolvedGalleryInitialIndex = 0,
    this.message,
  });

  final SavedMediaViewStatus status;
  final List<SavedMedia> items;
  final bool hasMore;
  final bool isLoadingMore;
  final Map<String, Uint8List> thumbnails;
  final Set<String> thumbnailFailures;
  final Set<String> savedSourcePaths;
  final String? resolvedPath;
  final bool resolvedIsVideo;
  final List<String> resolvedGalleryPaths;
  final List<bool> resolvedGalleryVideoFlags;
  final int resolvedGalleryInitialIndex;
  final String? message;

  bool get isLoading => status == SavedMediaViewStatus.loading;

  SavedMediaState copyWith({
    SavedMediaViewStatus? status,
    List<SavedMedia>? items,
    bool? hasMore,
    bool? isLoadingMore,
    Map<String, Uint8List>? thumbnails,
    Set<String>? thumbnailFailures,
    Set<String>? savedSourcePaths,
    String? resolvedPath,
    bool? resolvedIsVideo,
    List<String>? resolvedGalleryPaths,
    List<bool>? resolvedGalleryVideoFlags,
    int? resolvedGalleryInitialIndex,
    String? message,
    bool clearMessage = false,
    bool clearResolvedMedia = false,
  }) => SavedMediaState(
    status: status ?? this.status,
    items: items ?? this.items,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    thumbnails: thumbnails ?? this.thumbnails,
    thumbnailFailures: thumbnailFailures ?? this.thumbnailFailures,
    savedSourcePaths: savedSourcePaths ?? this.savedSourcePaths,
    resolvedPath: clearResolvedMedia ? null : resolvedPath ?? this.resolvedPath,
    resolvedIsVideo:
        clearResolvedMedia ? false : resolvedIsVideo ?? this.resolvedIsVideo,
    resolvedGalleryPaths:
        clearResolvedMedia
            ? const <String>[]
            : resolvedGalleryPaths ?? this.resolvedGalleryPaths,
    resolvedGalleryVideoFlags:
        clearResolvedMedia
            ? const <bool>[]
            : resolvedGalleryVideoFlags ?? this.resolvedGalleryVideoFlags,
    resolvedGalleryInitialIndex:
        clearResolvedMedia
            ? 0
            : resolvedGalleryInitialIndex ?? this.resolvedGalleryInitialIndex,
    message: clearMessage ? null : message ?? this.message,
  );

  @override
  List<Object?> get props => <Object?>[
    status,
    items,
    hasMore,
    isLoadingMore,
    thumbnails,
    thumbnailFailures,
    savedSourcePaths,
    resolvedPath,
    resolvedIsVideo,
    resolvedGalleryPaths,
    resolvedGalleryVideoFlags,
    resolvedGalleryInitialIndex,
    message,
  ];
}
