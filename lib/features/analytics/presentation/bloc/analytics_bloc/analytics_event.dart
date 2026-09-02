part of 'analytics_bloc.dart';

sealed class AnalyticsBlocEvent extends Equatable {
  const AnalyticsBlocEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

class AnalyticsStarted extends AnalyticsBlocEvent {
  const AnalyticsStarted();
}

class AnalyticsEventLogged extends AnalyticsBlocEvent {
  const AnalyticsEventLogged(this.event);

  final AnalyticsEventEntity event;

  @override
  List<Object?> get props => <Object?>[event];
}
