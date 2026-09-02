import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/base_usecase.dart';
import '../repositories/ads_repository.dart';

/// Show app open ad use case
class ShowAppOpenUseCase extends NoParamsUseCase<bool> {
  final AdsRepository repository;

  ShowAppOpenUseCase({required this.repository});

  @override
  Future<Either<Failure, bool>> call() async {
    return await repository.showAppOpen();
  }
}
