import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:storysaver/features/analytics/data/services/analytics_service.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/utils/legacy_app_constants.dart';
import '../../../../core/utils/legacy_custom_colors.dart';
import '../../../monetization/presentation/bloc/ads_bloc/ads_bloc.dart';
import '../../../monetization/presentation/bloc/iap_bloc/iap_bloc.dart';
import '../../../monetization/presentation/controllers/legacy/ad_suppression_manager.dart';
import '../../../monetization/presentation/widgets/banner_ad_widget.dart';
import '../../../monetization/presentation/widgets/legacy/premium_upgrade_modal.dart';
import '../../../saved_media/presentation/bloc/saved_media_bloc/saved_media_bloc.dart';
import '../../../saved_media/presentation/services/legacy/share_to_app.dart';
import '../../../settings/presentation/services/rating_prompt.dart';
import '../l10n/status_strings.dart';
import 'media_viewer_arguments.dart';

export 'media_viewer_arguments.dart';

class MediaViewerScreen extends StatefulWidget {
  const MediaViewerScreen({required this.arguments, super.key});

  final MediaViewerArguments arguments;

  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen> {
  late final PageController _pageController;
  late int _index;
  late int _lastAllowedIndex;
  bool _isReverting = false;

  String get _currentPath => widget.arguments.paths[_index];

  @override
  void initState() {
    super.initState();
    _index = widget.arguments.initialIndex;
    _lastAllowedIndex = widget.arguments.initialIndex;
    _pageController = PageController(initialPage: _index);
    _trackViewed();
    context.read<AdsBloc>().add(const InterstitialAdRequested());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (_isReverting) {
      _isReverting = false;
      _lastAllowedIndex = index;
      setState(() => _index = index);
      return;
    }

    setState(() => _index = index);
    final isPremium = context.read<IapBloc>().state.isPremium;
    final shouldRestrict =
        widget.arguments.allowSave &&
        !isPremium &&
        index >= StatusStrings.freeItemLimit;
    if (shouldRestrict) {
      _isReverting = true;
      _pageController.animateToPage(
        _lastAllowedIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      _showPremiumModal();
    } else {
      _lastAllowedIndex = index;
      _trackViewed();
    }
  }

  void _trackViewed() {
    AnalyticsService.track('media_viewed', {
      'source': widget.arguments.allowSave ? 'statuses' : 'saved_media',
      'index': _index,
    });
  }

  Future<void> _showPremiumModal() async {
    if (AdSuppressionManager().areAdsSuppressed) return;
    await AdSuppressionManager().withAdsSuppressed(
      reason: 'gallery_limit',
      action: () async {
        final shouldStartTrial = await showPremiumUpgradeModal(
          context,
          message: StatusStrings.unlimitedGalleryMessage,
        );
        if (shouldStartTrial == true && mounted) {
          final iapBloc = context.read<IapBloc>();
          final paywallFinished = iapBloc.stream.firstWhere(
            (state) =>
                state.status == IapViewStatus.ready ||
                state.status == IapViewStatus.failure,
          );
          iapBloc.add(const IapPaywallRequested());
          await paywallFinished;
        }
      },
    );
  }

  void _save() {
    if (!widget.arguments.allowSave) return;
    context.read<SavedMediaBloc>().add(StatusSaveRequested(_currentPath));
    RatingPrompt.recordDownload(context);
  }

  void _share() {
    context.read<SavedMediaBloc>().add(MediaShareRequested(_currentPath));
  }

  void _shareToWhatsApp() {
    shareToWhatsApp(
      '${StatusStrings.sharedFromApp} ${AppConstants().GOOGLE_PLAY_STORE_LINK}',
      filePath: _currentPath,
      context: context,
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocListener<SavedMediaBloc, SavedMediaState>(
    listenWhen: (previous, current) => previous.message != current.message,
    listener: (context, state) {
      if (state.message != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.message!)));
      }
    },
    child: Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: PhotoViewGallery.builder(
              scrollPhysics: const BouncingScrollPhysics(),
              itemCount: widget.arguments.paths.length,
              pageController: _pageController,
              onPageChanged: _onPageChanged,
              backgroundDecoration: const BoxDecoration(color: Colors.black),
              loadingBuilder:
                  (context, event) =>
                      const Center(child: CircularProgressIndicator()),
              builder: (context, index) {
                final path = widget.arguments.paths[index];
                if (widget.arguments.isVideoAt(index)) {
                  return PhotoViewGalleryPageOptions.customChild(
                    child: _VideoPlayer(path: path),
                  );
                }
                return PhotoViewGalleryPageOptions(
                  imageProvider: FileImage(File(path)),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2,
                  initialScale: PhotoViewComputedScale.contained,
                  errorBuilder:
                      (context, error, stackTrace) => const Center(
                        child: Text(
                          StatusStrings.fileMissing,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                );
              },
            ),
          ),
          const Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: 30),
              child: BannerAdWidget(),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 70),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _ViewerActionButton(
              heroTag: 'viewer_back',
              icon: Icons.arrow_back,
              onPressed: () => Navigator.pop(context),
            ),
            if (widget.arguments.allowSave)
              _ViewerActionButton(
                heroTag: 'viewer_download',
                icon: Icons.download,
                onPressed: _save,
              ),
            _ViewerActionButton(
              heroTag: 'viewer_share',
              icon: Icons.share,
              onPressed: _share,
            ),
            _ViewerActionButton(
              heroTag: 'viewer_whatsapp',
              icon: Icons.repeat_outlined,
              onPressed: _shareToWhatsApp,
            ),
          ],
        ),
      ),
    ),
  );
}

class _ViewerActionButton extends StatelessWidget {
  const _ViewerActionButton({
    required this.heroTag,
    required this.icon,
    required this.onPressed,
  });

  final String heroTag;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FloatingActionButton(
    heroTag: heroTag,
    foregroundColor: Colors.white,
    backgroundColor: const Color(CustomColors.ButtonColor),
    shape: const CircleBorder(),
    elevation: 0,
    onPressed: onPressed,
    child: Icon(icon),
  );
}

class _VideoPlayer extends StatefulWidget {
  const _VideoPlayer({required this.path});

  final String path;

  @override
  State<_VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<_VideoPlayer> {
  late final VideoPlayerController _videoController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.file(File(widget.path));
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _videoController.initialize();
      var aspectRatio = _videoController.value.aspectRatio;
      if (aspectRatio <= 0) {
        final mediaInfo = await VideoCompress.getMediaInfo(widget.path);
        final width = mediaInfo.width?.toDouble() ?? 0;
        final height = mediaInfo.height?.toDouble() ?? 0;
        if (width > 0 && height > 0) aspectRatio = width / height;
      }
      if (!mounted) return;
      setState(() {
        _chewieController = ChewieController(
          videoPlayerController: _videoController,
          autoInitialize: true,
          autoPlay: true,
          aspectRatio: aspectRatio > 0 ? aspectRatio : 1,
          materialProgressColors: ChewieProgressColors(
            playedColor: const Color(CustomColors.ButtonColor),
            handleColor: const Color(CustomColors.ButtonColor),
            bufferedColor: Colors.grey,
            backgroundColor: Colors.black,
          ),
        );
      });
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _chewieController;
    return controller == null
        ? const Center(child: CircularProgressIndicator())
        : Chewie(controller: controller);
  }
}
