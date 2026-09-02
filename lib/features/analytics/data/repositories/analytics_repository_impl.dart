import 'package:dartz/dartz.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/analytics_event.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../datasources/analytics_remote_data_source.dart';

class AnalyticsRepo implements AnalyticsBaseRepo {
  const AnalyticsRepo({required AnalyticsBaseRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final AnalyticsBaseRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, Unit>> initialize() =>
      _guard(_remoteDataSource.initialize);

  @override
  Future<Either<Failure, Unit>> log(AnalyticsEventEntity event) =>
      _guard(() => _remoteDataSource.log(event));

  Future<Either<Failure, Unit>> _guard(
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
