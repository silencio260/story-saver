import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/subscription.dart';

abstract class IapBaseRepo {
  Future<Either<Failure, Subscription>> initialize();

  Future<Either<Failure, Subscription>> refresh();

  Future<Either<Failure, Subscription>> showPaywall();

  Future<Either<Failure, Unit>> showCustomerCenter();

  Future<Either<Failure, Subscription>> restorePurchases();
}
