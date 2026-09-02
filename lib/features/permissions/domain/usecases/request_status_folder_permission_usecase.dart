import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/base_usecase.dart';
import '../repositories/permission_repository.dart';
import 'permission_check_params.dart';

class RequestStatusFolderPermissionUseCase
    extends BaseUseCase<Unit, PermissionCheckParams> {
  const RequestStatusFolderPermissionUseCase({required PermissionBaseRepo repo})
    : _repo = repo;

  final PermissionBaseRepo _repo;

  @override
  Future<Either<Failure, Unit>> call(PermissionCheckParams params) => _repo
      .requestStatusFolderPermission(isBusinessMode: params.isBusinessMode);
}
