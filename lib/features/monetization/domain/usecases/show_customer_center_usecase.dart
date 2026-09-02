import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/base_usecase.dart';
import '../repositories/iap_repository.dart';

class ShowCustomerCenterUseCase extends BaseUseCase<Unit, NoParams> {
  const ShowCustomerCenterUseCase({required IapBaseRepo repo}) : _repo = repo;

  final IapBaseRepo _repo;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) =>
      _repo.showCustomerCenter();
}
