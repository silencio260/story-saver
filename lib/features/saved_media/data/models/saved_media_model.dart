import 'package:photo_manager/photo_manager.dart';

import '../../domain/entities/saved_media.dart';

class SavedMediaModel extends SavedMedia {
  const SavedMediaModel({
    required super.id,
    required super.title,
    required super.type,
    required this.asset,
  });

  final AssetEntity asset;

  factory SavedMediaModel.fromAsset(AssetEntity asset) => SavedMediaModel(
    id: asset.id,
    title: asset.title ?? asset.id,
    type:
        asset.type == AssetType.video
            ? SavedMediaType.video
            : SavedMediaType.image,
    asset: asset,
  );

  SavedMedia toDomain() => SavedMedia(id: id, title: title, type: type);
}
