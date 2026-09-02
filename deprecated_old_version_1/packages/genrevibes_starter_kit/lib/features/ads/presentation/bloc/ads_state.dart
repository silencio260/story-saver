part of 'ads_bloc.dart';

abstract class AdsState extends Equatable {
  final AdsConfig? config;
  const AdsState({this.config});

  @override
  List<Object?> get props => [config];
}

class AdsInitial extends AdsState {
  const AdsInitial({super.config});
}

class AdsLoading extends AdsState {
  const AdsLoading({super.config});
}

class AdsInitialized extends AdsState {
  const AdsInitialized({super.config});
}

class AdsReady extends AdsState {
  final bool isInterstitialReady;
  final bool isRewardedReady;
  final bool isAppOpenReady;
  final bool isNativeReady;

  const AdsReady({
    this.isInterstitialReady = false,
    this.isRewardedReady = false,
    this.isAppOpenReady = false,
    this.isNativeReady = false,
    super.config,
  });

  @override
  List<Object?> get props => [
    ...super.props,
    isInterstitialReady,
    isRewardedReady,
    isAppOpenReady,
    isNativeReady,
  ];
}

class AdsShowSuccess extends AdsState {
  final AdType type;
  final AdReward? reward;

  const AdsShowSuccess({required this.type, this.reward, super.config});

  @override
  List<Object?> get props => [...super.props, type, reward];
}

class AdsError extends AdsState {
  final String message;

  const AdsError({required this.message, super.config});

  @override
  List<Object?> get props => [...super.props, message];
}
