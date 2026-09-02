import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';

abstract class PermissionBaseRepo {
  Future<Either<Failure, bool>> checkStoragePermission();

  Future<Either<Failure, bool>> requestStoragePermission();

  Future<Either<Failure, bool>> checkStatusFolderPermission({
    required bool isBusinessMode,
  });

  Future<Either<Failure, Unit>> requestStatusFolderPermission({
    required bool isBusinessMode,
  });
}
