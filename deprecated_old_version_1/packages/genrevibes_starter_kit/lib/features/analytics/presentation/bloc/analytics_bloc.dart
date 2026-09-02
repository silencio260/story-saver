import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/analytics_repository.dart';
import '../../domain/usecases/log_event_usecase.dart';
import '../../domain/usecases/log_ad_revenue_usecase.dart';
import 'analytics_event.dart';
import 'analytics_state.dart';

class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final AnalyticsRepository repository;
  final LogEventUseCase logEventUseCase;
  final LogAdRevenueUseCase logAdRevenueUseCase;

  AnalyticsBloc({
    required this.repository,
    required this.logEventUseCase,
    required this.logAdRevenueUseCase,
  }) : super(const AnalyticsInitial()) {
    on<AnalyticsInitialize>(_onInitialize);
    on<AnalyticsLogEvent>(_onLogEvent);
    on<AnalyticsLogScreenView>(_onLogScreenView);
    on<AnalyticsLogAdRevenue>(_onLogAdRevenue);
    on<AnalyticsSetUserId>(_onSetUserId);
    on<AnalyticsSetUserProperty>(_onSetUserProperty);
    on<AnalyticsLogRetention>(_onLogRetention);
    on<AnalyticsLogUserSegment>(_onLogUserSegment);
    on<AnalyticsLogTargeting>(_onLogTargeting);
    on<AnalyticsRecordFlutterError>(_onRecordFlutterError);
    on<AnalyticsRecordError>(_onRecordError);
  }

  Future<void> _onInitialize(
    AnalyticsInitialize event,
    Emitter<AnalyticsState> emit,
  ) async {
    final result = await repository.initialize();
    result.fold(
      (failure) => emit(AnalyticsError(message: failure.message)),
      (_) => emit(const AnalyticsInitialized()),
    );
  }

  Future<void> _onLogEvent(
    AnalyticsLogEvent event,
    Emitter<AnalyticsState> emit,
  ) async {
    await logEventUseCase(event.event);
  }

  Future<void> _onLogScreenView(
    AnalyticsLogScreenView event,
    Emitter<AnalyticsState> emit,
  ) async {
    await repository.logScreenView(event.screenName);
  }

  Future<void> _onSetUserId(
    AnalyticsSetUserId event,
    Emitter<AnalyticsState> emit,
  ) async {
    await repository.setUserId(event.userId);
  }

  Future<void> _onSetUserProperty(
    AnalyticsSetUserProperty event,
    Emitter<AnalyticsState> emit,
  ) async {
    await repository.setUserProperty(event.name, event.value);
  }

  Future<void> _onLogAdRevenue(
    AnalyticsLogAdRevenue event,
    Emitter<AnalyticsState> emit,
  ) async {
    await logAdRevenueUseCase(event.revenueEvent);
  }

  Future<void> _onLogRetention(
    AnalyticsLogRetention event,
    Emitter<AnalyticsState> emit,
  ) async {
    await repository.logRetentionEvent(event.name, event.parameters);
  }

  Future<void> _onLogUserSegment(
    AnalyticsLogUserSegment event,
    Emitter<AnalyticsState> emit,
  ) async {
    await repository.logUserSegmentEvent(event.name, event.parameters);
  }

  Future<void> _onLogTargeting(
    AnalyticsLogTargeting event,
    Emitter<AnalyticsState> emit,
  ) async {
    await repository.logTargetingEvent(event.name, event.parameters);
  }

  Future<void> _onRecordFlutterError(
    AnalyticsRecordFlutterError event,
    Emitter<AnalyticsState> emit,
  ) async {
    await repository.recordFlutterError(
      event.error,
      event.stack,
      fatal: event.fatal,
    );
  }

  Future<void> _onRecordError(
    AnalyticsRecordError event,
    Emitter<AnalyticsState> emit,
  ) async {
    await repository.recordError(event.error, event.stack, fatal: event.fatal);
  }
}
