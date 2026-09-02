import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/base_usecase.dart';
import '../repositories/ads_repository.dart';

/// Show interstitial ad use case
class ShowInterstitialUseCase extends NoParamsUseCase<bool> {
  final AdsRepository repository;

  ShowInterstitialUseCase({required this.repository});

  @override
  Future<Either<Failure, bool>> call() async {
    return await repository.showInterstitial();
  }
}
