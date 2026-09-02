part of 'splash_bloc.dart';

enum SplashDestination { pending, onboarding, home }

class SplashState extends Equatable {
  const SplashState({
    this.destination = SplashDestination.pending,
    this.message,
  });

  final SplashDestination destination;
  final String? message;

  @override
  List<Object?> get props => <Object?>[destination, message];
}
