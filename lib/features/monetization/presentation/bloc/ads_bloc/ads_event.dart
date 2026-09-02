part of 'ads_bloc.dart';

sealed class AdsEvent extends Equatable {
  const AdsEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

class AdsStarted extends AdsEvent {
  const AdsStarted();
}

class InterstitialAdRequested extends AdsEvent {
  const InterstitialAdRequested();
}

class AdsDisabled extends AdsEvent {
  const AdsDisabled();
}

class AdsSuppressionChanged extends AdsEvent {
  const AdsSuppressionChanged(this.isSuppressed);

  final bool isSuppressed;

  @override
  List<Object?> get props => <Object?>[isSuppressed];
}
