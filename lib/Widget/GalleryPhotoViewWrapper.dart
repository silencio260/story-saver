import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:storysaver/Monetization/Ads/Admob/Widget/DisplayBannerAds.dart';
import 'package:storysaver/Monetization/Ads/Admob/admob_wrapper.dart';
import 'package:storysaver/Monetization/SubscriptionManager.dart';
import 'package:storysaver/Monetization/IAP/RevenueCat/Services/revenueCatUtil.dart';
import 'package:storysaver/Widget/PremiumUpgradeModal.dart';
import 'package:storysaver/Monetization/AdSuppressionManager.dart';
import 'package:storysaver/Screens/TopNavPages/Images/Image_view.dart';
import 'package:storysaver/Screens/TopNavPages/Video/video_view.dart';

class GalleryPhotoViewWrapper extends StatefulWidget {
  GalleryPhotoViewWrapper({
    this.loadingBuilder,
    this.backgroundDecoration,
    this.minScale,
    this.maxScale,
    this.initialIndex = 0,
    required this.galleryItems,
    this.isVideoView = false,
    this.scrollDirection = Axis.horizontal,
  }) : pageController = PageController(initialPage: initialIndex);

  final LoadingBuilder? loadingBuilder;
  final BoxDecoration? backgroundDecoration;
  final dynamic minScale;
  final dynamic maxScale;
  final int initialIndex;
  final PageController pageController;
  final List<FileSystemEntity> galleryItems;
  final isVideoView;
  final Axis scrollDirection;

  @override
  State<StatefulWidget> createState() {
    return _GalleryPhotoViewWrapperState();
  }
}

class _GalleryPhotoViewWrapperState extends State<GalleryPhotoViewWrapper> {
  late int currentIndex = widget.initialIndex;
  late int _lastIndex = widget.initialIndex;
  bool _isPremium = false;
  bool _isReverting = false;
  final int _freeLimit = 3; // First 3 items are free (indices 0, 1, 2)

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _checkPremium();
  }

  Future<void> _checkPremium() async {
    _isPremium = SubscriptionManager().isPremium;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
  }

  void onPageChanged(int index) {
    if (_isReverting) {
      _isReverting = false;
      _lastIndex = index;
      return;
    }

    setState(() {
      currentIndex = index;
    });

    // If user swipes to a restricted item (index >= 3)
    if (!_isPremium && index >= _freeLimit) {
      _isReverting = true;
      // Revert to last valid index
      widget.pageController.animateToPage(
        _lastIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      _showPremiumModal();
    } else {
      _lastIndex = index;
    }
  }

  void _showPremiumModal() {
    // Prevent multiple modals if already showing or animating
    if (AdSuppressionManager().areAdsSuppressed) return;

    AdSuppressionManager().withAdsSuppressed(
      reason: 'gallery_limit',
      action: () async {
        final shouldStartTrial = await showPremiumUpgradeModal(
          context,
          message: "Unlock unlimited gallery access with Premium!",
        );

        if (shouldStartTrial == true) {
          // User clicked "Start Free Trial" -> Show Paywall
          await RevenueCatService().PresentRevenueCatPayWallIfNeeded();
        }

        // Re-check status after modal/paywall closes
        await _checkPremium();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    AdmobWrapper().showInterstitialAd();

    return Scaffold(
      body: Container(
        decoration: widget.backgroundDecoration,
        constraints: BoxConstraints.expand(
          height: MediaQuery.of(context).size.height,
        ),
        child: Stack(
          alignment: Alignment.bottomRight,
          children: <Widget>[
            PhotoViewGallery.builder(
              scrollPhysics: const BouncingScrollPhysics(),
              builder: _buildItem,
              itemCount: widget.galleryItems.length,
              loadingBuilder: widget.loadingBuilder,
              backgroundDecoration: widget.backgroundDecoration,
              pageController: widget.pageController,
              onPageChanged: onPageChanged,
              scrollDirection: widget.scrollDirection,
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                child: DisplayBannerAdWidget(),
                padding: EdgeInsets.only(top: 30),
              ),
            )
          ],
        ),
      ),
    );
  }

  PhotoViewGalleryPageOptions _buildItem(BuildContext context, int index) {
    final FileSystemEntity item = widget.galleryItems[index];

    print('PhotoViewGalleryPageOptions widget.videoFilePath ${item.path}');
    print(
        'video_Index = ${index} - total_length = ${widget.galleryItems.length}');

    return PhotoViewGalleryPageOptions.customChild(
      child: !widget.isVideoView
          ? ImageView(imagePath: item.path)
          : VideoView(videoPath: item.path),
    );
  }
}
