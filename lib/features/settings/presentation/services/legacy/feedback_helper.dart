import 'package:fancy_rating_bar/fancy_rating_bar.dart';
import 'package:feedbacknest_core/feedbacknest.dart';
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
      onSubmit: (response) {
        // Send to FeedbackNest for AI analysis
        Feedbacknest.submitCommunication(
          message: response.message,
          type: CommunicationViewType.feedback.name,
          email: response.email,
          files: response.screenshots,
        );
      },
    );
  }

  void showContactUsDialog(BuildContext context) {
    FlutterFeedbackDialog.show(
      context,
      type: CommunicationViewType.contact,
      theme: CommunicationTheme.light,
      onSubmit: (response) {
        // Send to FeedbackNest for AI analysis
        Feedbacknest.submitCommunication(
          message: response.message,
          type: CommunicationViewType.contact.name,
          email: response.email,
          files: response.screenshots,
        );
      },
    );
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
        Feedbacknest.submitRatingAndReview(
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
