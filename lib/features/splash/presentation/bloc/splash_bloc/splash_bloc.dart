import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/usecase/base_usecase.dart';
import '../../../../onboarding/domain/usecases/get_onboarding_status_usecase.dart';

part 'splash_event.dart';
part 'splash_state.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  SplashBloc({required GetOnboardingStatusUseCase getOnboardingStatusUseCase})
    : _getOnboardingStatus = getOnboardingStatusUseCase,
      super(const SplashState()) {
    on<SplashStarted>(_onStarted);
  }

  final GetOnboardingStatusUseCase _getOnboardingStatus;

  Future<void> _onStarted(
    SplashStarted event,
    Emitter<SplashState> emit,
  ) async {
    final result = await _getOnboardingStatus(NoParams.instance);
    result.fold(
      (failure) => emit(
        SplashState(
          destination: SplashDestination.onboarding,
          message: failure.message,
        ),
      ),
      (completed) => emit(
        SplashState(
          destination:
              completed ? SplashDestination.home : SplashDestination.onboarding,
        ),
      ),
    );
  }
}
