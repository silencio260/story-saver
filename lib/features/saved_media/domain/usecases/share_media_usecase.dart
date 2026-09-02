import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/base_usecase.dart';
import '../repositories/saved_media_repository.dart';

class ShareMediaUseCase extends BaseUseCase<Unit, String> {
  const ShareMediaUseCase({required SavedMediaBaseRepo repo}) : _repo = repo;

  final SavedMediaBaseRepo _repo;

  @override
  Future<Either<Failure, Unit>> call(String path) => _repo.share(path);
}
