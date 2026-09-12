import 'package:dartz/dartz.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/status_collection.dart';
import '../../domain/repositories/status_repository.dart';
import '../datasources/local/status_local_data_source.dart';

class StatusRepo implements StatusBaseRepo {
  const StatusRepo({required StatusBaseLocalDataSource localDataSource})
    : _localDataSource = localDataSource;

  final StatusBaseLocalDataSource _localDataSource;

  @override
  Future<Either<Failure, StatusCollection>> loadStatuses({
    void Function(StatusCollection)? onProgress,
  }) async {
    try {
      return Right(await _localDataSource.loadStatuses(onProgress: onProgress));
    } catch (error) {
      return Left(ErrorHandler.handle(error));
    }
  }

  @override
  Future<Either<Failure, bool>> getBusinessMode() async {
    try {
      return Right(await _localDataSource.getBusinessMode());
    } catch (error) {
      return Left(ErrorHandler.handle(error));
    }
  }

  @override
  Future<Either<Failure, bool>> setBusinessMode(bool enabled) async {
    try {
      return Right(await _localDataSource.setBusinessMode(enabled));
    } catch (error) {
      return Left(ErrorHandler.handle(error));
    }
  }

  @override
  Future<Either<Failure, Unit>> clearCache() async {
    try {
      await _localDataSource.clearCache();
      return const Right(unit);
    } catch (error) {
      return Left(ErrorHandler.handle(error));
    }
  }

  @override
  Future<Either<Failure, String>> generateVideoThumbnail(
    String videoPath,
  ) async {
    try {
      return Right(await _localDataSource.generateVideoThumbnail(videoPath));
    } catch (error) {
      return Left(ErrorHandler.handle(error));
    }
  }
}
