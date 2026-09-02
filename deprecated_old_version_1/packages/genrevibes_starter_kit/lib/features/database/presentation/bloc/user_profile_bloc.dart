import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user_profile_entity.dart';

import '../../domain/repositories/user_profile_repository.dart';

part 'user_profile_event.dart';
part 'user_profile_state.dart';

class UserProfileBloc extends Bloc<UserProfileEvent, UserProfileState> {
  final UserProfileRepository _repository;
  StreamSubscription<UserProfileEntity?>? _profileSubscription;

  UserProfileBloc({required UserProfileRepository repository})
      : _repository = repository,
        super(const UserProfileInitial()) {
    on<UserProfileLoad>(_onLoad);
    on<UserProfileUpdatePreferences>(_onUpdatePreferences);
    on<UserProfileIncrementUsage>(_onIncrementUsage);
    on<UserProfileRefresh>(_onRefresh);
    on<_UserProfileChanged>(_onProfileChanged);
  }

  Future<void> _onLoad(
    UserProfileLoad event,
    Emitter<UserProfileState> emit,
  ) async {
    emit(const UserProfileLoading());

    // Cancel existing subscription if any
    await _profileSubscription?.cancel();

    // Start listening to profile changes
    _profileSubscription = _repository.userProfileStream(event.uid).listen(
          (profile) => add(_UserProfileChanged(profile)),
        );

    final result = await _repository.getUserProfile(event.uid);
    result.fold(
      (failure) => emit(UserProfileError(message: failure.message)),
      (profile) => emit(UserProfileLoaded(profile: profile)),
    );
  }

  Future<void> _onUpdatePreferences(
    UserProfileUpdatePreferences event,
    Emitter<UserProfileState> emit,
  ) async {
    if (state is UserProfileLoaded) {
      final currentProfile = (state as UserProfileLoaded).profile;
      final result = await _repository.updatePreferences(
        currentProfile.uid,
        event.preferences,
      );

      if (result.isLeft()) {
        result.leftMap(
            (failure) => emit(UserProfileError(message: failure.message)));
      }
    }
  }

  Future<void> _onIncrementUsage(
    UserProfileIncrementUsage event,
    Emitter<UserProfileState> emit,
  ) async {
    if (state is UserProfileLoaded) {
      final currentProfile = (state as UserProfileLoaded).profile;
      await _repository.incrementUsage(currentProfile.uid, event.usageKey);
    }
  }

  Future<void> _onRefresh(
    UserProfileRefresh event,
    Emitter<UserProfileState> emit,
  ) async {
    if (state is UserProfileLoaded) {
      final uid = (state as UserProfileLoaded).profile.uid;
      final result = await _repository.getUserProfile(uid);
      result.fold(
        (failure) => emit(UserProfileError(message: failure.message)),
        (profile) => emit(UserProfileLoaded(profile: profile)),
      );
    }
  }

  void _onProfileChanged(
    _UserProfileChanged event,
    Emitter<UserProfileState> emit,
  ) {
    if (event.profile != null) {
      emit(UserProfileLoaded(profile: event.profile!));
    }
  }

  @override
  Future<void> close() {
    _profileSubscription?.cancel();
    return super.close();
  }
}
