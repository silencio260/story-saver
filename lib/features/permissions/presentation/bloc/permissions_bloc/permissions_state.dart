part of 'permissions_bloc.dart';

enum PermissionViewStatus { initial, checking, requesting, ready, failure }

class PermissionsState extends Equatable {
  const PermissionsState({
    this.status = PermissionViewStatus.initial,
    this.hasStoragePermission = false,
    this.regularStatusFolderPermission,
    this.businessStatusFolderPermission,
    this.errorMessage,
  });

  final PermissionViewStatus status;
  final bool hasStoragePermission;
  final bool? regularStatusFolderPermission;
  final bool? businessStatusFolderPermission;
  final String? errorMessage;

  bool hasStatusFolderPermission({required bool isBusinessMode}) =>
      isBusinessMode
          ? businessStatusFolderPermission == true
          : regularStatusFolderPermission == true;

  PermissionsState copyWith({
    PermissionViewStatus? status,
    bool? hasStoragePermission,
    bool? regularStatusFolderPermission,
    bool? businessStatusFolderPermission,
    String? errorMessage,
    bool clearError = false,
  }) => PermissionsState(
    status: status ?? this.status,
    hasStoragePermission: hasStoragePermission ?? this.hasStoragePermission,
    regularStatusFolderPermission:
        regularStatusFolderPermission ?? this.regularStatusFolderPermission,
    businessStatusFolderPermission:
        businessStatusFolderPermission ?? this.businessStatusFolderPermission,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );

  @override
  List<Object?> get props => <Object?>[
    status,
    hasStoragePermission,
    regularStatusFolderPermission,
    businessStatusFolderPermission,
    errorMessage,
  ];
}
