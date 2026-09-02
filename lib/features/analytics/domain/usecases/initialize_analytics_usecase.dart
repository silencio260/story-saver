import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/base_usecase.dart';
import '../repositories/analytics_repository.dart';

class InitializeAnalyticsUseCase extends BaseUseCase<Unit, NoParams> {
  const InitializeAnalyticsUseCase({required AnalyticsBaseRepo repo})
    : _repo = repo;

  final AnalyticsBaseRepo _repo;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) => _repo.initialize();
}
