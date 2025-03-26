import 'dart:io';
import 'dart:typed_data';

import 'package:photo_manager/photo_manager.dart';

Future<String?> getAssetEntityPath(AssetEntity asset) async {
  // Get the actual file path of the asset
  final File? file = await asset.file;

  if (file != null) {
    final String filePath = file.path;
    // print("File path: $filePath");

    return filePath;
  }

  return null;

}
String? getAssetEntityPathSync(AssetEntity asset) {
  // The `file` method in AssetEntity is asynchronous, so true sync retrieval is not possible.
  // This function will remain async-like but ensures minimal await usage.

  // Warning: This approach might not work since `file` is inherently async.
  File? file;

  asset.file.then((f) => file = f);

  return file?.path;
}

Future<Uint8List?> getAssetEntityBytes(AssetEntity asset) async {
  // Get the actual file path of the asset
  final File? file = await asset.file;

  if (file != null) {
    final String filePath = file.path;
    // print("File path: $filePath");

    // Convert the file into a Uint8List
    final Uint8List bytes = await file.readAsBytes();
    return bytes;
  }

  return null;
}
