import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/base_usecase.dart';
import '../repositories/app_services_repository.dart';

class InitializeAppServicesUseCase extends BaseUseCase<Unit, NoParams> {
  const InitializeAppServicesUseCase({required AppServicesBaseRepo repo})
    : _repo = repo;

  final AppServicesBaseRepo _repo;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) => _repo.initialize();
}
