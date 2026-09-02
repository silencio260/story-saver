import 'package:equatable/equatable.dart';

enum StatusMediaType { image, video }

class StatusMedia extends Equatable {
  const StatusMedia({required this.path, required this.type});

  final String path;
  final StatusMediaType type;

  bool get isVideo => type == StatusMediaType.video;

  @override
  List<Object?> get props => <Object?>[path, type];
}
