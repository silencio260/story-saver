import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/usecase/base_usecase.dart';
import '../../../domain/entities/saved_media.dart';
import '../../../domain/usecases/delete_all_saved_media_usecase.dart';
import '../../../domain/usecases/delete_saved_media_usecase.dart';
import '../../../domain/usecases/load_saved_media_usecase.dart';
import '../../../domain/usecases/is_status_saved_usecase.dart';
import '../../../domain/usecases/load_saved_media_thumbnail_usecase.dart';
import '../../../domain/usecases/resolve_saved_media_usecase.dart';
import '../../../domain/usecases/save_status_usecase.dart';
import '../../../domain/usecases/share_media_usecase.dart';
import '../../l10n/saved_media_strings.dart';

part 'saved_media_event.dart';
part 'saved_media_state.dart';

class SavedMediaBloc extends Bloc<SavedMediaEvent, SavedMediaState> {
  SavedMediaBloc({
    required LoadSavedMediaUseCase loadSavedMediaUseCase,
    required DeleteSavedMediaUseCase deleteSavedMediaUseCase,
    required DeleteAllSavedMediaUseCase deleteAllSavedMediaUseCase,
    required SaveStatusUseCase saveStatusUseCase,
    required IsStatusSavedUseCase isStatusSavedUseCase,
    required ResolveSavedMediaPathUseCase resolveSavedMediaPathUseCase,
    required LoadSavedMediaThumbnailUseCase loadSavedMediaThumbnailUseCase,
    required ShareMediaUseCase shareMediaUseCase,
  }) : _loadSavedMedia = loadSavedMediaUseCase,
       _deleteSavedMedia = deleteSavedMediaUseCase,
       _deleteAllSavedMedia = deleteAllSavedMediaUseCase,
       _saveStatus = saveStatusUseCase,
       _isStatusSaved = isStatusSavedUseCase,
       _resolveSavedMediaPath = resolveSavedMediaPathUseCase,
       _loadSavedMediaThumbnail = loadSavedMediaThumbnailUseCase,
       _shareMedia = shareMediaUseCase,
       super(const SavedMediaState()) {
    on<SavedMediaLoadRequested>(_onLoadRequested);
    on<SavedMediaMoreRequested>(_onMoreRequested);
    on<SavedMediaDeleteRequested>(_onDeleteRequested);
    on<SavedMediaDeleteAllRequested>(_onDeleteAllRequested);
    on<StatusSaveRequested>(_onStatusSaveRequested);
    on<StatusSavedCheckRequested>(_onStatusSavedCheckRequested);
    on<SavedMediaOpenRequested>(_onOpenRequested);
    on<SavedMediaGalleryOpenRequested>(_onGalleryOpenRequested);
    on<SavedMediaNavigationHandled>(_onNavigationHandled);
    on<SavedMediaThumbnailRequested>(_onThumbnailRequested);
    on<MediaShareRequested>(_onShareRequested);
  }

  final LoadSavedMediaUseCase _loadSavedMedia;
  final DeleteSavedMediaUseCase _deleteSavedMedia;
  final DeleteAllSavedMediaUseCase _deleteAllSavedMedia;
  final SaveStatusUseCase _saveStatus;
  final IsStatusSavedUseCase _isStatusSaved;
  final ResolveSavedMediaPathUseCase _resolveSavedMediaPath;
  final LoadSavedMediaThumbnailUseCase _loadSavedMediaThumbnail;
  final ShareMediaUseCase _shareMedia;

  Future<void> _onLoadRequested(
    SavedMediaLoadRequested event,
    Emitter<SavedMediaState> emit,
  ) async {
    emit(
      state.copyWith(status: SavedMediaViewStatus.loading, clearMessage: true),
    );
    final result = await _loadSavedMedia(true);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: SavedMediaViewStatus.failure,
          message: failure.message,
        ),
      ),
      (page) => emit(
        state.copyWith(
          status: SavedMediaViewStatus.success,
          items: page.items,
          hasMore: page.hasMore,
          clearMessage: true,
        ),
      ),
    );
  }

  Future<void> _onMoreRequested(
    SavedMediaMoreRequested event,
    Emitter<SavedMediaState> emit,
  ) async {
    if (!state.hasMore || state.isLoadingMore) return;
    emit(state.copyWith(isLoadingMore: true, clearMessage: true));
    final result = await _loadSavedMedia(false);
    result.fold(
      (failure) =>
          emit(state.copyWith(isLoadingMore: false, message: failure.message)),
      (page) => emit(
        state.copyWith(
          status: SavedMediaViewStatus.success,
          items: page.items,
          hasMore: page.hasMore,
          isLoadingMore: false,
          clearMessage: true,
        ),
      ),
    );
  }

  Future<void> _onDeleteRequested(
    SavedMediaDeleteRequested event,
    Emitter<SavedMediaState> emit,
  ) async {
    final result = await _deleteSavedMedia(event.id);
    result.fold(
      (failure) => emit(state.copyWith(message: failure.message)),
      (_) => emit(
        state.copyWith(
          items: state.items.where((item) => item.id != event.id).toList(),
          message: SavedMediaStrings.deleted,
        ),
      ),
    );
  }

  Future<void> _onDeleteAllRequested(
    SavedMediaDeleteAllRequested event,
    Emitter<SavedMediaState> emit,
  ) async {
    final result = await _deleteAllSavedMedia(NoParams.instance);
    result.fold(
      (failure) => emit(state.copyWith(message: failure.message)),
      (_) => emit(
        state.copyWith(
          items: const <SavedMedia>[],
          hasMore: false,
          message: SavedMediaStrings.allDeleted,
        ),
      ),
    );
  }

  Future<void> _onStatusSaveRequested(
    StatusSaveRequested event,
    Emitter<SavedMediaState> emit,
  ) async {
    final result = await _saveStatus(event.sourcePath);
    await result.fold(
      (failure) async => emit(state.copyWith(message: failure.message)),
      (saved) async {
        emit(
          state.copyWith(
            message:
                saved ? SavedMediaStrings.saved : SavedMediaStrings.notSaved,
          ),
        );
        if (saved) add(const SavedMediaLoadRequested());
        if (saved) {
          emit(
            state.copyWith(
              savedSourcePaths: <String>{
                ...state.savedSourcePaths,
                event.sourcePath,
              },
            ),
          );
        }
      },
    );
  }

  Future<void> _onStatusSavedCheckRequested(
    StatusSavedCheckRequested event,
    Emitter<SavedMediaState> emit,
  ) async {
    final result = await _isStatusSaved(event.sourcePath);
    result.fold(
      (_) => null,
      (saved) => emit(
        state.copyWith(
          savedSourcePaths:
              saved
                  ? <String>{...state.savedSourcePaths, event.sourcePath}
                  : <String>{
                    ...state.savedSourcePaths.where(
                      (path) => path != event.sourcePath,
                    ),
                  },
        ),
      ),
    );
  }

  Future<void> _onOpenRequested(
    SavedMediaOpenRequested event,
    Emitter<SavedMediaState> emit,
  ) async {
    final result = await _resolveSavedMediaPath(event.id);
    result.fold(
      (failure) => emit(state.copyWith(message: failure.message)),
      (path) => emit(
        state.copyWith(
          resolvedPath: path,
          resolvedIsVideo: event.isVideo,
          clearMessage: true,
        ),
      ),
    );
  }

  Future<void> _onGalleryOpenRequested(
    SavedMediaGalleryOpenRequested event,
    Emitter<SavedMediaState> emit,
  ) async {
    final paths = <String>[];
    final videoFlags = <bool>[];
    var adjustedInitialIndex = event.initialIndex;

    for (var index = 0; index < state.items.length; index++) {
      final item = state.items[index];
      final result = await _resolveSavedMediaPath(item.id);
      final path = result.fold<String?>((failure) => null, (value) => value);
      if (path == null) {
        if (index < event.initialIndex) adjustedInitialIndex--;
        continue;
      }
      paths.add(path);
      videoFlags.add(item.isVideo);
    }

    if (paths.isEmpty) {
      emit(state.copyWith(message: SavedMediaStrings.mediaUnavailable));
      return;
    }
    emit(
      state.copyWith(
        resolvedGalleryPaths: paths,
        resolvedGalleryVideoFlags: videoFlags,
        resolvedGalleryInitialIndex:
            adjustedInitialIndex.clamp(0, paths.length - 1).toInt(),
        clearMessage: true,
      ),
    );
  }

  void _onNavigationHandled(
    SavedMediaNavigationHandled event,
    Emitter<SavedMediaState> emit,
  ) {
    emit(state.copyWith(clearResolvedMedia: true));
  }

  Future<void> _onThumbnailRequested(
    SavedMediaThumbnailRequested event,
    Emitter<SavedMediaState> emit,
  ) async {
    if (state.thumbnails.containsKey(event.id) ||
        state.thumbnailFailures.contains(event.id)) {
      return;
    }
    final result = await _loadSavedMediaThumbnail(event.id);
    result.fold(
      (_) => emit(
        state.copyWith(
          thumbnailFailures: <String>{...state.thumbnailFailures, event.id},
        ),
      ),
      (bytes) => emit(
        state.copyWith(
          thumbnails: <String, Uint8List>{...state.thumbnails, event.id: bytes},
        ),
      ),
    );
  }

  Future<void> _onShareRequested(
    MediaShareRequested event,
    Emitter<SavedMediaState> emit,
  ) async {
    final result = await _shareMedia(event.path);
    result.fold(
      (failure) => emit(state.copyWith(message: failure.message)),
      (_) => emit(state.copyWith(clearMessage: true)),
    );
  }
}
