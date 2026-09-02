import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/base_usecase.dart';
import '../entities/subscription_status.dart';
import '../repositories/iap_repository.dart';

/// Restore previous purchases use case
class RestorePurchasesUseCase extends NoParamsUseCase<SubscriptionStatus> {
  final IapRepository repository;

  RestorePurchasesUseCase({required this.repository});

  @override
  Future<Either<Failure, SubscriptionStatus>> call() async {
    return await repository.restorePurchases();
  }
}
