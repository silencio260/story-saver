import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/usecase/base_usecase.dart';
import '../../../domain/usecases/complete_onboarding_usecase.dart';
import '../../../domain/usecases/reset_onboarding_usecase.dart';

part 'onboarding_event.dart';
part 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc({
    required CompleteOnboardingUseCase completeOnboardingUseCase,
    required ResetOnboardingUseCase resetOnboardingUseCase,
  }) : _completeOnboarding = completeOnboardingUseCase,
       _resetOnboarding = resetOnboardingUseCase,
       super(const OnboardingState()) {
    on<OnboardingPageChanged>(
      (event, emit) => emit(state.copyWith(pageIndex: event.index)),
    );
    on<OnboardingCompleted>(_onCompleted);
    on<OnboardingResetRequested>(_onResetRequested);
  }

  final CompleteOnboardingUseCase _completeOnboarding;
  final ResetOnboardingUseCase _resetOnboarding;

  Future<void> _onCompleted(
    OnboardingCompleted event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(state.copyWith(status: OnboardingViewStatus.saving));
    final result = await _completeOnboarding(NoParams.instance);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: OnboardingViewStatus.failure,
          message: failure.message,
        ),
      ),
      (_) => emit(state.copyWith(status: OnboardingViewStatus.completed)),
    );
  }

  Future<void> _onResetRequested(
    OnboardingResetRequested event,
    Emitter<OnboardingState> emit,
  ) async {
    final result = await _resetOnboarding(NoParams.instance);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: OnboardingViewStatus.failure,
          message: failure.message,
        ),
      ),
      (_) => emit(const OnboardingState()),
    );
  }
}
