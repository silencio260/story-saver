part of 'ads_bloc.dart';

enum AdsViewStatus { initial, ready, disabled, failure }

class AdsState extends Equatable {
  const AdsState({
    this.status = AdsViewStatus.initial,
    this.interstitialWasShown = false,
    this.message,
  });

  final AdsViewStatus status;
  final bool interstitialWasShown;
  final String? message;

  @override
  List<Object?> get props => <Object?>[status, interstitialWasShown, message];
}
