import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/base_usecase.dart';
import '../repositories/saved_media_repository.dart';

class SaveStatusUseCase extends BaseUseCase<bool, String> {
  const SaveStatusUseCase({required SavedMediaBaseRepo repo}) : _repo = repo;

  final SavedMediaBaseRepo _repo;

  @override
  Future<Either<Failure, bool>> call(String sourcePath) =>
      _repo.saveStatus(sourcePath);
}
