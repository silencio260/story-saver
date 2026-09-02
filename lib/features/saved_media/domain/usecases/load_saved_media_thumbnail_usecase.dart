import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/base_usecase.dart';
import '../repositories/saved_media_repository.dart';

class LoadSavedMediaThumbnailUseCase extends BaseUseCase<Uint8List, String> {
  const LoadSavedMediaThumbnailUseCase({required SavedMediaBaseRepo repo})
    : _repo = repo;

  final SavedMediaBaseRepo _repo;

  @override
  Future<Either<Failure, Uint8List>> call(String id) => _repo.loadThumbnail(id);
}
