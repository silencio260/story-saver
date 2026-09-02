import 'package:equatable/equatable.dart';

import 'status_media.dart';

class StatusCollection extends Equatable {
  const StatusCollection({
    required this.images,
    required this.videos,
    required this.isBusinessMode,
    required this.isWhatsAppAvailable,
  });

  final List<StatusMedia> images;
  final List<StatusMedia> videos;
  final bool isBusinessMode;
  final bool isWhatsAppAvailable;

  @override
  List<Object?> get props => <Object?>[
    images,
    videos,
    isBusinessMode,
    isWhatsAppAvailable,
  ];
}
