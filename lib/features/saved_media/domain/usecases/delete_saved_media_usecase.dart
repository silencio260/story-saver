import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../repositories/saved_media_repository.dart';
import '../../../../core/usecase/base_usecase.dart';

class DeleteSavedMediaUseCase extends BaseUseCase<Unit, String> {
  const DeleteSavedMediaUseCase({required SavedMediaBaseRepo repo})
    : _repo = repo;

  final SavedMediaBaseRepo _repo;

  @override
  Future<Either<Failure, Unit>> call(String id) => _repo.delete(id);
}
