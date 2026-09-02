part of 'settings_bloc.dart';

sealed class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

class SettingsLoadRequested extends SettingsEvent {
  const SettingsLoadRequested();
}

class AutoSaveChanged extends SettingsEvent {
  const AutoSaveChanged(this.enabled);
  final bool enabled;
  @override
  List<Object?> get props => <Object?>[enabled];
}

class AppShareRequested extends SettingsEvent {
  const AppShareRequested();
}

class AppRatingRequested extends SettingsEvent {
  const AppRatingRequested();
}

class SupportContactRequested extends SettingsEvent {
  const SupportContactRequested();
}
