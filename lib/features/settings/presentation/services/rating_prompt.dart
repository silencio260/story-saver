import 'package:flutter/material.dart';
import 'package:genrevibes_app_rating/genrevibes_app_rating.dart';

import '../../../../container_injector.dart';
import '../widgets/legacy/rating_dialog.dart';
import 'legacy/feedback_helper.dart';

/// Presents the rating dialog and routes what follows.
///
/// This is the presentation half of app rating. Every rule — how many opens,
/// how long since install, how long since the last prompt, what happens after
/// an answer — lives in the kit's [RatingCoordinator], which owns no UI and can
/// be tested against an injected clock. This file only shows a dialog and obeys
/// the follow-up it is handed.
///
/// It replaces `AdvancedAppRatingService`, which mixed eligibility arithmetic,
/// `SharedPreferences` access, analytics, ad suppression and dialog presentation
/// into one static class. The stored state carries over: the coordinator reads
/// the same `app_install_date`, `app_opens_count`, `never_show_rating`,
/// `last_rating_shown_date` and `download_count` values through the store's
/// legacy-key mapping, so existing users keep their eligibility rather than
/// being re-prompted on the release that adopts this.
abstract final class RatingPrompt {
  /// Counts a completed download and prompts once the milestone is reached.
  ///
  /// The old code prompted on exactly the second download. That is preserved,
  /// but the check is now "at least two" rather than "equal to two", so a
  /// counter that advances twice between prompts does not skip the milestone
  /// forever.
  static Future<void> recordDownload(BuildContext context) async {
    final rating = sl<RatingCoordinator>();
    final count = (await rating.recordTrigger('download')).fold(
      onSuccess: (value) => value,
      onFailure: (_) => 0,
    );
    if (count < 2 || !context.mounted) return;
    await showIfEligible(context, force: true);
  }

  /// Shows the dialog when the coordinator allows it.
  ///
  /// [force] bypasses the timing and app-open thresholds for an app-chosen
  /// milestone. It does not override an explicit opt-out: a user who asked not
  /// to be prompted is never asked again, which the old `force` path got wrong.
  static Future<void> showIfEligible(
    BuildContext context, {
    bool force = false,
  }) async {
    // Not while another modal owns the screen. A rating prompt over a paywall
    // interrupts the more valuable of the two.
    if (!force && !(ModalRoute.of(context)?.isCurrent ?? false)) return;

    final rating = sl<RatingCoordinator>();
    final decision = await rating.evaluate(force: force);
    final allowed = decision.fold(
      onSuccess: (value) => value.isAllowed,
      onFailure: (_) => false,
    );
    if (!allowed || !context.mounted) return;

    RatingDialogResponse? response;
    // `present` runs this with ads suppressed and records that a prompt was
    // shown, so the cooldown starts even if the user dismisses it.
    await rating.present(() async {
      if (!context.mounted) return;
      response = await showDialog<RatingDialogResponse>(
        context: context,
        barrierDismissible: false,
        builder: (_) => RatingDialog(),
      );
    });

    final answer = response;
    if (answer == null) return;

    final outcome = switch (answer.action) {
      RatingAction.maybeLater => RatingOutcome.maybeLater,
      RatingAction.never => RatingOutcome.never,
      RatingAction.continue_ => RatingOutcome.submitted,
    };
    final followUp = (await rating.recordOutcome(
      outcome,
      rating: answer.rating,
    ))
        .fold(
      onSuccess: (value) => value,
      onFailure: (_) => RatingFollowUp.none,
    );

    switch (followUp) {
      case RatingFollowUp.none:
        return;
      case RatingFollowUp.storeReview:
        await _requestStoreReview();
      case RatingFollowUp.feedback:
        if (context.mounted) FeedBackHelper().showFeedBackDialog(context);
    }
  }

  /// Opens the store listing directly, bypassing eligibility.
  static Future<void> openStoreListing() =>
      sl<StoreReviewProvider>().openStoreListing();

  static Future<void> _requestStoreReview() async {
    final provider = sl<StoreReviewProvider>();
    final available = (await provider.isAvailable()).fold(
      onSuccess: (value) => value,
      onFailure: (_) => false,
    );
    // The native flow is quota-limited and declines silently, so the listing is
    // the only reliable way to reach a user who chose to leave a review.
    if (available) {
      await provider.requestReview();
    } else {
      await provider.openStoreListing();
    }
  }
}
