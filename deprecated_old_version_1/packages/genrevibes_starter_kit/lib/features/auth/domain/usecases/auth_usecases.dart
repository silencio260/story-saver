import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failure.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Base use case class for authentication operations
abstract class AuthUseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// No parameters needed
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}

/// Parameters for email sign-in
class EmailSignInParams extends Equatable {
  final String email;
  final String password;

  const EmailSignInParams({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// Parameters for email sign-up
class EmailSignUpParams extends Equatable {
  final String email;
  final String password;
  final String? displayName;

  const EmailSignUpParams({
    required this.email,
    required this.password,
    this.displayName,
  });

  @override
  List<Object?> get props => [email, password, displayName];
}

/// Sign in anonymously use case
class SignInAnonymouslyUseCase implements AuthUseCase<UserEntity, NoParams> {
  final AuthRepository repository;

  SignInAnonymouslyUseCase({required this.repository});

  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) {
    return repository.signInAnonymously();
  }
}

/// Sign in with email use case
class SignInWithEmailUseCase
    implements AuthUseCase<UserEntity, EmailSignInParams> {
  final AuthRepository repository;

  SignInWithEmailUseCase({required this.repository});

  @override
  Future<Either<Failure, UserEntity>> call(EmailSignInParams params) {
    return repository.signInWithEmail(
      email: params.email,
      password: params.password,
    );
  }
}

/// Sign in with Google use case
class SignInWithGoogleUseCase implements AuthUseCase<UserEntity, NoParams> {
  final AuthRepository repository;

  SignInWithGoogleUseCase({required this.repository});

  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) {
    return repository.signInWithGoogle();
  }
}

/// Sign in with Apple use case
class SignInWithAppleUseCase implements AuthUseCase<UserEntity, NoParams> {
  final AuthRepository repository;

  SignInWithAppleUseCase({required this.repository});

  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) {
    return repository.signInWithApple();
  }
}

/// Sign up with email use case
class SignUpWithEmailUseCase
    implements AuthUseCase<UserEntity, EmailSignUpParams> {
  final AuthRepository repository;

  SignUpWithEmailUseCase({required this.repository});

  @override
  Future<Either<Failure, UserEntity>> call(EmailSignUpParams params) {
    return repository.signUpWithEmail(
      email: params.email,
      password: params.password,
      displayName: params.displayName,
    );
  }
}

/// Sign out use case
class SignOutUseCase implements AuthUseCase<void, NoParams> {
  final AuthRepository repository;

  SignOutUseCase({required this.repository});

  @override
  Future<Either<Failure, void>> call(NoParams params) {
    return repository.signOut();
  }
}

/// Get current user use case
class GetCurrentUserUseCase implements AuthUseCase<UserEntity?, NoParams> {
  final AuthRepository repository;

  GetCurrentUserUseCase({required this.repository});

  @override
  Future<Either<Failure, UserEntity?>> call(NoParams params) {
    return repository.getCurrentUser();
  }
}

/// Get ID token use case
class GetIdTokenUseCase implements AuthUseCase<String?, NoParams> {
  final AuthRepository repository;

  GetIdTokenUseCase({required this.repository});

  @override
  Future<Either<Failure, String?>> call(NoParams params) {
    return repository.getIdToken();
  }
}

/// Link anonymous account with email use case
class LinkWithEmailUseCase
    implements AuthUseCase<UserEntity, EmailSignInParams> {
  final AuthRepository repository;

  LinkWithEmailUseCase({required this.repository});

  @override
  Future<Either<Failure, UserEntity>> call(EmailSignInParams params) {
    return repository.linkWithEmail(
      email: params.email,
      password: params.password,
    );
  }
}

/// Link anonymous account with Google use case
class LinkWithGoogleUseCase implements AuthUseCase<UserEntity, NoParams> {
  final AuthRepository repository;

  LinkWithGoogleUseCase({required this.repository});

  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) {
    return repository.linkWithGoogle();
  }
}

/// Link anonymous account with Apple use case
class LinkWithAppleUseCase implements AuthUseCase<UserEntity, NoParams> {
  final AuthRepository repository;

  LinkWithAppleUseCase({required this.repository});

  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) {
    return repository.linkWithApple();
  }
}
