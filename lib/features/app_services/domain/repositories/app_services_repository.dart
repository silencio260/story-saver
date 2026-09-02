import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';

abstract class AppServicesBaseRepo {
  Future<Either<Failure, Unit>> initialize();
}
