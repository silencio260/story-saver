import 'package:dartz/dartz.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/repositories/iap_repository.dart';
import '../datasources/iap_remote_data_source.dart';

class IapRepo implements IapBaseRepo {
  const IapRepo({required IapBaseRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final IapBaseRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, Subscription>> initialize() =>
      _guard(_remoteDataSource.initialize);

  @override
  Future<Either<Failure, Subscription>> refresh() =>
      _guard(_remoteDataSource.refresh);

  @override
  Future<Either<Failure, Subscription>> showPaywall() =>
      _guard(_remoteDataSource.showPaywall, includePurchaseStatus: true);

  @override
  Future<Either<Failure, Unit>> showCustomerCenter() async {
    try {
      await _remoteDataSource.showCustomerCenter();
      return const Right(unit);
    } catch (error) {
      return Left(ErrorHandler.handle(error));
    }
  }

  @override
  Future<Either<Failure, Subscription>> restorePurchases() =>
      _guard(_remoteDataSource.restorePurchases);

  Future<Either<Failure, Subscription>> _guard(
    Future<bool> Function() operation, {
    bool includePurchaseStatus = false,
  }) async {
    try {
      final premium = await operation();
      final source = _remoteDataSource;
      return Right(
        Subscription(
          isPremium: premium,
          purchaseStatus:
              includePurchaseStatus && source is PurchaseOutcomeSource
                  ? (source as PurchaseOutcomeSource).lastPurchaseStatus
                  : null,
        ),
      );
    } catch (error) {
      return Left(ErrorHandler.handle(error));
    }
  }
}
