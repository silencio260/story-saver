import 'package:genrevibes_analytics_posthog/genrevibes_analytics_posthog.dart';
import 'dart:async';

import 'package:fancy_rating_bar/fancy_rating_bar.dart';
import 'package:flutter/material.dart';
import 'package:genrevibes_feedback/genrevibes_feedback.dart';
import 'package:genrevibes_feedback_ui/genrevibes_feedback_ui.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../container_injector.dart';
import '../../widgets/settings_page_style.dart';

class FeedBackHelper {
  /// FeedbackNest is initialized by the kit's feedback provider, from the
  /// bootstrap. This was fire-and-forget, so it raced `runApp`.
  static void init() {}

  /// Product feedback, on the kit's feedback page.
  void showFeedBackDialog(BuildContext context) =>
      unawaited(_show(context, FeedbackKind.feedback));

  /// A support request. The page asks for an email to reply to.
  void showContactUsDialog(BuildContext context) =>
      unawaited(_show(context, FeedbackKind.contact));

  /// The kit's page replaces `flutter_feedback_dialog`, whose dialog applied
  /// the keyboard's height twice and could not scroll, so its fields spilled
  /// out of the card with the keyboard open. It opens like the other Settings
  /// pages, in their colors.
  Future<void> _show(BuildContext context, FeedbackKind kind) =>
      openFeedbackPage(
        context,
        provider: sl<FeedbackProvider>(),
        protectContent: (child) => PostHogMaskWidget(child: child),
        kind: kind,
        theme: SettingsPageStyle.feedback,
        pickScreenshot: _pickScreenshot,
      );

  /// One image from the gallery, through Android's photo picker, which needs
  /// no storage permission.
  static Future<FeedbackAttachment?> _pickScreenshot() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (image == null) return null;
    return FeedbackAttachment(
      filename: image.name,
      bytes: await image.readAsBytes(),
      mimeType: _mimeType(image),
    );
  }

  static String _mimeType(XFile image) {
    final reported = image.mimeType;
    if (reported != null && reported.isNotEmpty) return reported;
    final name = image.name.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    if (name.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  void showFancyRatings(BuildContext context) {
    FancyRatingBarParams params = FancyRatingBarParams(
      theme: RatingThemes.forest,
      // playStoreUrl: "https://play.google.com/store/apps/details?id=your.app.id",
      // appStoreUrl: "https://apps.apple.com/app/your-app-id",
      testMode: true, // Remove in production
      threshold: 1,
    );

    // FancyRatingBar.of(context).showRatingDialog(params, (response) {
    //   print('Rating: ${response.rating}');
    // });
    FancyRatingBar.of(context).handleAutomaticRating(
      params: params,
      onSubmit: (response) {
        // Option 1: Use FeedbackNest for automatic analytics
        sl<FeedbackProvider>().submitRatingAndReview(
          rating: response.rating,
          review: response.message ?? response.type.name,
        );

        // Option 2: Handle manually
        print('Rating: ${response.rating}');
      },
    );
  }

  //   FancyRatingBar.of(context).handleAutomaticRating(
  //     params: params,
  //     onSubmit: (response) {
  //       // Option 1: Use FeedbackNest for automatic analytics
  //       Feedbacknest.submitRatingAndReview(
  //         rating: response.rating,
  //         review: response.message ?? response.type.name,
  //       );
  //
  //       // Option 2: Handle manually
  //       print('Rating: ${response.rating}');
  //     },
  //   );
  // }
}
