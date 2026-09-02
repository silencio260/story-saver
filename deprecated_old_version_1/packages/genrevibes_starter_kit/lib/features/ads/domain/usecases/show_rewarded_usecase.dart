import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/base_usecase.dart';
import '../entities/ad_reward.dart';
import '../repositories/ads_repository.dart';

/// Show rewarded ad use case
class ShowRewardedUseCase extends NoParamsUseCase<AdReward> {
  final AdsRepository repository;

  ShowRewardedUseCase({required this.repository});

  @override
  Future<Either<Failure, AdReward>> call() async {
    return await repository.showRewarded();
  }
}
