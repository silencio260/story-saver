import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/base_usecase.dart';
import '../repositories/permission_repository.dart';
import 'permission_check_params.dart';

class CheckStatusFolderPermissionUseCase
    extends BaseUseCase<bool, PermissionCheckParams> {
  const CheckStatusFolderPermissionUseCase({required PermissionBaseRepo repo})
    : _repo = repo;

  final PermissionBaseRepo _repo;

  @override
  Future<Either<Failure, bool>> call(PermissionCheckParams params) =>
      _repo.checkStatusFolderPermission(isBusinessMode: params.isBusinessMode);
}
