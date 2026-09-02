import '../../models/saved_media_model.dart';

class SavedMediaDataPage {
  const SavedMediaDataPage({required this.items, required this.hasMore});

  final List<SavedMediaModel> items;
  final bool hasMore;
}
