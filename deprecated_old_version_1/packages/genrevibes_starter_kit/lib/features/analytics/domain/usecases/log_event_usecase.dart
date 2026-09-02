import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/base_usecase.dart';
import '../entities/analytics_event.dart';
import '../repositories/analytics_repository.dart';

/// Log event use case
class LogEventUseCase extends BaseUseCase<void, AnalyticsEvent> {
  final AnalyticsRepository repository;

  LogEventUseCase({required this.repository});

  @override
  Future<Either<Failure, void>> call(AnalyticsEvent params) async {
    return await repository.logEvent(params);
  }
}
