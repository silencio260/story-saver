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
