import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/ad_reward.dart';
import '../../domain/entities/ad_unit.dart';
import '../../domain/repositories/ads_repository.dart';
import '../../../analytics/domain/entities/ad_revenue_event.dart';
import '../datasources/ads_remote_data_source.dart';

class AdsRepositoryImpl implements AdsRepository {
  final AdsRemoteDataSource remoteDataSource;
  void Function(AdRevenueEvent)? _onPaidEvent;
  void Function(String adType)? _onAdClick;

  AdsRepositoryImpl({required this.remoteDataSource});

  @override
  void setOnPaidEventListener(void Function(AdRevenueEvent) listener) {
    _onPaidEvent = listener;
    remoteDataSource.setOnPaidEventListener(listener);
  }

  @override
  void setOnAdClickListener(void Function(String adType) listener) {
    _onAdClick = listener;
    remoteDataSource.setOnAdClickListener(listener);
  }

  @override
  void recordAdRevenue(AdRevenueEvent event) {
    _onPaidEvent?.call(event);
  }

  @override
  void recordAdClick(String adType) {
    _onAdClick?.call(adType);
  }

  @override
  Future<Either<Failure, void>> initialize(AdsConfig config) async {
    return _guard(() => remoteDataSource.initialize(config));
  }

  @override
  Future<Either<Failure, AdUnit>> loadBanner(String adUnitId) {
    return _guard(() => remoteDataSource.loadBanner(adUnitId));
  }

  @override
  Future<Either<Failure, AdUnit>> loadInterstitial(String adUnitId) {
    return _guard(() => remoteDataSource.loadInterstitial(adUnitId));
  }

  @override
  Future<Either<Failure, bool>> showInterstitial() {
    return _guard(remoteDataSource.showInterstitial);
  }

  @override
  Future<Either<Failure, AdUnit>> loadRewarded(String adUnitId) {
    return _guard(() => remoteDataSource.loadRewarded(adUnitId));
  }

  @override
  Future<Either<Failure, AdReward>> showRewarded() {
    return _guard(remoteDataSource.showRewarded);
  }

  @override
  Future<Either<Failure, bool>> isInterstitialReady() {
    return _guard(remoteDataSource.isInterstitialReady);
  }

  @override
  Future<Either<Failure, bool>> isRewardedReady() {
    return _guard(remoteDataSource.isRewardedReady);
  }

  @override
  Future<Either<Failure, AdUnit>> loadAppOpen(String adUnitId) {
    return _guard(() => remoteDataSource.loadAppOpen(adUnitId));
  }

  @override
  Future<Either<Failure, bool>> showAppOpen() {
    return _guard(remoteDataSource.showAppOpen);
  }

  @override
  Future<Either<Failure, bool>> isAppOpenReady() {
    return _guard(remoteDataSource.isAppOpenReady);
  }

  @override
  Future<Either<Failure, AdUnit>> loadNative(String adUnitId) {
    return _guard(() => remoteDataSource.loadNative(adUnitId));
  }

  @override
  Future<Either<Failure, bool>> isNativeReady() {
    return _guard(remoteDataSource.isNativeReady);
  }

  @override
  Future<Either<Failure, void>> dispose() {
    return _guard(remoteDataSource.dispose);
  }

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } catch (error) {
      return Left(AdFailure(message: error.toString()));
    }
  }
}
