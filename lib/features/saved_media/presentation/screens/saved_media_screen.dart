import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/routes_manager.dart';
import '../../../permissions/presentation/bloc/permissions_bloc/permissions_bloc.dart';
import '../../../statuses/presentation/screens/media_viewer_screen.dart';
import '../../domain/entities/saved_media.dart';
import '../bloc/saved_media_bloc/saved_media_bloc.dart';
import '../l10n/saved_media_strings.dart';
import '../widgets/saved_media_tile.dart';

class SavedMediaScreen extends StatefulWidget {
  const SavedMediaScreen({super.key});

  @override
  State<SavedMediaScreen> createState() => _SavedMediaScreenState();
}

class _SavedMediaScreenState extends State<SavedMediaScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocListener<SavedMediaBloc, SavedMediaState>(
      listenWhen:
          (previous, current) =>
              previous.message != current.message ||
              previous.resolvedGalleryPaths != current.resolvedGalleryPaths,
      listener: (context, state) {
        if (state.message != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message!)));
        }
        if (state.resolvedGalleryPaths.isNotEmpty) {
          Navigator.pushNamed(
            context,
            Routes.mediaViewer,
            arguments: MediaViewerArguments(
              paths: state.resolvedGalleryPaths,
              initialIndex: state.resolvedGalleryInitialIndex,
              isVideo: false,
              videoFlags: state.resolvedGalleryVideoFlags,
              allowSave: false,
            ),
          );
          context.read<SavedMediaBloc>().add(
            const SavedMediaNavigationHandled(),
          );
        }
      },
      child: BlocBuilder<PermissionsBloc, PermissionsState>(
        builder: (context, permissions) {
          if (!permissions.hasStoragePermission) {
            return const Center(
              child: Text(SavedMediaStrings.noStoragePermission),
            );
          }
          return BlocBuilder<SavedMediaBloc, SavedMediaState>(
            builder: (context, state) {
              if (state.isLoading && state.items.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.items.isEmpty) {
                return const Center(child: Text(SavedMediaStrings.empty));
              }
              return NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification.metrics.extentAfter < 500 &&
                      state.hasMore &&
                      !state.isLoadingMore) {
                    context.read<SavedMediaBloc>().add(
                      const SavedMediaMoreRequested(),
                    );
                  }
                  return false;
                },
                child: RefreshIndicator(
                  onRefresh: () async {
                    final bloc = context.read<SavedMediaBloc>();
                    bloc.add(const SavedMediaLoadRequested());
                    await bloc.stream.firstWhere((state) => !state.isLoading);
                  },
                  child: CustomScrollView(
                    slivers: <Widget>[
                      SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 300,
                              crossAxisSpacing: 5,
                              mainAxisSpacing: 8,
                              childAspectRatio: 0.95,
                            ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final media = state.items[index];
                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: SavedMediaTile(
                              key: ValueKey(media.id),
                              media: media,
                              onTap:
                                  () => context.read<SavedMediaBloc>().add(
                                    SavedMediaGalleryOpenRequested(index),
                                  ),
                              onDelete: () => _confirmDelete(context, media),
                            ),
                          );
                        }, childCount: state.items.length),
                      ),
                      if (state.isLoadingMore)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ),
                      const SliverToBoxAdapter(child: SizedBox(height: 20)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, SavedMedia media) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text(SavedMediaStrings.deleteTitle),
            content: const Text(SavedMediaStrings.deleteMessage),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text(
                  SavedMediaStrings.cancel,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text(
                  SavedMediaStrings.ok,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
    if (confirmed == true && context.mounted) {
      context.read<SavedMediaBloc>().add(SavedMediaDeleteRequested(media.id));
    }
  }
}
