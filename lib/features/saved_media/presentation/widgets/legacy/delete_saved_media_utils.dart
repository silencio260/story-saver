import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/saved_media_bloc/saved_media_bloc.dart';

/// BLoC-backed compatibility version of the original deletion helper.
class deleteSavedMeidaUtils {
  void confirmFileDeleteDialog(
    BuildContext context,
    String message,
    String mediaId,
  ) {
    Future<void>.delayed(Duration.zero, () async {
      if (!context.mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (dialogContext) => AlertDialog(
              backgroundColor: Colors.white,
              title: const Text('Confirm'),
              content: Text(message),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('OK', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
      );
      if (confirmed == true && context.mounted) {
        deleteMedia(context, mediaId);
      }
    });
  }

  void deleteMedia(BuildContext context, String mediaId) {
    context.read<SavedMediaBloc>().add(SavedMediaDeleteRequested(mediaId));
  }

  void confirmDeleteAllDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('Confirm Delete All'),
            content: const Text(
              'Are you sure you want to delete ALL saved media? This action cannot be undone.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  deleteAllMedia(context);
                },
                child: const Text(
                  'Delete All',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> deleteAllMedia(
    BuildContext context, {
    bool showCompletionSnackBar = true,
  }) async {
    final bloc = context.read<SavedMediaBloc>();
    final completion = bloc.stream.firstWhere((state) => state.items.isEmpty);
    bloc.add(const SavedMediaDeleteAllRequested());
    await completion;
    if (showCompletionSnackBar && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All media deleted successfully')),
      );
    }
  }
}
