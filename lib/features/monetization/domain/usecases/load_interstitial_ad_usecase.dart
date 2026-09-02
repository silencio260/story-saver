import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/base_usecase.dart';
import '../repositories/ads_repository.dart';

class LoadInterstitialAdUseCase extends BaseUseCase<Unit, NoParams> {
  const LoadInterstitialAdUseCase({required AdsBaseRepo repo}) : _repo = repo;

  final AdsBaseRepo _repo;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) =>
      _repo.loadInterstitial();
}
