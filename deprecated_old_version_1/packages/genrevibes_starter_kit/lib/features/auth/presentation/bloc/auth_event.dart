part of 'auth_bloc.dart';

/// Base class for all auth events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Check current authentication status (called on app launch)
class AuthCheckStatus extends AuthEvent {
  const AuthCheckStatus();
}

/// Check if email exists and get its sign-in methods
class AuthCheckEmail extends AuthEvent {
  final String email;

  const AuthCheckEmail({required this.email});

  @override
  List<Object?> get props => [email];
}

/// Sign in anonymously (auto-login)
class AuthSignInAnonymously extends AuthEvent {
  const AuthSignInAnonymously();
}

/// Sign in with email and password
class AuthSignInWithEmail extends AuthEvent {
  final String email;
  final String password;

  const AuthSignInWithEmail({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// Sign in with Google
class AuthSignInWithGoogle extends AuthEvent {
  const AuthSignInWithGoogle();
}

/// Sign in with Apple
class AuthSignInWithApple extends AuthEvent {
  const AuthSignInWithApple();
}

/// Sign up with email and password
class AuthSignUpWithEmail extends AuthEvent {
  final String email;
  final String password;
  final String? displayName;

  const AuthSignUpWithEmail({
    required this.email,
    required this.password,
    this.displayName,
  });

  @override
  List<Object?> get props => [email, password, displayName];
}

/// Sign out current user
class AuthSignOut extends AuthEvent {
  const AuthSignOut();
}

/// Link anonymous account with email
class AuthLinkWithEmail extends AuthEvent {
  final String email;
  final String password;

  const AuthLinkWithEmail({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// Link anonymous account with Google
class AuthLinkWithGoogle extends AuthEvent {
  const AuthLinkWithGoogle();
}

/// Link anonymous account with Apple
class AuthLinkWithApple extends AuthEvent {
  const AuthLinkWithApple();
}

/// Send password reset email
class AuthSendPasswordReset extends AuthEvent {
  final String email;

  const AuthSendPasswordReset({required this.email});

  @override
  List<Object?> get props => [email];
}

/// Delete user account
class AuthDeleteAccount extends AuthEvent {
  const AuthDeleteAccount();
}

/// Internal event for auth state changes from stream
class _AuthStateChanged extends AuthEvent {
  final UserEntity? user;

  const _AuthStateChanged(this.user);

  @override
  List<Object?> get props => [user];
}
