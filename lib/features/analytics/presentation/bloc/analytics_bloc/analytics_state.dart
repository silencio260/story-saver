part of 'analytics_bloc.dart';

enum AnalyticsViewStatus { initial, ready, failure }

class AnalyticsState extends Equatable {
  const AnalyticsState({
    this.status = AnalyticsViewStatus.initial,
    this.message,
  });

  final AnalyticsViewStatus status;
  final String? message;

  @override
  List<Object?> get props => <Object?>[status, message];
}
