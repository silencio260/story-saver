import '../../domain/entities/user_entity.dart';

/// Abstract interface for authentication data source operations
abstract class AuthRemoteDataSource {
  /// Sign in anonymously
  Future<UserEntity> signInAnonymously();

  /// Sign in with email and password
  Future<UserEntity> signInWithEmail(String email, String password);

  /// Sign in with Google
  Future<UserEntity> signInWithGoogle();

  /// Sign in with Apple
  Future<UserEntity> signInWithApple();

  /// Sign up with email and password
  Future<UserEntity> signUpWithEmail(
    String email,
    String password,
    String? displayName,
  );

  /// Sign out
  Future<void> signOut();

  /// Get current user
  UserEntity? getCurrentUser();

  /// Stream of auth state changes
  Stream<UserEntity?> authStateChanges();

  /// Get ID token for backend auth
  Future<String?> getIdToken();

  /// Link anonymous account with email
  Future<UserEntity> linkWithEmail(String email, String password);

  /// Link anonymous account with Google
  Future<UserEntity> linkWithGoogle();

  /// Link anonymous account with Apple
  Future<UserEntity> linkWithApple();

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email);

  /// Fetch sign-in methods for email
  Future<List<String>> fetchSignInMethodsForEmail(String email);

  /// Delete user account
  Future<void> deleteAccount();

  /// Update display name
  Future<void> updateDisplayName(String displayName);

  /// Update photo URL
  Future<void> updatePhotoUrl(String photoUrl);
}
