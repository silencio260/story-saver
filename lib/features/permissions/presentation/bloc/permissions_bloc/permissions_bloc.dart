import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:storysaver/features/analytics/data/services/analytics_service.dart';

import '../../../../../core/usecase/base_usecase.dart';
import '../../../domain/usecases/check_status_folder_permission_usecase.dart';
import '../../../domain/usecases/check_storage_permission_usecase.dart';
import '../../../domain/usecases/permission_check_params.dart';
import '../../../domain/usecases/request_status_folder_permission_usecase.dart';
import '../../../domain/usecases/request_storage_permission_usecase.dart';

part 'permissions_event.dart';
part 'permissions_state.dart';

class PermissionsBloc extends Bloc<PermissionsEvent, PermissionsState> {
  PermissionsBloc({
    required CheckStoragePermissionUseCase checkStoragePermissionUseCase,
    required RequestStoragePermissionUseCase requestStoragePermissionUseCase,
    required CheckStatusFolderPermissionUseCase
    checkStatusFolderPermissionUseCase,
    required RequestStatusFolderPermissionUseCase
    requestStatusFolderPermissionUseCase,
  }) : _checkStorage = checkStoragePermissionUseCase,
       _requestStorage = requestStoragePermissionUseCase,
       _checkStatusFolder = checkStatusFolderPermissionUseCase,
       _requestStatusFolder = requestStatusFolderPermissionUseCase,
       super(const PermissionsState()) {
    on<PermissionsCheckRequested>(_onCheckRequested);
    on<StoragePermissionRequested>(_onStorageRequested);
    on<StatusFolderPermissionRequested>(_onStatusFolderRequested);
  }

  final CheckStoragePermissionUseCase _checkStorage;
  final RequestStoragePermissionUseCase _requestStorage;
  final CheckStatusFolderPermissionUseCase _checkStatusFolder;
  final RequestStatusFolderPermissionUseCase _requestStatusFolder;

  Future<void> _onCheckRequested(
    PermissionsCheckRequested event,
    Emitter<PermissionsState> emit,
  ) async {
    emit(
      state.copyWith(status: PermissionViewStatus.checking, clearError: true),
    );
    final storageResult = await _checkStorage(NoParams.instance);
    await storageResult.fold(
      (failure) async => emit(
        state.copyWith(
          status: PermissionViewStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (hasStoragePermission) async {
        final folderResult = await _checkStatusFolder(
          PermissionCheckParams(isBusinessMode: event.isBusinessMode),
        );
        folderResult.fold(
          (failure) => emit(
            state.copyWith(
              status: PermissionViewStatus.failure,
              hasStoragePermission: hasStoragePermission,
              errorMessage: failure.message,
            ),
          ),
          (hasFolderPermission) => emit(
            state.copyWith(
              status: PermissionViewStatus.ready,
              hasStoragePermission: hasStoragePermission,
              regularStatusFolderPermission:
                  event.isBusinessMode
                      ? state.regularStatusFolderPermission
                      : hasFolderPermission,
              businessStatusFolderPermission:
                  event.isBusinessMode
                      ? hasFolderPermission
                      : state.businessStatusFolderPermission,
              clearError: true,
            ),
          ),
        );
      },
    );
  }

  Future<void> _onStorageRequested(
    StoragePermissionRequested event,
    Emitter<PermissionsState> emit,
  ) async {
    emit(state.copyWith(status: PermissionViewStatus.requesting));
    await AnalyticsService.track('storage_permission_requested');
    final result = await _requestStorage(NoParams.instance);
    await result.fold(
      (_) => AnalyticsService.track('storage_permission_failed'),
      (granted) => AnalyticsService.track('storage_permission_result', {
        'granted': granted,
      }),
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PermissionViewStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (granted) => emit(
        state.copyWith(
          status: PermissionViewStatus.ready,
          hasStoragePermission: granted,
          clearError: true,
        ),
      ),
    );
  }

  Future<void> _onStatusFolderRequested(
    StatusFolderPermissionRequested event,
    Emitter<PermissionsState> emit,
  ) async {
    emit(state.copyWith(status: PermissionViewStatus.requesting));
    final params = PermissionCheckParams(isBusinessMode: event.isBusinessMode);
    await AnalyticsService.track('request_whatsapp_folder_permission', {
      'business_mode': event.isBusinessMode,
    });
    final requestResult = await _requestStatusFolder(params);
    Future<void> recordOutcome(bool granted, {bool failed = false}) async {
      if (failed)
        await AnalyticsService.track('app_error_operation_failed', {
          'operation': 'folder_permission',
        });
      final name =
          event.isBusinessMode
              ? (granted
                  ? 'grant_business_folder_permission'
                  : 'denied_business_folder_permission')
              : (granted
                  ? 'grant_whatsapp_folder_permission'
                  : 'denied_whatsapp_folder_permission');
      await AnalyticsService.track(name);
    }

    await requestResult.fold(
      (failure) async {
        await recordOutcome(false, failed: true);
        emit(
          state.copyWith(
            status: PermissionViewStatus.failure,
            errorMessage: failure.message,
          ),
        );
      },
      (_) async {
        final checkResult = await _checkStatusFolder(params);
        await checkResult.fold(
          (_) => recordOutcome(false, failed: true),
          (granted) => recordOutcome(granted),
        );
        checkResult.fold(
          (failure) => emit(
            state.copyWith(
              status: PermissionViewStatus.failure,
              errorMessage: failure.message,
            ),
          ),
          (granted) => emit(
            state.copyWith(
              status: PermissionViewStatus.ready,
              regularStatusFolderPermission:
                  event.isBusinessMode
                      ? state.regularStatusFolderPermission
                      : granted,
              businessStatusFolderPermission:
                  event.isBusinessMode
                      ? granted
                      : state.businessStatusFolderPermission,
              clearError: true,
            ),
          ),
        );
      },
    );
  }
}
