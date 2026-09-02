import '../../domain/entities/user_entity.dart';

/// Minimal generic UserModel for starter_kit interface
class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    super.email,
    super.displayName,
    super.photoUrl,
    required super.isAnonymous,
    required super.createdAt,
    super.lastSignInAt,
    required super.provider,
  });
}
