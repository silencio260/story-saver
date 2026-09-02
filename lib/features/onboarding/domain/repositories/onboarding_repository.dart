import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';

abstract class OnboardingBaseRepo {
  Future<Either<Failure, bool>> hasCompletedOnboarding();

  Future<Either<Failure, Unit>> completeOnboarding();

  Future<Either<Failure, Unit>> resetOnboarding();
}
