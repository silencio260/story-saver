import 'package:equatable/equatable.dart';

class Subscription extends Equatable {
  const Subscription({required this.isPremium});

  final bool isPremium;

  @override
  List<Object?> get props => <Object?>[isPremium];
}
