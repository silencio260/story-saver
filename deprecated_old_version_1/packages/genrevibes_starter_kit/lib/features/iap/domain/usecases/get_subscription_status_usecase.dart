import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/base_usecase.dart';
import '../entities/subscription_status.dart';
import '../repositories/iap_repository.dart';

/// Get current subscription status use case
class GetSubscriptionStatusUseCase extends NoParamsUseCase<SubscriptionStatus> {
  final IapRepository repository;

  GetSubscriptionStatusUseCase({required this.repository});

  @override
  Future<Either<Failure, SubscriptionStatus>> call() async {
    return await repository.getSubscriptionStatus();
  }
}
