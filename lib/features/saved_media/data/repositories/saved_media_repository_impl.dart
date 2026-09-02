import 'dart:typed_data';

import 'package:dartz/dartz.dart';

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
      return Right(
        SavedMediaPageResult(
          items: page.items.map((model) => model.toDomain()).toList(),
          hasMore: page.hasMore,
        ),
      );
    } catch (error) {
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
  Future<Either<Failure, Unit>> delete(String id) =>
      _guardUnit(() => _localDataSource.delete(id));

  @override
  Future<Either<Failure, Unit>> deleteAll() =>
      _guardUnit(_localDataSource.deleteAll);

  @override
  Future<Either<Failure, bool>> saveStatus(String sourcePath) =>
      _guard(() => _localDataSource.saveStatus(sourcePath));

  @override
  Future<Either<Failure, bool>> isStatusSaved(String sourcePath) =>
      _guard(() => _localDataSource.isStatusSaved(sourcePath));

  @override
  Future<Either<Failure, Unit>> share(String path) =>
      _guardUnit(() => _localDataSource.share(path));

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() operation) async {
    try {
      return Right(await operation());
    } catch (error) {
      return Left(ErrorHandler.handle(error));
    }
  }

  Future<Either<Failure, Unit>> _guardUnit(
    Future<void> Function() operation,
  ) async {
    try {
      await operation();
      return const Right(unit);
    } catch (error) {
      return Left(ErrorHandler.handle(error));
    }
  }
}
