import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:storysaver/features/analytics/data/services/analytics_service.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/saved_media.dart';
import '../../domain/entities/saved_media_page_result.dart';
import '../../domain/repositories/saved_media_repository.dart';
import '../datasources/local/saved_media_local_data_source.dart';

class SavedMediaRepo implements SavedMediaBaseRepo {
  const SavedMediaRepo({required SavedMediaBaseLocalDataSource localDataSource})
    : _localDataSource = localDataSource;

  final SavedMediaBaseLocalDataSource _localDataSource;

  @override
  Future<Either<Failure, SavedMediaPageResult>> load({
    required bool reset,
  }) async {
    try {
      final page = await _localDataSource.load(reset: reset);
      await AnalyticsService.track('saved_media_loaded', {
        'count': page.items.length,
        'reset': reset,
      });
      return Right(
        SavedMediaPageResult(
          items: page.items.map((model) => model.toDomain()).toList(),
          hasMore: page.hasMore,
        ),
      );
    } catch (error) {
      await AnalyticsService.track('saved_media_load_failed');
      return Left(ErrorHandler.handle(error));
    }
  }

  @override
  Future<Either<Failure, String>> resolveFilePath(String id) =>
      _guard(() => _localDataSource.resolveFilePath(id));

  @override
  Future<Either<Failure, Uint8List>> loadThumbnail(String id) =>
      _guard(() => _localDataSource.loadThumbnail(id));

  @override
  Future<Either<Failure, Unit>> delete(String id) => _guardUnit(
    () => _localDataSource.delete(id),
    event: 'delete_saved_media',
  );

  @override
  Future<Either<Failure, Unit>> deleteAll() =>
      _guardUnit(_localDataSource.deleteAll, event: 'delete_all_saved_media');

  @override
  Future<Either<Failure, bool>> saveStatus(String sourcePath) =>
      _saveTracked(sourcePath);

  @override
  Future<Either<Failure, bool>> isStatusSaved(String sourcePath) =>
      _guard(() => _localDataSource.isStatusSaved(sourcePath));

  @override
  Future<Either<Failure, Unit>> share(String path) =>
      _guardUnit(() => _localDataSource.share(path), event: 'share_media');

  Future<Either<Failure, bool>> _saveTracked(String path) async {
    await AnalyticsService.track('save_status_requested', {'source': 'manual'});
    final result = await _guard(() => _localDataSource.saveStatus(path));
    await AnalyticsService.track(
      result.fold((_) => false, (saved) => saved)
          ? 'save_status'
          : 'save_status_failed',
      {'source': 'manual'},
    );
    return result;
  }

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() operation) async {
    try {
      return Right(await operation());
    } catch (error) {
      return Left(ErrorHandler.handle(error));
    }
  }

  Future<Either<Failure, Unit>> _guardUnit(
    Future<void> Function() operation, {
    required String event,
  }) async {
    await AnalyticsService.track("${event}_requested");
    try {
      await operation();
      await AnalyticsService.track(event);
      return const Right(unit);
    } catch (error) {
      await AnalyticsService.track("${event}_failed");
      return Left(ErrorHandler.handle(error));
    }
  }
}
