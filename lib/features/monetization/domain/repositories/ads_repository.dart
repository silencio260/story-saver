import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';

abstract class AdsBaseRepo {
  Future<Either<Failure, Unit>> loadInterstitial();

  Future<Either<Failure, bool>> showInterstitial();

  Future<Either<Failure, Unit>> dispose();
}
