import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

import '../../../../features/database/domain/entities/user_profile_entity.dart';
import '../../../../features/database/domain/repositories/user_profile_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Authentication BLoC for managing auth state
///
/// Handles all authentication operations including:
/// - Auto-login with anonymous authentication
/// - Email/password sign-in and sign-up
/// - Google and Apple sign-in
/// - Account linking for anonymous users
/// - Sign out and account deletion
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;
  final UserProfileRepository? _userProfileRepository;
  final Future<void> Function(String ghostUid, String permanentUid)?
      onAccountMerge;

  /// Loading message shown while [onAccountMerge] runs. Generic by default so
  /// the kit isn't tied to chat semantics; hosts can override per app.
  // TODO(feature-audit): chat-specific; strip account-merge from kit when audited
  final String mergeLoadingMessage;
  StreamSubscription<UserEntity?>? _authStateSubscription;

  AuthBloc({
    required AuthRepository repository,
    UserProfileRepository? userProfileRepository,
    this.onAccountMerge,
    this.mergeLoadingMessage = 'Merging your account...',
  })  : _repository = repository,
        _userProfileRepository = userProfileRepository,
        super(const AuthInitial()) {
    if (kDebugMode) {
      print(
          "DEBUG PREFILL: AuthBloc initialized. userProfileRepository is null? ${userProfileRepository == null}");
    }
    // Register event handlers
    on<AuthCheckStatus>(_onCheckStatus);
    on<AuthSignInAnonymously>(_onSignInAnonymously);
    on<AuthSignInWithEmail>(_onSignInWithEmail);
    on<AuthSignInWithGoogle>(_onSignInWithGoogle);
    on<AuthSignInWithApple>(_onSignInWithApple);
    on<AuthSignUpWithEmail>(_onSignUpWithEmail);
    on<AuthSignOut>(_onSignOut);
    on<AuthLinkWithEmail>(_onLinkWithEmail);
    on<AuthLinkWithGoogle>(_onLinkWithGoogle);
    on<AuthLinkWithApple>(_onLinkWithApple);
    on<AuthSendPasswordReset>(_onSendPasswordReset);
    on<AuthDeleteAccount>(_onDeleteAccount);
    on<_AuthStateChanged>(_onAuthStateChanged);
    on<AuthCheckEmail>(_onCheckEmail);

    // Listen to auth state changes
    _authStateSubscription = _repository.authStateChanges().listen(
      (user) {
        if (user != null) {
          _ensureProfileExists(user);
        }
        add(_AuthStateChanged(user));
      },
    );
  }

  /// Ensure user profile exists in Firestore
  Future<void> _ensureProfileExists(UserEntity user) async {
    // Do not create or sync profiles for anonymous users
    if (user.isAnonymous) return;
    if (_userProfileRepository == null) return;

    try {
      final result = await _userProfileRepository!.getUserProfile(user.uid);

      if (result.isLeft()) {
        // Profile doesn't exist — create a new one
        final newProfile = UserProfileEntity.initial(
          uid: user.uid,
          email: user.email,
          displayName: user.displayName,
          photoUrl: user.photoUrl,
          isAnonymous: user.isAnonymous,
        );
        await _userProfileRepository!.createUserProfile(newProfile);
      } else {
        // Profile exists
        final profile = result.getOrElse(
          () => throw Exception('unreachable'),
        );

        // Always update last active
        await _userProfileRepository!.updateLastActive(user.uid);

        // Sync profile if user info has changed (e.g. anonymous→real,
        // or displayName/email/photo updated via Google sign-in)
        final needsUpdate = profile.isAnonymous != user.isAnonymous ||
            (user.displayName != null &&
                user.displayName != profile.displayName) ||
            (user.email != null && user.email != profile.email) ||
            (user.photoUrl != null && user.photoUrl != profile.photoUrl);

        if (needsUpdate) {
          final updatedProfile = profile.copyWith(
            email: user.email ?? profile.email,
            displayName: user.displayName ?? profile.displayName,
            photoUrl: user.photoUrl ?? profile.photoUrl,
            isAnonymous: user.isAnonymous,
          );
          await _userProfileRepository!.updateUserProfile(updatedProfile);
        }
      }
    } catch (e) {
      // Log but don't crash — profile sync is best-effort
      if (kDebugMode) {
        print('[AuthBloc] _ensureProfileExists error: $e');
      }
    }
  }

  /// Get the current user ID token for backend authentication
  Future<String?> getIdToken() async {
    final result = await _repository.getIdToken();
    return result.fold((failure) => null, (token) => token);
  }

  /// Get the current authenticated user
  UserEntity? get currentUser {
    final currentState = state;
    if (currentState is AuthAuthenticated) {
      return currentState.user;
    }
    return null;
  }

  /// Check if user is currently authenticated
  bool get isAuthenticated => state is AuthAuthenticated;

  /// Check if current user is anonymous
  bool get isAnonymous {
    final user = currentUser;
    return user?.isAnonymous ?? true;
  }

  Future<void> _onCheckStatus(
    AuthCheckStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Checking authentication...'));

    final result = await _repository.getCurrentUser();
    result.fold(
      (failure) => emit(const AuthUnauthenticated()),
      (user) {
        if (user != null) {
          emit(AuthAuthenticated(user: user));
        } else {
          emit(const AuthUnauthenticated());
        }
      },
    );
  }

  Future<void> _onCheckEmail(
    AuthCheckEmail event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Checking email...'));

    final result = await _repository.fetchSignInMethodsForEmail(event.email);
    final methods = result.getOrElse(() => []);

    // Always try to fetch the user profile by email from Firestore.
    // We do NOT gate this on `methods.isNotEmpty` because
    // fetchSignInMethodsForEmail is deprecated and returns empty on
    // newer Firebase projects even when the account exists.
    String? displayName;

    if (_userProfileRepository != null) {
      try {
        final profileResult =
            await _userProfileRepository!.getUserProfileByEmail(event.email);

        if (kDebugMode) {
          print("DEBUG PREFILL {prrofileResult}: $profileResult ");
          print("DEBUG PREFILL {result}: $result ");
        }

        profileResult.fold(
          (failure) => null,
          (profile) => displayName = profile?.displayName,
        );
      } catch (_) {
        // Ignore — lookup is best-effort
      }
    }

    if (result.isLeft()) {
      result.fold(
        (failure) => emit(AuthError(message: failure.message)),
        (_) {},
      );
    } else {
      emit(AuthEmailChecked(
        email: event.email,
        isNewUser: methods.isEmpty && displayName == null,
        signInMethods: methods,
        displayName: displayName,
      ));
    }
  }

  Future<void> _onSignInAnonymously(
    AuthSignInAnonymously event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Signing in...'));

    final result = await _repository.signInAnonymously();
    result.fold(
      (failure) => emit(AuthError(
        message: failure.message,
        code: failure is AuthFailure ? failure.code : null,
      )),
      (user) => emit(AuthAuthenticated(user: user)),
    );
  }

  Future<void> _onSignInWithEmail(
    AuthSignInWithEmail event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Signing in...'));

    final wasAnonymous = isAnonymous;
    final ghostUid = currentUser?.uid;

    final result = await _repository.signInWithEmail(
      email: event.email,
      password: event.password,
    );

    await result.fold(
      (failure) async {
        emit(AuthError(
          message: failure.message,
          code: failure is AuthFailure ? failure.code : null,
        ));
      },
      (user) async {
        // Merge accounts if we just transitioned from an anonymous account
        if (wasAnonymous &&
            ghostUid != null &&
            user.uid != ghostUid &&
            onAccountMerge != null) {
          emit(AuthLoading(message: mergeLoadingMessage));
          await onAccountMerge!.call(ghostUid, user.uid);
        }
        emit(AuthAuthenticated(user: user));
      },
    );
  }

  Future<void> _onSignInWithGoogle(
    AuthSignInWithGoogle event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Signing in with Google...'));

    final wasAnonymous = isAnonymous;
    final ghostUid = currentUser?.uid;

    final result = await _repository.signInWithGoogle();

    await result.fold(
      (failure) async {
        emit(AuthError(
          message: failure.message,
          code: failure is AuthFailure ? failure.code : null,
        ));
      },
      (user) async {
        if (wasAnonymous &&
            ghostUid != null &&
            user.uid != ghostUid &&
            onAccountMerge != null) {
          emit(AuthLoading(message: mergeLoadingMessage));
          await onAccountMerge!.call(ghostUid, user.uid);
        }
        emit(AuthAuthenticated(user: user));
      },
    );
  }

  Future<void> _onSignInWithApple(
    AuthSignInWithApple event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Signing in with Apple...'));

    final wasAnonymous = isAnonymous;
    final ghostUid = currentUser?.uid;

    final result = await _repository.signInWithApple();

    await result.fold(
      (failure) async {
        emit(AuthError(
          message: failure.message,
          code: failure is AuthFailure ? failure.code : null,
        ));
      },
      (user) async {
        if (wasAnonymous &&
            ghostUid != null &&
            user.uid != ghostUid &&
            onAccountMerge != null) {
          emit(AuthLoading(message: mergeLoadingMessage));
          await onAccountMerge!.call(ghostUid, user.uid);
        }
        emit(AuthAuthenticated(user: user));
      },
    );
  }

  Future<void> _onSignUpWithEmail(
    AuthSignUpWithEmail event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Creating account...'));

    final wasAnonymous = isAnonymous;
    final ghostUid = currentUser?.uid;

    final result = await _repository.signUpWithEmail(
      email: event.email,
      password: event.password,
      displayName: event.displayName,
    );

    await result.fold(
      (failure) async {
        emit(AuthError(
          message: failure.message,
          code: failure is AuthFailure ? failure.code : null,
        ));
      },
      (user) async {
        if (wasAnonymous &&
            ghostUid != null &&
            user.uid != ghostUid &&
            onAccountMerge != null) {
          emit(AuthLoading(message: mergeLoadingMessage));
          await onAccountMerge!.call(ghostUid, user.uid);
        }
        emit(AuthAuthenticated(user: user));
      },
    );
  }

  Future<void> _onSignOut(
    AuthSignOut event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Signing out...'));

    final result = await _repository.signOut();
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) => emit(const AuthUnauthenticated()),
    );
  }

  Future<void> _onLinkWithEmail(
    AuthLinkWithEmail event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Linking account...'));

    final result = await _repository.linkWithEmail(
      email: event.email,
      password: event.password,
    );
    result.fold(
      (failure) => emit(AuthError(
        message: failure.message,
        code: failure is AuthFailure ? failure.code : null,
      )),
      (user) => emit(AuthAccountLinked(user: user)),
    );
  }

  Future<void> _onLinkWithGoogle(
    AuthLinkWithGoogle event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Linking with Google...'));

    final result = await _repository.linkWithGoogle();
    result.fold(
      (failure) => emit(AuthError(
        message: failure.message,
        code: failure is AuthFailure ? failure.code : null,
      )),
      (user) => emit(AuthAccountLinked(user: user)),
    );
  }

  Future<void> _onLinkWithApple(
    AuthLinkWithApple event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Linking with Apple...'));

    final result = await _repository.linkWithApple();
    result.fold(
      (failure) => emit(AuthError(
        message: failure.message,
        code: failure is AuthFailure ? failure.code : null,
      )),
      (user) => emit(AuthAccountLinked(user: user)),
    );
  }

  Future<void> _onSendPasswordReset(
    AuthSendPasswordReset event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Sending reset email...'));

    final result = await _repository.sendPasswordResetEmail(email: event.email);
    result.fold(
      (failure) => emit(AuthError(
        message: failure.message,
        code: failure is AuthFailure ? failure.code : null,
      )),
      (_) => emit(AuthPasswordResetSent(email: event.email)),
    );
  }

  Future<void> _onDeleteAccount(
    AuthDeleteAccount event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Deleting account...'));

    final result = await _repository.deleteAccount();
    result.fold(
      (failure) => emit(AuthError(
        message: failure.message,
        code: failure is AuthFailure ? failure.code : null,
      )),
      (_) => emit(const AuthAccountDeleted()),
    );
  }

  void _onAuthStateChanged(
    _AuthStateChanged event,
    Emitter<AuthState> emit,
  ) {
    if (event.user != null) {
      // Avoid emitting a duplicate AuthAuthenticated if we're already
      // authenticated with the same user. This prevents the double-pop
      // issue where a sign-in handler emits AuthAuthenticated and then
      // the auth state stream fires _AuthStateChanged with the same user.
      if (state is AuthAuthenticated &&
          (state as AuthAuthenticated).user.uid == event.user!.uid) {
        return;
      }
      emit(AuthAuthenticated(user: event.user!));
    } else {
      // Don't emit unauthenticated during loading states
      if (state is! AuthLoading) {
        emit(const AuthUnauthenticated());
      }
    }
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}
