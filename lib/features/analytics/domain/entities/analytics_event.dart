import 'package:equatable/equatable.dart';

class AnalyticsEventEntity extends Equatable {
  const AnalyticsEventEntity({
    required this.name,
    this.parameters = const <String, Object>{},
  });

  final String name;
  final Map<String, Object> parameters;

  @override
  List<Object?> get props => <Object?>[name, parameters];
}
