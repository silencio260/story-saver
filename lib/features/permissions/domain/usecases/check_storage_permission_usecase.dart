import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/base_usecase.dart';
import '../repositories/permission_repository.dart';

class CheckStoragePermissionUseCase extends BaseUseCase<bool, NoParams> {
  const CheckStoragePermissionUseCase({required PermissionBaseRepo repo})
    : _repo = repo;

  final PermissionBaseRepo _repo;

  @override
  Future<Either<Failure, bool>> call(NoParams params) =>
      _repo.checkStoragePermission();
}
