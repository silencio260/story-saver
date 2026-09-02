part of 'settings_bloc.dart';

enum SettingsViewStatus { initial, loading, ready, failure }

class SettingsState extends Equatable {
  const SettingsState({
    this.status = SettingsViewStatus.initial,
    this.settings = const AppSettings(autoSaveEnabled: false),
    this.message,
  });

  final SettingsViewStatus status;
  final AppSettings settings;
  final String? message;

  SettingsState copyWith({
    SettingsViewStatus? status,
    AppSettings? settings,
    String? message,
    bool clearMessage = false,
  }) => SettingsState(
    status: status ?? this.status,
    settings: settings ?? this.settings,
    message: clearMessage ? null : message ?? this.message,
  );

  @override
  List<Object?> get props => <Object?>[status, settings, message];
}
