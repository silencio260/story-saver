import 'package:dartz/dartz.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failure.dart';
import '../../domain/repositories/ads_repository.dart';
import '../datasources/ads_base_remote_data_source.dart';

class AdsRepo implements AdsBaseRepo {
  const AdsRepo({required AdsBaseRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final AdsBaseRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, Unit>> loadInterstitial() =>
      _guardUnit(_remoteDataSource.loadInterstitial);

  @override
  Future<Either<Failure, bool>> showInterstitial() async {
    try {
      return Right(await _remoteDataSource.showInterstitial());
    } catch (error) {
      return Left(ErrorHandler.handle(error));
    }
  }

  @override
  Future<Either<Failure, Unit>> dispose() =>
      _guardUnit(_remoteDataSource.dispose);

  Future<Either<Failure, Unit>> _guardUnit(
    Future<void> Function() operation,
  ) async {
    try {
      await operation();
      return const Right(unit);
    } catch (error) {
      return Left(ErrorHandler.handle(error));
    }
  }
}
