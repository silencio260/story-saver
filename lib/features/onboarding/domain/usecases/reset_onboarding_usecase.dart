import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/base_usecase.dart';
import '../repositories/onboarding_repository.dart';

class ResetOnboardingUseCase extends BaseUseCase<Unit, NoParams> {
  const ResetOnboardingUseCase({required OnboardingBaseRepo repo})
    : _repo = repo;

  final OnboardingBaseRepo _repo;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) =>
      _repo.resetOnboarding();
}
