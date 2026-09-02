import 'package:equatable/equatable.dart';
import 'auth_provider.dart';

/// Domain entity representing an authenticated user
/// 
/// This is a pure domain object with no framework dependencies.
/// It represents the authenticated user's core information.
class UserEntity extends Equatable {
  /// Unique user identifier from Firebase Auth
  final String uid;

  /// User's email address (null for anonymous users)
  final String? email;

  /// User's display name
  final String? displayName;

  /// URL to user's profile photo
  final String? photoUrl;

  /// Whether this is an anonymous account
  final bool isAnonymous;

  /// When the user account was created
  final DateTime createdAt;

  /// Last sign-in timestamp
  final DateTime? lastSignInAt;

  /// Authentication provider used
  final AuthProvider provider;

  const UserEntity({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    required this.isAnonymous,
    required this.createdAt,
    this.lastSignInAt,
    required this.provider,
  });

  /// Create a copy with modified fields
  UserEntity copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isAnonymous,
    DateTime? createdAt,
    DateTime? lastSignInAt,
    AuthProvider? provider,
  }) {
    return UserEntity(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      createdAt: createdAt ?? this.createdAt,
      lastSignInAt: lastSignInAt ?? this.lastSignInAt,
      provider: provider ?? this.provider,
    );
  }

  @override
  List<Object?> get props => [
        uid,
        email,
        displayName,
        photoUrl,
        isAnonymous,
        createdAt,
        lastSignInAt,
        provider,
      ];

  @override
  String toString() {
    return 'UserEntity(uid: $uid, email: $email, displayName: $displayName, '
        'isAnonymous: $isAnonymous, provider: ${provider.value})';
  }
}
