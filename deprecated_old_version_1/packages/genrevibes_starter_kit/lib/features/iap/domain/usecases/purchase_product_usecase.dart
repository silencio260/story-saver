import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/base_usecase.dart';
import '../entities/subscription_status.dart';
import '../repositories/iap_repository.dart';

/// Purchase a product use case
class PurchaseProductUseCase extends BaseUseCase<SubscriptionStatus, String> {
  final IapRepository repository;

  PurchaseProductUseCase({required this.repository});

  @override
  Future<Either<Failure, SubscriptionStatus>> call(String productId) async {
    return await repository.purchaseProduct(productId);
  }
}
