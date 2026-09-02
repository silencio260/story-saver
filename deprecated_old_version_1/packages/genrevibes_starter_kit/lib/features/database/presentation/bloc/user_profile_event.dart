part of 'user_profile_bloc.dart';

abstract class UserProfileEvent extends Equatable {
  const UserProfileEvent();

  @override
  List<Object?> get props => [];
}

class UserProfileLoad extends UserProfileEvent {
  final String uid;

  const UserProfileLoad(this.uid);

  @override
  List<Object?> get props => [uid];
}

class UserProfileUpdatePreferences extends UserProfileEvent {
  final Map<String, dynamic> preferences;

  const UserProfileUpdatePreferences(this.preferences);

  @override
  List<Object?> get props => [preferences];
}

class UserProfileIncrementUsage extends UserProfileEvent {
  final String usageKey;

  const UserProfileIncrementUsage(this.usageKey);

  @override
  List<Object?> get props => [usageKey];
}

class UserProfileRefresh extends UserProfileEvent {
  const UserProfileRefresh();
}

class _UserProfileChanged extends UserProfileEvent {
  final UserProfileEntity? profile;

  const _UserProfileChanged(this.profile);

  @override
  List<Object?> get props => [profile];
}
