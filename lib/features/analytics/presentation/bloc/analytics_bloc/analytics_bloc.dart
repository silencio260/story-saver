import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/usecase/base_usecase.dart';
import '../../../domain/entities/analytics_event.dart';
import '../../../domain/entities/analytics_events.dart';
import '../../../domain/usecases/initialize_analytics_usecase.dart';
import '../../../domain/usecases/log_analytics_event_usecase.dart';

part 'analytics_event.dart';
part 'analytics_state.dart';

class AnalyticsBloc extends Bloc<AnalyticsBlocEvent, AnalyticsState> {
  AnalyticsBloc({
    required InitializeAnalyticsUseCase initializeAnalyticsUseCase,
    required LogAnalyticsEventUseCase logAnalyticsEventUseCase,
  }) : _initialize = initializeAnalyticsUseCase,
       _logEvent = logAnalyticsEventUseCase,
       super(const AnalyticsState()) {
    on<AnalyticsStarted>(_onStarted);
    on<AnalyticsEventLogged>(_onEventLogged);
  }

  final InitializeAnalyticsUseCase _initialize;
  final LogAnalyticsEventUseCase _logEvent;

  Future<void> _onStarted(
    AnalyticsStarted event,
    Emitter<AnalyticsState> emit,
  ) async {
    final result = await _initialize(NoParams.instance);
    await result.fold(
      (failure) async => emit(
        AnalyticsState(
          status: AnalyticsViewStatus.failure,
          message: failure.message,
        ),
      ),
      (_) async {
        emit(const AnalyticsState(status: AnalyticsViewStatus.ready));
        add(const AnalyticsEventLogged(AnalyticsEvents.appOpen));
      },
    );
  }

  Future<void> _onEventLogged(
    AnalyticsEventLogged event,
    Emitter<AnalyticsState> emit,
  ) async {
    final result = await _logEvent(event.event);
    result.fold(
      (failure) => emit(
        AnalyticsState(
          status: AnalyticsViewStatus.failure,
          message: failure.message,
        ),
      ),
      (_) => emit(const AnalyticsState(status: AnalyticsViewStatus.ready)),
    );
  }
}
