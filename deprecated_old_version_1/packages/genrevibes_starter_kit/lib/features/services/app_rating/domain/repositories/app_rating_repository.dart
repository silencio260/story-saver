import 'package:dartz/dartz.dart';

import '../../../../../core/error/failure.dart';

abstract class AppRatingRepository {
  Future<Either<Failure, void>> initialize();
  Future<Either<Failure, bool>> checkEligibility();
  Future<Either<Failure, void>> requestReview();
  Future<Either<Failure, void>> openStoreListing();
  Future<void> incrementMessagesSent();
}
