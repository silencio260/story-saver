import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:storysaver/features/analytics/data/services/analytics_service.dart';

import '../../../../../core/usecase/base_usecase.dart';
import '../../../domain/entities/status_collection.dart';
import '../../../domain/entities/status_media.dart';
import '../../../domain/usecases/clear_status_cache_usecase.dart';
import '../../../domain/usecases/generate_status_thumbnail_usecase.dart';
import '../../../domain/usecases/get_business_mode_usecase.dart';
import '../../../domain/usecases/load_statuses_usecase.dart';
import '../../../domain/usecases/set_business_mode_usecase.dart';

part 'status_event.dart';
part 'status_state.dart';

class StatusBloc extends Bloc<StatusEvent, StatusState> {
  StatusBloc({
    required LoadStatusesUseCase loadStatusesUseCase,
    required GetBusinessModeUseCase getBusinessModeUseCase,
    required SetBusinessModeUseCase setBusinessModeUseCase,
    required ClearStatusCacheUseCase clearStatusCacheUseCase,
    required GenerateStatusThumbnailUseCase generateStatusThumbnailUseCase,
  }) : _loadStatuses = loadStatusesUseCase,
       _getBusinessMode = getBusinessModeUseCase,
       _setBusinessMode = setBusinessModeUseCase,
       _clearStatusCache = clearStatusCacheUseCase,
       _generateStatusThumbnail = generateStatusThumbnailUseCase,
       super(const StatusState()) {
    on<StatusLoadRequested>(_onLoadRequested);
    on<StatusBusinessModeRequested>(_onBusinessModeRequested);
    on<StatusCacheClearRequested>(_onCacheClearRequested);
    on<StatusThumbnailRequested>(_onThumbnailRequested);
  }

  final LoadStatusesUseCase _loadStatuses;
  final GetBusinessModeUseCase _getBusinessMode;
  final SetBusinessModeUseCase _setBusinessMode;
  final ClearStatusCacheUseCase _clearStatusCache;
  final GenerateStatusThumbnailUseCase _generateStatusThumbnail;

  Completer<void>? _loadFinished;
  bool _loadInProgress = false;
  bool _reloadAfterLoad = false;
  int _sourceVersion = 0;

  Future<void> _onLoadRequested(
    StatusLoadRequested event,
    Emitter<StatusState> emit,
  ) async {
    // Permission checks and tab rebuilds can request the same load together.
    if (_loadInProgress) return;
    _loadInProgress = true;
    _loadFinished = Completer<void>();
    final sourceVersion = _sourceVersion;
    emit(state.copyWith(status: StatusViewStatus.loading, clearMessage: true));
    unawaited(AnalyticsService.track('statuses_load_requested'));
    try {
      final result = await _loadStatuses.load(
        onProgress: (collection) {
          if (!emit.isDone && sourceVersion == _sourceVersion) {
            emit(
              state.copyWith(
                collection: collection,
                status: StatusViewStatus.loading,
                clearMessage: true,
              ),
            );
          }
        },
      );
      if (emit.isDone || sourceVersion != _sourceVersion) return;
      result.fold(
        (failure) => emit(
          state.copyWith(
            status: StatusViewStatus.failure,
            message: failure.message,
          ),
        ),
        (collection) => emit(
          state.copyWith(
            status: StatusViewStatus.success,
            collection: collection,
            clearMessage: true,
          ),
        ),
      );
      // Display the result before waiting on any analytics SDK or disk queue.
      unawaited(
        result.fold(
          (_) => AnalyticsService.track('statuses_load_failed'),
          (collection) => AnalyticsService.track('statuses_loaded', {
            'image_count': collection.images.length,
            'video_count': collection.videos.length,
            'business_mode': collection.isBusinessMode,
          }),
        ),
      );
    } finally {
      _loadInProgress = false;
      _loadFinished?.complete();
      _loadFinished = null;
      if (_reloadAfterLoad && !isClosed) {
        _reloadAfterLoad = false;
        add(const StatusLoadRequested());
      }
    }
  }

  Future<void> _onBusinessModeRequested(
    StatusBusinessModeRequested event,
    Emitter<StatusState> emit,
  ) async {
    final result =
        event.enabled == null
            ? await _getBusinessMode(NoParams.instance)
            : await _setBusinessMode(event.enabled!);
    if (event.enabled != null) {
      await result.fold(
        (_) => AnalyticsService.track('business_mode_change_failed'),
        (enabled) => AnalyticsService.track(
          enabled ? 'switch_to_business_mode' : 'switch_to_normal_mode',
        ),
      );
    }
    result.fold((failure) => emit(state.copyWith(message: failure.message)), (
      isBusinessMode,
    ) {
      final current = state.collection;
      final changedSource = current.isBusinessMode != isBusinessMode;
      if (changedSource) {
        _sourceVersion++;
        if (_loadInProgress) _reloadAfterLoad = true;
      }
      emit(
        state.copyWith(
          collection: StatusCollection(
            images: changedSource ? const <StatusMedia>[] : current.images,
            videos: changedSource ? const <StatusMedia>[] : current.videos,
            isBusinessMode: isBusinessMode,
            isWhatsAppAvailable: current.isWhatsAppAvailable,
          ),
          clearMessage: true,
        ),
      );
      if (event.reloadStatuses) add(const StatusLoadRequested());
    });
  }

  Future<void> _onCacheClearRequested(
    StatusCacheClearRequested event,
    Emitter<StatusState> emit,
  ) async {
    _sourceVersion++;
    await _loadFinished?.future;
    final result = await _clearStatusCache(NoParams.instance);
    await result.fold(
      (_) => AnalyticsService.track('status_cache_clear_failed'),
      (_) => AnalyticsService.track('status_cache_cleared'),
    );
    result.fold(
      (failure) => emit(state.copyWith(message: failure.message)),
      (_) => emit(
        state.copyWith(
          collection: StatusCollection(
            images: const <StatusMedia>[],
            videos: const <StatusMedia>[],
            isBusinessMode: state.collection.isBusinessMode,
            isWhatsAppAvailable: state.collection.isWhatsAppAvailable,
          ),
          clearMessage: true,
        ),
      ),
    );
  }

  Future<void> _onThumbnailRequested(
    StatusThumbnailRequested event,
    Emitter<StatusState> emit,
  ) async {
    if (state.thumbnails.containsKey(event.videoPath) ||
        state.thumbnailFailures.contains(event.videoPath)) {
      return;
    }
    final result = await _generateStatusThumbnail(event.videoPath);
    result.fold(
      (_) => emit(
        state.copyWith(
          thumbnailFailures: <String>{
            ...state.thumbnailFailures,
            event.videoPath,
          },
        ),
      ),
      (thumbnail) => emit(
        state.copyWith(
          thumbnails: <String, String>{
            ...state.thumbnails,
            event.videoPath: thumbnail,
          },
        ),
      ),
    );
  }
}
