import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/analytics_event.dart';

abstract class AnalyticsBaseRepo {
  Future<Either<Failure, Unit>> initialize();

  Future<Either<Failure, Unit>> log(AnalyticsEventEntity event);
}
