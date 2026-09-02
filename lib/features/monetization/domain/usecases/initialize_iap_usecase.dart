import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/base_usecase.dart';
import '../entities/subscription.dart';
import '../repositories/iap_repository.dart';

class InitializeIapUseCase extends BaseUseCase<Subscription, NoParams> {
  const InitializeIapUseCase({required IapBaseRepo repo}) : _repo = repo;

  final IapBaseRepo _repo;

  @override
  Future<Either<Failure, Subscription>> call(NoParams params) =>
      _repo.initialize();
}
