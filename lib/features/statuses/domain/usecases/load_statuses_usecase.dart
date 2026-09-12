import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/base_usecase.dart';
import '../entities/status_collection.dart';
import '../repositories/status_repository.dart';

class LoadStatusesUseCase extends BaseUseCase<StatusCollection, NoParams> {
  const LoadStatusesUseCase({required StatusBaseRepo statusRepo})
    : _statusRepo = statusRepo;

  final StatusBaseRepo _statusRepo;

  Future<Either<Failure, StatusCollection>> load({
    void Function(StatusCollection)? onProgress,
  }) => _statusRepo.loadStatuses(onProgress: onProgress);

  @override
  Future<Either<Failure, StatusCollection>> call(NoParams params) =>
      _statusRepo.loadStatuses();
}
