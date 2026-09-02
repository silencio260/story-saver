import 'package:dartz/dartz.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failure.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../datasources/onboarding_local_data_source.dart';

class OnboardingRepo implements OnboardingBaseRepo {
  const OnboardingRepo({required OnboardingBaseLocalDataSource localDataSource})
    : _localDataSource = localDataSource;

  final OnboardingBaseLocalDataSource _localDataSource;

  @override
  Future<Either<Failure, bool>> hasCompletedOnboarding() async {
    try {
      return Right(await _localDataSource.hasCompletedOnboarding());
    } catch (error) {
      return Left(ErrorHandler.handle(error));
    }
  }

  @override
  Future<Either<Failure, Unit>> completeOnboarding() =>
      _guard(_localDataSource.completeOnboarding);

  @override
  Future<Either<Failure, Unit>> resetOnboarding() =>
      _guard(_localDataSource.resetOnboarding);

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
