import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/base_usecase.dart';
import '../repositories/status_repository.dart';

class SetBusinessModeUseCase extends BaseUseCase<bool, bool> {
  const SetBusinessModeUseCase({required StatusBaseRepo statusRepo})
    : _statusRepo = statusRepo;

  final StatusBaseRepo _statusRepo;

  @override
  Future<Either<Failure, bool>> call(bool params) =>
      _statusRepo.setBusinessMode(params);
}
