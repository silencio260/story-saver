part of 'auth_bloc.dart';

/// Base class for all auth states
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any auth check
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Result of checking an email's sign-in methods
class AuthEmailChecked extends AuthState {
  final String email;
  final bool isNewUser;
  final List<String> signInMethods;
  final String? displayName;

  const AuthEmailChecked({
    required this.email,
    required this.isNewUser,
    required this.signInMethods,
    this.displayName,
  });

  @override
  List<Object?> get props => [email, isNewUser, signInMethods, displayName];
}

/// Loading state during authentication operations
class AuthLoading extends AuthState {
  final String? message;

  const AuthLoading({this.message});

  @override
  List<Object?> get props => [message];
}

/// Authenticated state with user data
class AuthAuthenticated extends AuthState {
  final UserEntity user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

/// Unauthenticated state (no user signed in)
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Error state with message
class AuthError extends AuthState {
  final String message;
  final String? code;

  const AuthError({
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [message, code];
}

/// Password reset email sent successfully
class AuthPasswordResetSent extends AuthState {
  final String email;

  const AuthPasswordResetSent({required this.email});

  @override
  List<Object?> get props => [email];
}

/// Account successfully linked
class AuthAccountLinked extends AuthState {
  final UserEntity user;

  const AuthAccountLinked({required this.user});

  @override
  List<Object?> get props => [user];
}

/// Account deleted successfully
class AuthAccountDeleted extends AuthState {
  const AuthAccountDeleted();
}
