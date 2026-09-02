import 'package:equatable/equatable.dart';

class RatingCondition extends Equatable {
  final int minAppOpens;
  final int minDaysInstalled;
  final bool isEligible;

  const RatingCondition({
    required this.minAppOpens,
    required this.minDaysInstalled,
    required this.isEligible,
  });

  @override
  List<Object?> get props => [minAppOpens, minDaysInstalled, isEligible];
}
