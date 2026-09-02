import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/base_usecase.dart';
import '../entities/saved_media_page_result.dart';
import '../repositories/saved_media_repository.dart';

class LoadSavedMediaUseCase extends BaseUseCase<SavedMediaPageResult, bool> {
  const LoadSavedMediaUseCase({required SavedMediaBaseRepo repo})
    : _repo = repo;

  final SavedMediaBaseRepo _repo;

  @override
  Future<Either<Failure, SavedMediaPageResult>> call(bool reset) =>
      _repo.load(reset: reset);
}
