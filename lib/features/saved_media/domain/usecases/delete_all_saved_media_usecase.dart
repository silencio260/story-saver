import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/base_usecase.dart';
import '../repositories/saved_media_repository.dart';

class DeleteAllSavedMediaUseCase extends BaseUseCase<Unit, NoParams> {
  const DeleteAllSavedMediaUseCase({required SavedMediaBaseRepo repo})
    : _repo = repo;

  final SavedMediaBaseRepo _repo;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) => _repo.deleteAll();
}
