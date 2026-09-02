import 'package:dartz/dartz.dart';

import '../error/failure.dart';

export 'no_params.dart';

abstract class BaseUseCase<Output, Input> {
  const BaseUseCase();

  Future<Either<Failure, Output>> call(Input params);
}
