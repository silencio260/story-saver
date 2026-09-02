import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/base_usecase.dart';
import '../repositories/saved_media_repository.dart';

class ResolveSavedMediaPathUseCase extends BaseUseCase<String, String> {
  const ResolveSavedMediaPathUseCase({required SavedMediaBaseRepo repo})
    : _repo = repo;

  final SavedMediaBaseRepo _repo;

  @override
  Future<Either<Failure, String>> call(String id) => _repo.resolveFilePath(id);
}
