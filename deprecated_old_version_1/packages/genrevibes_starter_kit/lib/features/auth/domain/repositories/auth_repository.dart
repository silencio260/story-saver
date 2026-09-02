import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/user_entity.dart';

/// Abstract repository interface for authentication operations
///
/// This defines the contract for authentication that can be implemented
/// with different providers (Firebase, custom backend, etc.)
abstract class AuthRepository {
  /// Sign in anonymously (auto-login for new users)
  Future<Either<Failure, UserEntity>> signInAnonymously();

  /// Sign in with email and password
  Future<Either<Failure, UserEntity>> signInWithEmail({
    required String email,
    required String password,
  });

  /// Sign in with Google account
  Future<Either<Failure, UserEntity>> signInWithGoogle();

  /// Sign in with Apple account (iOS only)
  Future<Either<Failure, UserEntity>> signInWithApple();

  /// Create a new account with email and password
  Future<Either<Failure, UserEntity>> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  });

  /// Sign out the current user
  Future<Either<Failure, void>> signOut();

  /// Get the currently authenticated user (null if not signed in)
  Future<Either<Failure, UserEntity?>> getCurrentUser();

  /// Stream of authentication state changes
  /// Emits null when signed out, UserEntity when signed in
  Stream<UserEntity?> authStateChanges();

  /// Get the current user's ID token for backend authentication
  /// Returns null if not signed in
  Future<Either<Failure, String?>> getIdToken();

  /// Link an anonymous account to email/password credentials
  /// Preserves user data when upgrading from anonymous to permanent account
  Future<Either<Failure, UserEntity>> linkWithEmail({
    required String email,
    required String password,
  });

  /// Link an anonymous account to Google credentials
  Future<Either<Failure, UserEntity>> linkWithGoogle();

  /// Link an anonymous account to Apple credentials
  Future<Either<Failure, UserEntity>> linkWithApple();

  /// Send password reset email
  Future<Either<Failure, void>> sendPasswordResetEmail({
    required String email,
  });

  /// Fetch sign-in methods for email
  Future<Either<Failure, List<String>>> fetchSignInMethodsForEmail(
      String email);

  /// Delete the current user account
  Future<Either<Failure, void>> deleteAccount();

  /// Update user display name
  Future<Either<Failure, void>> updateDisplayName(String displayName);

  /// Update user profile photo URL
  Future<Either<Failure, void>> updatePhotoUrl(String photoUrl);
}
