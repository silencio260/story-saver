import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';

import '../../../../config/routes_manager.dart';
import '../../../permissions/data/services/status_connection_journey.dart';
import '../../../navigation/presentation/bloc/navigation_bloc/navigation_bloc.dart';
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
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  final RefreshController _refreshController = RefreshController();

  bool _openingWhatsApp = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _openingWhatsApp && mounted) {
      _openingWhatsApp = false;
      context.read<StatusBloc>().add(const StatusLoadRequested());
    }
  }

  Future<void> _openWhatsApp(bool business) async {
    _openingWhatsApp = true;
    final opened = await StatusConnectionJourney.openWhatsApp(
      business: business,
    );
    if (!opened) {
      _openingWhatsApp = false;
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open WhatsApp. Open it from your home screen.',
            ),
          ),
        );
    }
  }

  bool get _isVideo => widget.type == StatusMediaType.video;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final bloc = context.read<StatusBloc>();
    bloc.add(const StatusLoadRequested());
    try {
      final result = await bloc.stream.firstWhere(
        (state) =>
            state.status == StatusViewStatus.success ||
            state.status == StatusViewStatus.failure,
      );
      if (!mounted) return;
      if (result.status == StatusViewStatus.failure) {
        _refreshController.refreshFailed();
      } else {
        _refreshController.refreshCompleted();
      }
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
              if (!statusState.collection.isWhatsAppAvailable &&
                  !statusState.isLoading) {
                return _RefreshMessage(
                  message:
                      'View a status in ${isBusinessMode ? 'WhatsApp Business' : 'WhatsApp'}, then come back.',
                  onOpen: () => _openWhatsApp(isBusinessMode),
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
                  onOpen: () => _openWhatsApp(isBusinessMode),
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
  const _RefreshMessage({required this.message, required this.onOpen});
  final String message;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.visibility_outlined, size: 48),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onOpen,
            child: Text(
              context.read<StatusBloc>().state.isBusinessMode
                  ? 'Open WhatsApp Business'
                  : 'Open WhatsApp',
            ),
          ),
          TextButton(
            onPressed:
                () =>
                    context.read<StatusBloc>().add(const StatusLoadRequested()),
            child: const Text('Refresh statuses'),
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

  void _recordDisplayed(BuildContext context) {
    final business = context.read<StatusBloc>().state.isBusinessMode;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted &&
          ModalRoute.of(context)?.isCurrent == true &&
          context.read<NavigationBloc>().state.currentIndex ==
              (item.isVideo ? 1 : 0) &&
          TickerMode.of(context)) {
        unawaited(
          StatusConnectionJourney.instance.displayed(business: business),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // A previously decoded off-screen tab must get another visibility check
    // when selected; cached thumbnail frames may not otherwise rebuild.
    context.select<NavigationBloc, int>((bloc) => bloc.state.currentIndex);
    if (!item.isVideo) {
      return Image.file(
        File(item.path),
        fit: BoxFit.cover,
        cacheWidth: 600,
        frameBuilder: (context, child, frame, synchronous) {
          if (frame != null || synchronous) _recordDisplayed(context);
          return child;
        },
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
      );
    }
    return BlocBuilder<StatusBloc, StatusState>(
      buildWhen:
          (previous, current) =>
              previous.thumbnails[item.path] != current.thumbnails[item.path] ||
              previous.thumbnailFailures.contains(item.path) !=
                  current.thumbnailFailures.contains(item.path),
      builder: (context, state) {
        final thumbnail = state.thumbnails[item.path];
        if (thumbnail != null) {
          return Image.file(
            File(thumbnail),
            fit: BoxFit.cover,
            cacheWidth: 600,
            frameBuilder: (context, child, frame, synchronous) {
              if (frame != null || synchronous) _recordDisplayed(context);
              return child;
            },
          );
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
