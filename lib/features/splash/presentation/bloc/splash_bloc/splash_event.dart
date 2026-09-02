part of 'splash_bloc.dart';

sealed class SplashEvent extends Equatable {
  const SplashEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

class SplashStarted extends SplashEvent {
  const SplashStarted();
}
