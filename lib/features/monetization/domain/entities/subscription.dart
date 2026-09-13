import 'package:genrevibes_iap/genrevibes_iap.dart';
export 'package:genrevibes_iap/genrevibes_iap.dart' show PurchaseStatus;
import 'package:equatable/equatable.dart';

class Subscription extends Equatable {
  const Subscription({required this.isPremium, this.purchaseStatus});

  final bool isPremium;
  final PurchaseStatus? purchaseStatus;

  @override
  List<Object?> get props => <Object?>[isPremium, purchaseStatus];
}
