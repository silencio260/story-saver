import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:storysaver/features/analytics/data/services/analytics_service.dart';

import '../../../../../core/usecase/base_usecase.dart';
import '../../../domain/entities/app_settings.dart';
import '../../../domain/usecases/contact_support_usecase.dart';
import '../../../domain/usecases/load_settings_usecase.dart';
import '../../../domain/usecases/rate_app_usecase.dart';
import '../../../domain/usecases/set_auto_save_usecase.dart';
import '../../../domain/usecases/share_app_usecase.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({
    required LoadSettingsUseCase loadSettingsUseCase,
    required SetAutoSaveUseCase setAutoSaveUseCase,
    required ShareAppUseCase shareAppUseCase,
    required RateAppUseCase rateAppUseCase,
    required ContactSupportUseCase contactSupportUseCase,
  }) : _loadSettings = loadSettingsUseCase,
       _setAutoSave = setAutoSaveUseCase,
       _shareApp = shareAppUseCase,
       _rateApp = rateAppUseCase,
       _contactSupport = contactSupportUseCase,
       super(const SettingsState()) {
    on<SettingsLoadRequested>(_onLoadRequested);
    on<AutoSaveChanged>(_onAutoSaveChanged);
    on<AppShareRequested>((event, emit) => _runAction(_shareApp, emit));
    on<AppRatingRequested>((event, emit) => _runAction(_rateApp, emit));
    on<SupportContactRequested>(
      (event, emit) => _runAction(_contactSupport, emit),
    );
  }

  final LoadSettingsUseCase _loadSettings;
  final SetAutoSaveUseCase _setAutoSave;
  final ShareAppUseCase _shareApp;
  final RateAppUseCase _rateApp;
  final ContactSupportUseCase _contactSupport;

  Future<void> _onLoadRequested(
    SettingsLoadRequested event,
    Emitter<SettingsState> emit,
  ) async {
    emit(
      state.copyWith(status: SettingsViewStatus.loading, clearMessage: true),
    );
    final result = await _loadSettings(NoParams.instance);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: SettingsViewStatus.failure,
          message: failure.message,
        ),
      ),
      (settings) => emit(
        state.copyWith(
          status: SettingsViewStatus.ready,
          settings: settings,
          clearMessage: true,
        ),
      ),
    );
  }

  Future<void> _onAutoSaveChanged(
    AutoSaveChanged event,
    Emitter<SettingsState> emit,
  ) async {
    final result = await _setAutoSave(event.enabled);
    await result.fold(
      (_) => AnalyticsService.track('auto_save_setting_failed', {
        'enabled': event.enabled,
      }),
      (_) => AnalyticsService.track(
        event.enabled ? 'auto_save_enabled' : 'auto_save_disabled',
      ),
    );
    result.fold(
      (failure) => emit(state.copyWith(message: failure.message)),
      (settings) => emit(
        state.copyWith(
          status: SettingsViewStatus.ready,
          settings: settings,
          clearMessage: true,
        ),
      ),
    );
  }

  Future<void> _runAction(
    BaseUseCase<dynamic, NoParams> operation,
    Emitter<SettingsState> emit,
  ) async {
    final result = await operation(NoParams.instance);
    result.fold(
      (failure) => emit(state.copyWith(message: failure.message)),
      (_) => emit(state.copyWith(clearMessage: true)),
    );
  }
}
