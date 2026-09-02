part of 'saved_media_bloc.dart';

sealed class SavedMediaEvent extends Equatable {
  const SavedMediaEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

class SavedMediaLoadRequested extends SavedMediaEvent {
  const SavedMediaLoadRequested();
}

class SavedMediaMoreRequested extends SavedMediaEvent {
  const SavedMediaMoreRequested();
}

class SavedMediaDeleteRequested extends SavedMediaEvent {
  const SavedMediaDeleteRequested(this.id);

  final String id;

  @override
  List<Object?> get props => <Object?>[id];
}

class SavedMediaDeleteAllRequested extends SavedMediaEvent {
  const SavedMediaDeleteAllRequested();
}

class StatusSaveRequested extends SavedMediaEvent {
  const StatusSaveRequested(this.sourcePath);

  final String sourcePath;

  @override
  List<Object?> get props => <Object?>[sourcePath];
}

class StatusSavedCheckRequested extends SavedMediaEvent {
  const StatusSavedCheckRequested(this.sourcePath);

  final String sourcePath;

  @override
  List<Object?> get props => <Object?>[sourcePath];
}

class SavedMediaOpenRequested extends SavedMediaEvent {
  const SavedMediaOpenRequested({required this.id, required this.isVideo});

  final String id;
  final bool isVideo;

  @override
  List<Object?> get props => <Object?>[id, isVideo];
}

class SavedMediaGalleryOpenRequested extends SavedMediaEvent {
  const SavedMediaGalleryOpenRequested(this.initialIndex);

  final int initialIndex;

  @override
  List<Object?> get props => <Object?>[initialIndex];
}

class SavedMediaNavigationHandled extends SavedMediaEvent {
  const SavedMediaNavigationHandled();
}

class SavedMediaThumbnailRequested extends SavedMediaEvent {
  const SavedMediaThumbnailRequested(this.id);

  final String id;

  @override
  List<Object?> get props => <Object?>[id];
}

class MediaShareRequested extends SavedMediaEvent {
  const MediaShareRequested(this.path);

  final String path;

  @override
  List<Object?> get props => <Object?>[path];
}
