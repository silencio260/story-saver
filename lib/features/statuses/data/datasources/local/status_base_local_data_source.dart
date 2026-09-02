import '../../../domain/entities/status_collection.dart';

abstract class StatusBaseLocalDataSource {
  Future<StatusCollection> loadStatuses();

  Future<bool> getBusinessMode();

  Future<bool> setBusinessMode(bool enabled);

  Future<void> clearCache();

  Future<String> generateVideoThumbnail(String videoPath);
}
