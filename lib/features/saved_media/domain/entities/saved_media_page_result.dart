import 'package:equatable/equatable.dart';

import 'saved_media.dart';

class SavedMediaPageResult extends Equatable {
  const SavedMediaPageResult({required this.items, required this.hasMore});

  final List<SavedMedia> items;
  final bool hasMore;

  @override
  List<Object?> get props => <Object?>[items, hasMore];
}
