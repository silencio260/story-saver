import 'package:equatable/equatable.dart';

class AppSettings extends Equatable {
  const AppSettings({required this.autoSaveEnabled});

  final bool autoSaveEnabled;

  @override
  List<Object?> get props => <Object?>[autoSaveEnabled];
}
