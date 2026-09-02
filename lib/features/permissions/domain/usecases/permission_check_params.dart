import 'package:equatable/equatable.dart';

class PermissionCheckParams extends Equatable {
  const PermissionCheckParams({required this.isBusinessMode});

  final bool isBusinessMode;

  @override
  List<Object?> get props => <Object?>[isBusinessMode];
}
