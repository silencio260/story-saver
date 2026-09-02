import 'package:equatable/equatable.dart';

enum SavedMediaType { image, video }

class SavedMedia extends Equatable {
  const SavedMedia({required this.id, required this.title, required this.type});

  final String id;
  final String title;
  final SavedMediaType type;

  bool get isVideo => type == SavedMediaType.video;

  @override
  List<Object?> get props => <Object?>[id, title, type];
}
