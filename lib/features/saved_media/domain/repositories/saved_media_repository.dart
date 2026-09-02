import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/saved_media.dart';
import '../entities/saved_media_page_result.dart';

abstract class SavedMediaBaseRepo {
  Future<Either<Failure, SavedMediaPageResult>> load({required bool reset});

  Future<Either<Failure, String>> resolveFilePath(String id);

  Future<Either<Failure, Uint8List>> loadThumbnail(String id);

  Future<Either<Failure, Unit>> delete(String id);

  Future<Either<Failure, Unit>> deleteAll();

  Future<Either<Failure, bool>> saveStatus(String sourcePath);

  Future<Either<Failure, bool>> isStatusSaved(String sourcePath);

  Future<Either<Failure, Unit>> share(String path);
}
