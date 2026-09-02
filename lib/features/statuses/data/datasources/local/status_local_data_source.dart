import '../../../domain/entities/status_collection.dart';
import '../../../domain/entities/status_media.dart';
import 'status_base_local_data_source.dart';
import 'status_file_system_data_source_engine.dart';

export 'status_base_local_data_source.dart';

class StatusLocalDataSource implements StatusBaseLocalDataSource {
  StatusLocalDataSource({
    required StatusFileSystemDataSourceEngine statusEngine,
  }) : _statusEngine = statusEngine;

  final StatusFileSystemDataSourceEngine _statusEngine;

  @override
  Future<StatusCollection> loadStatuses() async {
    await _statusEngine.checkIsBusinessMode();
    await _statusEngine.getAllStatusesWithSaf();
    return _snapshot();
  }

  @override
  Future<bool> getBusinessMode() async {
    await _statusEngine.checkIsBusinessMode();
    return _statusEngine.isBusinessMode;
  }

  @override
  Future<bool> setBusinessMode(bool enabled) async {
    await _statusEngine.setIsBusinessMode(enabled);
    return _statusEngine.isBusinessMode;
  }

  @override
  Future<void> clearCache() => _statusEngine.clearCacheFromDisk();

  @override
  Future<String> generateVideoThumbnail(String videoPath) => _statusEngine
      .generateThumbnailFromListAllVideosForFutureBuilder(videoPath);

  StatusCollection _snapshot() => StatusCollection(
    images: _statusEngine.getImages
        .map(
          (file) => StatusMedia(path: file.path, type: StatusMediaType.image),
        )
        .toList(growable: false),
    videos: _statusEngine.getVideos
        .map(
          (file) => StatusMedia(path: file.path, type: StatusMediaType.video),
        )
        .toList(growable: false),
    isBusinessMode: _statusEngine.isBusinessMode,
    isWhatsAppAvailable: _statusEngine.isWhatsappAvailable,
  );
}
