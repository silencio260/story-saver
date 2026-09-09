import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';

import '../../../../config/routes_manager.dart';
import '../../../monetization/presentation/bloc/ads_bloc/ads_bloc.dart';
import '../../../monetization/presentation/bloc/iap_bloc/iap_bloc.dart';
import '../../../monetization/presentation/controllers/legacy/ad_suppression_manager.dart';
import '../../../monetization/presentation/widgets/legacy/premium_upgrade_modal.dart';
import '../../../permissions/presentation/bloc/permissions_bloc/permissions_bloc.dart';
import '../../../saved_media/presentation/bloc/saved_media_bloc/saved_media_bloc.dart';
import '../../../settings/presentation/services/rating_prompt.dart';
import '../../domain/entities/status_media.dart';
import '../bloc/status_bloc/status_bloc.dart';
import '../l10n/status_strings.dart';
import '../screens/media_viewer_screen.dart';

class StatusGrid extends StatefulWidget {
  const StatusGrid({required this.type, super.key});

  final StatusMediaType type;

  @override
  State<StatusGrid> createState() => _StatusGridState();
}

class _StatusGridState extends State<StatusGrid>
    with AutomaticKeepAliveClientMixin {
  final RefreshController _refreshController = RefreshController();

  bool get _isVideo => widget.type == StatusMediaType.video;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final bloc = context.read<StatusBloc>();
    bloc.add(const StatusLoadRequested());
    try {
      await bloc.stream.firstWhere((state) => !state.isLoading);
      _refreshController.refreshCompleted();
    } catch (_) {
      _refreshController.refreshFailed();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<PermissionsBloc, PermissionsState>(
      builder:
          (context, permissions) => BlocBuilder<StatusBloc, StatusState>(
            builder: (context, statusState) {
              final isBusinessMode = statusState.isBusinessMode;
              if (!permissions.hasStoragePermission) {
                return _PermissionPrompt(
                  message: StatusStrings.noStoragePermission,
                  onPressed:
                      () => context.read<PermissionsBloc>().add(
                        const StoragePermissionRequested(),
                      ),
                );
              }
              if (!permissions.hasStatusFolderPermission(
                isBusinessMode: isBusinessMode,
              )) {
                return _PermissionPrompt(
                  message:
                      isBusinessMode
                          ? StatusStrings.grantBusinessStatuses
                          : StatusStrings.grantAndroidMedia,
                  onPressed:
                      () => Navigator.pushNamed(
                        context,
                        Routes.statusFolderPermission,
                        arguments: isBusinessMode,
                      ),
                );
              }
              if (!statusState.collection.isWhatsAppAvailable) {
                return _RefreshMessage(
                  message:
                      isBusinessMode
                          ? StatusStrings.businessWhatsAppUnavailable
                          : StatusStrings.whatsAppUnavailable,
                );
              }
              final items = _isVideo ? statusState.videos : statusState.images;
              if (statusState.isLoading && items.isEmpty) {
                return const Center(child: Text(StatusStrings.loading));
              }
              if (items.isEmpty) {
                return _RefreshMessage(
                  message:
                      _isVideo
                          ? StatusStrings.noVideosFound
                          : StatusStrings.noImagesFound,
                );
              }
              final paths = items.map((item) => item.path).toList();
              return Padding(
                padding: const EdgeInsets.all(5),
                child: SmartRefresher(
                  controller: _refreshController,
                  onRefresh: _refresh,
                  physics:
                      _isVideo
                          ? const ClampingScrollPhysics()
                          : const AlwaysScrollableScrollPhysics(),
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
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _StatusTile(
                            key: ValueKey(items[index].path),
                            item: items[index],
                            itemIndex: index,
                            allPaths: paths,
                          ),
                          childCount: items.length,
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 20)),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }
}

class _PermissionPrompt extends StatelessWidget {
  const _PermissionPrompt({required this.message, required this.onPressed});

  final String message;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(message, textAlign: TextAlign.center),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          onPressed: onPressed,
          child: const Text(
            StatusStrings.grantPermission,
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
  );
}

class _RefreshMessage extends StatelessWidget {
  const _RefreshMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black, fontSize: 16),
        children: <InlineSpan>[
          TextSpan(text: '$message. '),
          TextSpan(
            text: StatusStrings.clickToRefresh,
            style: const TextStyle(
              color: Colors.blue,
              decoration: TextDecoration.underline,
            ),
            recognizer:
                TapGestureRecognizer()
                  ..onTap =
                      () => context.read<StatusBloc>().add(
                        const StatusLoadRequested(),
                      ),
          ),
        ],
      ),
    ),
  );
}

class _StatusTile extends StatefulWidget {
  const _StatusTile({
    required this.item,
    required this.itemIndex,
    required this.allPaths,
    super.key,
  });

  final StatusMedia item;
  final int itemIndex;
  final List<String> allPaths;

  @override
  State<_StatusTile> createState() => _StatusTileState();
}

class _StatusTileState extends State<_StatusTile> {
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.item.isVideo) {
      context.read<StatusBloc>().add(
        StatusThumbnailRequested(widget.item.path),
      );
    }
    context.read<SavedMediaBloc>().add(
      StatusSavedCheckRequested(widget.item.path),
    );
  }

  Future<void> _download() async {
    if (_isSaving) return;
    if (!await File(widget.item.path).exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(StatusStrings.fileMissing)),
        );
      }
      return;
    }

    final isPremium = context.read<IapBloc>().state.isPremium;
    if (!isPremium && widget.itemIndex >= StatusStrings.freeItemLimit) {
      await AdSuppressionManager().withAdsSuppressed(
        reason: 'premium_download_flow',
        action: () async {
          final shouldUpgrade = await showPremiumUpgradeModal(context);
          if (shouldUpgrade == true && mounted) {
            final iapBloc = context.read<IapBloc>();
            final paywallFinished = iapBloc.stream.firstWhere(
              (state) =>
                  state.status == IapViewStatus.ready ||
                  state.status == IapViewStatus.failure,
            );
            iapBloc.add(const IapPaywallRequested());
            await paywallFinished;
          } else if (shouldUpgrade == false && mounted) {
            context.read<AdsBloc>().add(const InterstitialAdRequested());
          }
        },
      );
      return;
    }

    setState(() => _isSaving = true);
    context.read<SavedMediaBloc>().add(StatusSaveRequested(widget.item.path));
    await RatingPrompt.recordDownload(context);
  }

  void _openViewer() {
    Navigator.pushNamed(
      context,
      Routes.mediaViewer,
      arguments: MediaViewerArguments(
        paths: widget.allPaths,
        initialIndex: widget.itemIndex,
        isVideo: widget.item.isVideo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<SavedMediaBloc, SavedMediaState>(
        listenWhen: (previous, current) => previous.message != current.message,
        listener: (context, state) {
          if (_isSaving && mounted) setState(() => _isSaving = false);
        },
        child: Builder(
          builder: (context) {
            final isSaved = context.select<SavedMediaBloc, bool>(
              (bloc) => bloc.state.savedSourcePaths.contains(widget.item.path),
            );
            final isPremium = context.select<IapBloc, bool>(
              (bloc) => bloc.state.isPremium,
            );
            return GestureDetector(
              onTap: _openViewer,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  _StatusThumbnail(item: widget.item),
                  const Positioned(
                    right: 0,
                    bottom: 0,
                    left: 0,
                    height: 40,
                    child: ColoredBox(color: Color.fromRGBO(0, 0, 0, 0.3)),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    width: 100,
                    height: 50,
                    child: InkWell(
                      onTap: _download,
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: SizedBox(
                          width: 50,
                          height: 50,
                          child: Icon(
                            isSaved
                                ? Icons.done_all
                                : _isSaving
                                ? Icons.downloading
                                : Icons.download,
                            color:
                                isSaved
                                    ? Colors.green
                                    : Colors.white.withOpacity(
                                      isPremium ||
                                              widget.itemIndex <
                                                  StatusStrings.freeItemLimit
                                          ? 1
                                          : 0.4,
                                    ),
                            size: isSaved ? 20 : 23,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (widget.item.isVideo)
                    const Positioned(
                      top: 10,
                      left: 10,
                      child: Icon(
                        Icons.videocam_sharp,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      );
}

class _StatusThumbnail extends StatelessWidget {
  const _StatusThumbnail({required this.item});

  final StatusMedia item;

  @override
  Widget build(BuildContext context) {
    if (!item.isVideo) return Image.file(File(item.path), fit: BoxFit.cover);
    return BlocBuilder<StatusBloc, StatusState>(
      buildWhen:
          (previous, current) =>
              previous.thumbnails[item.path] != current.thumbnails[item.path] ||
              previous.thumbnailFailures.contains(item.path) !=
                  current.thumbnailFailures.contains(item.path),
      builder: (context, state) {
        final thumbnail = state.thumbnails[item.path];
        if (thumbnail != null) {
          return Image.file(File(thumbnail), fit: BoxFit.cover);
        }
        if (state.thumbnailFailures.contains(item.path)) {
          return const ColoredBox(
            color: Colors.black12,
            child: Center(child: Icon(Icons.broken_image, color: Colors.grey)),
          );
        }
        return const ColoredBox(
          color: Colors.black12,
          child: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
