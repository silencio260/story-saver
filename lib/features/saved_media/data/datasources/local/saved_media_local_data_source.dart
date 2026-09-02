import 'dart:typed_data';

import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../core/utils/legacy_app_constants.dart' as legacy;
import '../../models/saved_media_model.dart';
import 'media_file_operations.dart' as legacy_save;
import 'saved_media_base_local_data_source.dart';
import 'saved_media_cache.dart';
import 'saved_media_data_page.dart';

export 'saved_media_base_local_data_source.dart';
export 'saved_media_data_page.dart';

class SavedMediaLocalDataSource implements SavedMediaBaseLocalDataSource {
  SavedMediaLocalDataSource({required SavedMediaManager cacheManager})
    : _cacheManager = cacheManager;

  static const int _pageSize = 50;

  final SavedMediaManager _cacheManager;
  final Map<String, AssetEntity> _assets = <String, AssetEntity>{};
  AssetPathEntity? _album;
  int _offset = 0;

  @override
  Future<SavedMediaDataPage> load({required bool reset}) async {
    if (reset) {
      _offset = 0;
      _assets.clear();
      _album = null;
    }

    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) {
      throw StateError('Storage permission is required.');
    }

    final album = _album ??= await _findAlbum();
    if (album == null) {
      return const SavedMediaDataPage(
        items: <SavedMediaModel>[],
        hasMore: false,
      );
    }

    final total = await album.assetCountAsync;
    final end = (_offset + _pageSize).clamp(0, total);
    if (_offset < total) {
      final page = await album.getAssetListRange(start: _offset, end: end);
      for (final asset in page) {
        _assets[asset.id] = asset;
      }
      _offset = end;
    }

    return SavedMediaDataPage(
      items: _assets.values.map(SavedMediaModel.fromAsset).toList(),
      hasMore: _offset < total,
    );
  }

  @override
  Future<String> resolveFilePath(String id) async {
    final asset = _requireAsset(id);
    final file = await asset.file;
    if (file == null) throw StateError('The media file is unavailable.');
    return file.path;
  }

  @override
  Future<Uint8List> loadThumbnail(String id) async {
    final bytes = await _requireAsset(
      id,
    ).thumbnailDataWithSize(const ThumbnailSize(500, 500));
    if (bytes == null) throw StateError('The media thumbnail is unavailable.');
    return bytes;
  }

  @override
  Future<void> delete(String id) async {
    final asset = _requireAsset(id);
    final deleted = await PhotoManager.editor.deleteWithIds(<String>[id]);
    if (deleted.isEmpty) throw StateError('The media could not be deleted.');
    await _cacheManager.deleteMediaFromCache(asset.title ?? id);
    _assets.remove(id);
    PhotoManager.clearFileCache();
  }

  @override
  Future<void> deleteAll() async {
    await _cacheManager.deleteAllSavedContent();
    _assets.clear();
    _album = null;
    _offset = 0;
    PhotoManager.clearFileCache();
  }

  @override
  Future<bool> saveStatus(String sourcePath) async {
    final saved = await legacy_save.saveStatusBackground(sourcePath);
    if (saved) await _cacheManager.saveMedia(sourcePath);
    return saved;
  }

  @override
  Future<bool> isStatusSaved(String sourcePath) =>
      _cacheManager.isMediaSaved(sourcePath);

  @override
  Future<void> share(String path) async {
    await Share.shareXFiles(
      <XFile>[XFile(path)],
      text:
          'Shared From WhatsApp Status Saver App @ ${legacy.AppConstants().GOOGLE_PLAY_STORE_LINK}',
    );
  }

  Future<AssetPathEntity?> _findAlbum() async {
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.fromTypes(<RequestType>[
        RequestType.image,
        RequestType.video,
      ]),
    );
    for (final album in albums) {
      if (album.name == legacy.AppConstants.SAVED_STORY_PATH) return album;
    }
    return null;
  }

  AssetEntity _requireAsset(String id) {
    final asset = _assets[id];
    if (asset == null) throw StateError('The media item is unavailable.');
    return asset;
  }
}
