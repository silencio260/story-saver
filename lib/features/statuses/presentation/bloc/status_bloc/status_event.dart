part of 'status_bloc.dart';

sealed class StatusEvent extends Equatable {
  const StatusEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

class StatusLoadRequested extends StatusEvent {
  const StatusLoadRequested();
}

class StatusBusinessModeRequested extends StatusEvent {
  const StatusBusinessModeRequested({
    this.enabled,
    this.reloadStatuses = false,
  });

  final bool? enabled;
  final bool reloadStatuses;

  @override
  List<Object?> get props => <Object?>[enabled, reloadStatuses];
}

class StatusCacheClearRequested extends StatusEvent {
  const StatusCacheClearRequested();
}

class StatusThumbnailRequested extends StatusEvent {
  const StatusThumbnailRequested(this.videoPath);

  final String videoPath;

  @override
  List<Object?> get props => <Object?>[videoPath];
}
