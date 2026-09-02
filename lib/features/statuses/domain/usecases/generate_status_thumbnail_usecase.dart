import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/base_usecase.dart';
import '../repositories/status_repository.dart';

class GenerateStatusThumbnailUseCase extends BaseUseCase<String, String> {
  const GenerateStatusThumbnailUseCase({required StatusBaseRepo statusRepo})
    : _statusRepo = statusRepo;

  final StatusBaseRepo _statusRepo;

  @override
  Future<Either<Failure, String>> call(String params) =>
      _statusRepo.generateVideoThumbnail(params);
}
