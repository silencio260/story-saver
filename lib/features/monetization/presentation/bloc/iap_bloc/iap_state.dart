part of 'iap_bloc.dart';

enum IapViewStatus { initial, loading, ready, failure }

class IapState extends Equatable {
  const IapState({
    this.status = IapViewStatus.initial,
    this.isPremium = false,
    this.message,
  });

  final IapViewStatus status;
  final bool isPremium;
  final String? message;

  IapState copyWith({
    IapViewStatus? status,
    bool? isPremium,
    String? message,
    bool clearMessage = false,
  }) => IapState(
    status: status ?? this.status,
    isPremium: isPremium ?? this.isPremium,
    message: clearMessage ? null : message ?? this.message,
  );

  @override
  List<Object?> get props => <Object?>[status, isPremium, message];
}
