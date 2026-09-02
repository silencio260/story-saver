import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/app_settings.dart';

abstract class SettingsBaseRepo {
  Future<Either<Failure, AppSettings>> load();

  Future<Either<Failure, AppSettings>> setAutoSave(bool enabled);

  Future<Either<Failure, Unit>> shareApp();

  Future<Either<Failure, Unit>> rateApp();

  Future<Either<Failure, Unit>> contactSupport();
}
