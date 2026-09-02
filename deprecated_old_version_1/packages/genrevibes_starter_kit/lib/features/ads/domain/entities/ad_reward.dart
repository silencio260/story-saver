import 'package:equatable/equatable.dart';

/// Ad reward entity for rewarded ads
class AdReward extends Equatable {
  final String type;
  final int amount;

  const AdReward({required this.type, required this.amount});

  @override
  List<Object?> get props => [type, amount];
}
