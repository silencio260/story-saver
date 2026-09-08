import 'package:fancy_rating_bar/fancy_rating_bar.dart';
import 'dart:io';

import 'package:genrevibes_feedback/genrevibes_feedback.dart';

import '../../../../../container_injector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_feedback_dialog/flutter_feedback_dialog.dart';
import 'package:flutter_feedback_dialog/models/communication_type.dart';

class FeedBackHelper {
  /// FeedbackNest is initialized by the kit's feedback provider, from the
  /// bootstrap. This was fire-and-forget, so it raced `runApp`.
  static void init() {}

  void showFeedBackDialog(BuildContext context) {
    FlutterFeedbackDialog.show(
      context,
      type: CommunicationViewType.feedback,
      theme: CommunicationTheme.light,
      onSubmit: (response) async {
        sl<FeedbackProvider>().submit(
          FeedbackSubmission(
            message: response.message,
            kind: FeedbackKind.feedback,
            email: response.email,
            attachments: await _attachmentsFrom(response.screenshots),
          ),
        );
      },
    );
  }

  void showContactUsDialog(BuildContext context) {
    FlutterFeedbackDialog.show(
      context,
      type: CommunicationViewType.contact,
      theme: CommunicationTheme.light,
      onSubmit: (response) async {
        sl<FeedbackProvider>().submit(
          FeedbackSubmission(
            message: response.message,
            kind: FeedbackKind.contact,
            email: response.email,
            attachments: await _attachmentsFrom(response.screenshots),
          ),
        );
      },
    );
  }

  /// Reads screenshot files into the neutral attachment type.
  ///
  /// The dialog hands back files; the contract takes bytes, so a provider that
  /// is not FeedbackNest does not have to know about the filesystem.
  static Future<List<FeedbackAttachment>> _attachmentsFrom(
    List<dynamic>? screenshots,
  ) async {
    if (screenshots == null || screenshots.isEmpty) {
      return const <FeedbackAttachment>[];
    }
    final attachments = <FeedbackAttachment>[];
    for (final screenshot in screenshots) {
      final file = screenshot is File ? screenshot : File('$screenshot');
      if (!file.existsSync()) continue;
      attachments.add(
        FeedbackAttachment(
          filename: file.uri.pathSegments.last,
          bytes: await file.readAsBytes(),
          mimeType: 'image/png',
        ),
      );
    }
    return attachments;
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
