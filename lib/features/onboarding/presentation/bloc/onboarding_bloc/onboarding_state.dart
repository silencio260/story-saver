part of 'onboarding_bloc.dart';

enum OnboardingViewStatus { idle, saving, completed, failure }

class OnboardingState extends Equatable {
  const OnboardingState({
    this.pageIndex = 0,
    this.status = OnboardingViewStatus.idle,
    this.message,
  });

  final int pageIndex;
  final OnboardingViewStatus status;
  final String? message;

  OnboardingState copyWith({
    int? pageIndex,
    OnboardingViewStatus? status,
    String? message,
  }) => OnboardingState(
    pageIndex: pageIndex ?? this.pageIndex,
    status: status ?? this.status,
    message: message ?? this.message,
  );

  @override
  List<Object?> get props => <Object?>[pageIndex, status, message];
}
