import 'dart:typed_data';

import 'saved_media_data_page.dart';

abstract class SavedMediaBaseLocalDataSource {
  Future<SavedMediaDataPage> load({required bool reset});

  Future<String> resolveFilePath(String id);

  Future<Uint8List> loadThumbnail(String id);

  Future<void> delete(String id);

  Future<void> deleteAll();

  Future<bool> saveStatus(String sourcePath);

  Future<bool> isStatusSaved(String sourcePath);

  Future<void> share(String path);
}
