import 'package:dartz/dartz.dart';

import '../error/failure.dart';

/// Base use case interface following Clean Architecture
///
/// Type parameters:
/// - [Output]: The return type on success
/// - [Input]: The input parameters type
abstract class BaseUseCase<Output, Input> {
  Future<Either<Failure, Output>> call(Input params);
}

/// Use case that doesn't require input parameters
abstract class NoParamsUseCase<Output> {
  Future<Either<Failure, Output>> call();
}

/// Marker class for use cases that don't need parameters
class NoParams {
  const NoParams._internal();

  static const NoParams _instance = NoParams._internal();

  factory NoParams() => _instance;
}
