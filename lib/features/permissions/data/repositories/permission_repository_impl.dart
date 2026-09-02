import 'package:dartz/dartz.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failure.dart';
import '../../domain/repositories/permission_repository.dart';
import '../datasources/permission_local_data_source.dart';

class PermissionRepo implements PermissionBaseRepo {
  const PermissionRepo({required PermissionBaseLocalDataSource localDataSource})
    : _localDataSource = localDataSource;

  final PermissionBaseLocalDataSource _localDataSource;

  @override
  Future<Either<Failure, bool>> checkStoragePermission() =>
      _guard(_localDataSource.checkStoragePermission);

  @override
  Future<Either<Failure, bool>> requestStoragePermission() =>
      _guard(_localDataSource.requestStoragePermission);

  @override
  Future<Either<Failure, bool>> checkStatusFolderPermission({
    required bool isBusinessMode,
  }) => _guard(
    () => _localDataSource.checkStatusFolderPermission(
      isBusinessMode: isBusinessMode,
    ),
  );

  @override
  Future<Either<Failure, Unit>> requestStatusFolderPermission({
    required bool isBusinessMode,
  }) async {
    try {
      await _localDataSource.requestStatusFolderPermission(
        isBusinessMode: isBusinessMode,
      );
      return const Right(unit);
    } catch (error) {
      return Left(ErrorHandler.handle(error));
    }
  }

  Future<Either<Failure, bool>> _guard(
    Future<bool> Function() operation,
  ) async {
    try {
      return Right(await operation());
    } catch (error) {
      return Left(ErrorHandler.handle(error));
    }
  }
}
