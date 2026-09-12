import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/status_collection.dart';

abstract class StatusBaseRepo {
  Future<Either<Failure, StatusCollection>> loadStatuses({
    void Function(StatusCollection)? onProgress,
  });

  Future<Either<Failure, bool>> getBusinessMode();

  Future<Either<Failure, bool>> setBusinessMode(bool enabled);

  Future<Either<Failure, Unit>> clearCache();

  Future<Either<Failure, String>> generateVideoThumbnail(String videoPath);
}
