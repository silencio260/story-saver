import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/base_usecase.dart';
import '../entities/subscription.dart';
import '../repositories/iap_repository.dart';

class ShowPaywallUseCase extends BaseUseCase<Subscription, NoParams> {
  const ShowPaywallUseCase({required IapBaseRepo repo}) : _repo = repo;

  final IapBaseRepo _repo;

  @override
  Future<Either<Failure, Subscription>> call(NoParams params) =>
      _repo.showPaywall();
}
