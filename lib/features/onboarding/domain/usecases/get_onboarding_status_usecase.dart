import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/base_usecase.dart';
import '../repositories/onboarding_repository.dart';

class GetOnboardingStatusUseCase extends BaseUseCase<bool, NoParams> {
  const GetOnboardingStatusUseCase({required OnboardingBaseRepo repo})
    : _repo = repo;

  final OnboardingBaseRepo _repo;

  @override
  Future<Either<Failure, bool>> call(NoParams params) =>
      _repo.hasCompletedOnboarding();
}
