part of 'permissions_bloc.dart';

sealed class PermissionsEvent extends Equatable {
  const PermissionsEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

class PermissionsCheckRequested extends PermissionsEvent {
  const PermissionsCheckRequested({required this.isBusinessMode});

  final bool isBusinessMode;

  @override
  List<Object?> get props => <Object?>[isBusinessMode];
}

class StoragePermissionRequested extends PermissionsEvent {
  const StoragePermissionRequested();
}

class StatusFolderPermissionRequested extends PermissionsEvent {
  const StatusFolderPermissionRequested({required this.isBusinessMode});

  final bool isBusinessMode;

  @override
  List<Object?> get props => <Object?>[isBusinessMode];
}
