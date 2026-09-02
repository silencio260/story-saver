import 'package:equatable/equatable.dart';

/// Represents an Ad Revenue Event to be logged
class AdRevenueEvent extends Equatable {
  final double value;
  final double valueMicros;
  final String currency;
  final String adSource; // e.g., AdMob, AppLovin
  final String adUnitId;
  final String? adNetwork; // Specific mediation network e.g. Facebook
  final String? adFormat; // e.g. banner, interstitial

  const AdRevenueEvent({
    required this.value,
    required this.valueMicros,
    required this.currency,
    required this.adSource,
    required this.adUnitId,
    this.adNetwork,
    this.adFormat,
  });

  @override
  List<Object?> get props => [
    value,
    valueMicros,
    currency,
    adSource,
    adUnitId,
    adNetwork,
    adFormat,
  ];
}
