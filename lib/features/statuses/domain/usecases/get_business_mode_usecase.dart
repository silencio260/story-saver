import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/base_usecase.dart';
import '../repositories/status_repository.dart';

class GetBusinessModeUseCase extends BaseUseCase<bool, NoParams> {
  const GetBusinessModeUseCase({required StatusBaseRepo statusRepo})
    : _statusRepo = statusRepo;

  final StatusBaseRepo _statusRepo;

  @override
  Future<Either<Failure, bool>> call(NoParams params) =>
      _statusRepo.getBusinessMode();
}
