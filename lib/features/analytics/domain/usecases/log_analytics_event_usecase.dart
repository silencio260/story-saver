import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/base_usecase.dart';
import '../entities/analytics_event.dart';
import '../repositories/analytics_repository.dart';

class LogAnalyticsEventUseCase extends BaseUseCase<Unit, AnalyticsEventEntity> {
  const LogAnalyticsEventUseCase({required AnalyticsBaseRepo repo})
    : _repo = repo;

  final AnalyticsBaseRepo _repo;

  @override
  Future<Either<Failure, Unit>> call(AnalyticsEventEntity event) =>
      _repo.log(event);
}
