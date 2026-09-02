import 'package:equatable/equatable.dart';

/// Generic event entity
class AnalyticsEvent extends Equatable {
  final String name;
  final Map<String, dynamic> parameters;

  const AnalyticsEvent({required this.name, this.parameters = const {}});

  @override
  List<Object?> get props => [name, parameters];
}
