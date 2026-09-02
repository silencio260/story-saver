import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/base_usecase.dart';
import '../repositories/ads_repository.dart';

class ShowInterstitialAdUseCase extends BaseUseCase<bool, NoParams> {
  const ShowInterstitialAdUseCase({required AdsBaseRepo repo}) : _repo = repo;

  final AdsBaseRepo _repo;

  @override
  Future<Either<Failure, bool>> call(NoParams params) =>
      _repo.showInterstitial();
}
