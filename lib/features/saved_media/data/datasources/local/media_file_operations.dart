import 'dart:io';

import 'package:media_scanner/media_scanner.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:photo_manager/photo_manager.dart';

import 'device_directory.dart';

final Set<String> _filesBeingSaved = <String>{};

Future<bool> saveStatusBackground(String sourcePath) async {
  if (!_filesBeingSaved.add(sourcePath)) return false;
  try {
    final source = File(sourcePath);
    if (!await source.exists()) return false;

    final fileName = source.uri.pathSegments.last;
    final extension = fileName.split('.').last.toLowerCase();
    final directoryInfo = DeviceFileInfo();
    final absoluteDirectory = await directoryInfo.GetSavedMediaAbsolutePath();
    await Directory(absoluteDirectory).create(recursive: true);

    await _deleteExistingMedia(
      fileName: fileName,
      appFolder: absoluteDirectory.split('/').last,
      extension: extension,
    );

    final relativeDirectory = await directoryInfo.GetSavedMediaBasedOnDevice();
    AssetEntity? savedMedia;
    if (_imageExtensions.contains(extension)) {
      savedMedia = await PhotoManager.editor.saveImageWithPath(
        sourcePath,
        title: fileName,
        relativePath: relativeDirectory,
      );
    } else if (_videoExtensions.contains(extension)) {
      savedMedia = await PhotoManager.editor.saveVideo(
        source,
        title: fileName,
        relativePath: relativeDirectory,
      );
    } else {
      return false;
    }

    final savedAsset = savedMedia;
    if (savedAsset == null || !await savedAsset.exists) return false;
    final savedFile = await savedAsset.file;
    if (savedFile != null) {
      try {
        await MediaScanner.loadMedia(path: savedFile.path);
      } catch (_) {
        // The media is already saved; scanner support differs by device.
      }
    }
    return true;
  } finally {
    _filesBeingSaved.remove(sourcePath);
  }
}

Future<void> _deleteExistingMedia({
  required String fileName,
  required String appFolder,
  required String extension,
}) async {
  MediaStore.appFolder = appFolder;
  final mediaStore = MediaStore();
  final DirType? type =
      _imageExtensions.contains(extension)
          ? DirType.photo
          : _videoExtensions.contains(extension)
          ? DirType.video
          : null;
  if (type == null) return;
  final uri = await mediaStore.getFileUri(
    fileName: fileName,
    dirType: type,
    dirName: DirName.pictures,
  );
  if (uri != null) {
    await mediaStore.deleteFileUsingUri(uriString: uri.toString());
  }
}

const Set<String> _imageExtensions = <String>{
  'jpg',
  'jpeg',
  'png',
  'gif',
  'bmp',
  'webp',
  'heic',
};

const Set<String> _videoExtensions = <String>{
  'mp4',
  'mov',
  'avi',
  'mkv',
  'webm',
  'flv',
};
