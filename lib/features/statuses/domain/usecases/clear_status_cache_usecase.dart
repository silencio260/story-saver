import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/base_usecase.dart';
import '../repositories/status_repository.dart';

class ClearStatusCacheUseCase extends BaseUseCase<Unit, NoParams> {
  const ClearStatusCacheUseCase({required StatusBaseRepo statusRepo})
    : _statusRepo = statusRepo;

  final StatusBaseRepo _statusRepo;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) =>
      _statusRepo.clearCache();
}
