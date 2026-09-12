import 'dart:io' show Platform;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:genrevibes_analytics/genrevibes_analytics.dart';

import '../../../domain/entities/analytics_event.dart';
import '../../../domain/entities/analytics_events.dart';

part 'analytics_event.dart';
part 'analytics_state.dart';

/// Records product analytics through the starter kit's pipeline.
///
/// The bloc keeps its events and states, so no screen changes. What it no
/// longer owns is delivery: the pipeline fans an event out to every configured
/// sink, applies the consent gate and resolves event names, none of which this
/// application should re-implement.
///
/// [AnalyticsStarted] no longer initializes anything. The pipeline is composed
/// and started by `bootstrapApp` before the first widget builds, so
/// initializing here would be a second, later start against an already-running
/// module.
class AnalyticsBloc extends Bloc<AnalyticsBlocEvent, AnalyticsState> {
  /// Creates a bloc over the composed [pipeline].
  AnalyticsBloc({required AnalyticsPipeline pipeline})
    : _pipeline = pipeline,
      super(const AnalyticsState()) {
    on<AnalyticsStarted>(_onStarted);
    on<AnalyticsEventLogged>(_onEventLogged);
  }

  final AnalyticsPipeline _pipeline;

  Future<void> _onStarted(
    AnalyticsStarted event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(const AnalyticsState(status: AnalyticsViewStatus.ready));
    add(const AnalyticsEventLogged(AnalyticsEvents.appOpen));
  }

  Future<void> _onEventLogged(
    AnalyticsEventLogged event,
    Emitter<AnalyticsState> emit,
  ) async {
    final result = await _pipeline.track(
      AnalyticsEvent(
        name: event.event.name,
        properties: {
          'platform': Platform.operatingSystem,
          ...event.event.parameters,
        },
      ),
    );
    result.fold(
      onSuccess:
          (report) => emit(
            AnalyticsState(
              status:
                  report.isCompleteSuccess
                      ? AnalyticsViewStatus.ready
                      : AnalyticsViewStatus.failure,
              message:
                  report.isCompleteSuccess
                      ? null
                      : 'Analytics delivery incomplete: ${report.failures.keys.join(", ")}'
                          '${report.suppressedByConsent ? " (consent suppressed)" : ""}',
            ),
          ),
      onFailure:
          (error) => emit(
            AnalyticsState(
              status: AnalyticsViewStatus.failure,
              message: error.message,
            ),
          ),
    );
  }
}
