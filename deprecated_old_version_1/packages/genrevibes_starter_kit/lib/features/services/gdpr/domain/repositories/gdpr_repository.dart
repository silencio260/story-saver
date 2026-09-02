import 'package:dartz/dartz.dart';
import 'package:genrevibes_starter_kit/core/error/failure.dart';

abstract class GdprRepository {
  /// Request consent update and show form if required
  Future<Either<Failure, void>> requestConsent();

  /// Check if consent has been gathered
  Future<Either<Failure, bool>> isConsentGiven();

  /// Reset consent state (for testing/debug settings)
  Future<Either<Failure, void>> resetConsent();
}
