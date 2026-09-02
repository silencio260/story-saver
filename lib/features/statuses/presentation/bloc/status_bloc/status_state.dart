part of 'status_bloc.dart';

enum StatusViewStatus { initial, loading, success, failure }

class StatusState extends Equatable {
  const StatusState({
    this.status = StatusViewStatus.initial,
    this.collection = const StatusCollection(
      images: <StatusMedia>[],
      videos: <StatusMedia>[],
      isBusinessMode: false,
      isWhatsAppAvailable: false,
    ),
    this.thumbnails = const <String, String>{},
    this.thumbnailFailures = const <String>{},
    this.message,
  });

  final StatusViewStatus status;
  final StatusCollection collection;
  final Map<String, String> thumbnails;
  final Set<String> thumbnailFailures;
  final String? message;

  bool get isLoading => status == StatusViewStatus.loading;
  List<StatusMedia> get images => collection.images;
  List<StatusMedia> get videos => collection.videos;
  bool get isBusinessMode => collection.isBusinessMode;

  StatusState copyWith({
    StatusViewStatus? status,
    StatusCollection? collection,
    Map<String, String>? thumbnails,
    Set<String>? thumbnailFailures,
    String? message,
    bool clearMessage = false,
  }) => StatusState(
    status: status ?? this.status,
    collection: collection ?? this.collection,
    thumbnails: thumbnails ?? this.thumbnails,
    thumbnailFailures: thumbnailFailures ?? this.thumbnailFailures,
    message: clearMessage ? null : message ?? this.message,
  );

  @override
  List<Object?> get props => <Object?>[
    status,
    collection,
    thumbnails,
    thumbnailFailures,
    message,
  ];
}
