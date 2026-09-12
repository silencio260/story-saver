import 'dart:io' show Platform;

import 'package:genrevibes_devtools/genrevibes_devtools.dart';

/// Every analytics event this application emits.
///
/// Verified against the emitters rather than written from memory. The previous
/// diagnostics screen kept its own list, which had drifted badly: five names in
/// it are emitted nowhere in `lib/`, and three more were `..._whatsapp_...`
/// spellings of events the app actually sends as `..._wa_...`. It was filling
/// dashboards with events production never sends while never exercising the
/// real ones.
///
/// Keep this diagnostic inventory aligned with the action emitters.
abstract final class AppAnalyticsCatalogue {
  /// Attached to every event by `AnalyticsService`.
  ///
  /// Also attached by AnalyticsBloc for consistent action properties.
  static Map<String, Object?> get alwaysAttached => <String, Object?>{
    'platform': Platform.operatingSystem,
  };

  /// The catalogue, grouped for navigation.
  static DevAnalyticsCatalogue get catalogue => DevAnalyticsCatalogue(
    alwaysAttached: alwaysAttached,
    events: const <DevEventSpec>[
      DevEventSpec(
        name: 'rating_evaluated',
        group: 'Rating',
        description:
            'Rating eligibility evaluated, with allowed flag and blocking reason.',
      ),
      DevEventSpec(
        name: 'rating_prompted',
        group: 'Rating',
        description: 'Rating coordinator recorded a prompt.',
      ),
      DevEventSpec(
        name: 'push_received',
        group: 'Notifications',
        description:
            'OneSignal foreground receipt callback; not a background delivery count.',
      ),
      DevEventSpec(
        name: 'push_opened',
        group: 'Notifications',
        description:
            'OneSignal notification tap or action, including app launches.',

        parameters: <DevParamSpec>[
          DevParamSpec(
            name: 'notification_title',
            kind: DevParamKind.text,
            example: 'Auto Save Complete',
          ),
          DevParamSpec(
            name: 'notification_body',
            kind: DevParamKind.text,
            example: 'Saved 3 new statuses to your gallery.',
          ),
          DevParamSpec(
            name: 'notification_payload',
            kind: DevParamKind.text,
            example: '{"value":"saved_media"}',
          ),
        ],
      ),
      DevEventSpec(
        name: 'push_state_changed',
        group: 'Notifications',
        description:
            'Push permission or subscription state changed; excludes push tokens.',
      ),
      DevEventSpec(
        name: 'local_notification_posted',
        group: 'Notifications',
        description:
            'Immediate OS show request finished; success does not prove visibility.',
      ),
      DevEventSpec(
        name: 'local_notification_opened',
        group: 'Notifications',
        description:
            'Local notification tapped or action selected, including cold launches.',

        parameters: <DevParamSpec>[
          DevParamSpec(
            name: 'notification_title',
            kind: DevParamKind.text,
            example: 'Auto Save Complete',
          ),
          DevParamSpec(
            name: 'notification_body',
            kind: DevParamKind.text,
            example: 'Saved 3 new statuses to your gallery.',
          ),
          DevParamSpec(
            name: 'notification_payload',
            kind: DevParamKind.text,
            example: '{"value":"saved_media"}',
          ),
        ],
      ),
      DevEventSpec(
        name: 'local_notification_scheduled',
        group: 'Notifications',
        description: 'OS scheduling request finished; not a delivery event.',
      ),
      DevEventSpec(
        name: 'local_notification_permission',
        group: 'Notifications',
        description: 'Local notification permission request finished.',
      ),
      DevEventSpec(
        name: 'local_notification_cancelled',
        group: 'Notifications',
        description: 'One local notification cancellation finished.',
      ),
      DevEventSpec(
        name: 'local_notifications_cleared',
        group: 'Notifications',
        description: 'All local notifications cancellation finished.',
      ),
      DevEventSpec(
        name: 'save_status_requested',
        group: 'Media',
        description: 'Manual save requested.',
      ),
      DevEventSpec(
        name: 'save_status_failed',
        group: 'Media',
        description:
            'Manual, bulk, or automatic save failed; source distinguishes the flow.',
      ),
      DevEventSpec(
        name: 'saved_media_loaded',
        group: 'Media',
        description: 'Saved media page loaded, with count and reset flag.',
      ),
      DevEventSpec(
        name: 'saved_media_load_failed',
        group: 'Media',
        description: 'Saved media page could not be loaded.',
      ),
      DevEventSpec(
        name: 'download_all_completed',
        group: 'Media',
        description: 'Bulk download finished with saved and failed counts.',
      ),
      DevEventSpec(
        name: 'auto_save_started',
        group: 'Media',
        description: 'Background or developer auto-save run began.',
      ),
      DevEventSpec(
        name: 'auto_save_completed',
        group: 'Media',
        description:
            'Auto-save scan finished with found, saved, and failed counts.',
      ),
      DevEventSpec(
        name: 'auto_save_failed',
        group: 'Media',
        description: 'Auto-save run failed.',
      ),
      DevEventSpec(
        name: 'auto_save_setting_failed',
        group: 'Media',
        description: 'Auto-save setting could not be applied.',
      ),
      DevEventSpec(
        name: 'business_mode_change_failed',
        group: 'Media',
        description: 'Source mode change failed.',
      ),
      DevEventSpec(
        name: 'media_viewed',
        group: 'Media',
        description: 'Media viewer opened or moved to an allowed item.',
      ),
      DevEventSpec(
        name: 'statuses_load_requested',
        group: 'Media',
        description: 'Statuses loading or refresh requested.',
      ),
      DevEventSpec(
        name: 'statuses_loaded',
        group: 'Media',
        description: 'Statuses loaded with image and video counts.',
      ),
      DevEventSpec(
        name: 'statuses_load_failed',
        group: 'Media',
        description: 'Status load failed.',
      ),
      DevEventSpec(
        name: 'status_cache_cleared',
        group: 'Media',
        description: 'Status cache cleared.',
      ),
      DevEventSpec(
        name: 'status_cache_clear_failed',
        group: 'Media',
        description: 'Status cache clearing failed.',
      ),
      DevEventSpec(
        name: 'share_whatsapp_requested',
        group: 'Media',
        description: 'WhatsApp sharing requested.',
      ),
      DevEventSpec(
        name: 'share_whatsapp_opened',
        group: 'Media',
        description:
            'WhatsApp deep link accepted; not proof a message was sent.',
      ),
      DevEventSpec(
        name: 'share_whatsapp_fallback',
        group: 'Media',
        description: 'Fallback share request finished.',
      ),
      DevEventSpec(
        name: 'delete_saved_media',
        group: 'Media',
        description: 'Delete saved media.',
      ),
      DevEventSpec(
        name: 'delete_saved_media_requested',
        group: 'Media',
        description: 'Delete saved media requested.',
      ),
      DevEventSpec(
        name: 'delete_saved_media_failed',
        group: 'Media',
        description: 'Delete saved media failed.',
      ),
      DevEventSpec(
        name: 'delete_all_saved_media',
        group: 'Media',
        description: 'Delete all saved media.',
      ),
      DevEventSpec(
        name: 'delete_all_saved_media_requested',
        group: 'Media',
        description: 'Delete all saved media requested.',
      ),
      DevEventSpec(
        name: 'delete_all_saved_media_failed',
        group: 'Media',
        description: 'Delete all saved media failed.',
      ),
      DevEventSpec(
        name: 'share_media',
        group: 'Media',
        description:
            'Share sheet request finished; not proof that the recipient received media.',
      ),
      DevEventSpec(
        name: 'share_media_requested',
        group: 'Media',
        description: 'Share media requested.',
      ),
      DevEventSpec(
        name: 'share_media_failed',
        group: 'Media',
        description: 'Share media failed.',
      ),
      DevEventSpec(
        name: 'app_lifecycle_changed',
        group: 'Lifecycle',
        description: 'App lifecycle changed.',
      ),
      DevEventSpec(
        name: 'navigation_tab_selected',
        group: 'Lifecycle',
        description: 'User switched navigation tab.',
      ),
      DevEventSpec(
        name: 'onboarding_page_viewed',
        group: 'Lifecycle',
        description: 'Onboarding page changed.',
      ),
      DevEventSpec(
        name: 'onboarding_complete_failed',
        group: 'Lifecycle',
        description: 'Onboarding completion could not be persisted.',
      ),
      DevEventSpec(
        name: 'onboarding_reset',
        group: 'Lifecycle',
        description: 'Onboarding reset completed.',
      ),
      DevEventSpec(
        name: 'onboarding_reset_failed',
        group: 'Lifecycle',
        description: 'Onboarding reset failed.',
      ),
      DevEventSpec(
        name: 'app_bloc_failed',
        group: 'Lifecycle',
        description: 'A BLoC raised an unhandled operation error.',
      ),
      DevEventSpec(
        name: 'storage_permission_requested',
        group: 'Permissions',
        description: 'Storage permission requested.',
      ),
      DevEventSpec(
        name: 'storage_permission_result',
        group: 'Permissions',
        description: 'Storage permission request finished, with granted flag.',
      ),
      DevEventSpec(
        name: 'storage_permission_failed',
        group: 'Permissions',
        description: 'Storage permission request failed.',
      ),
      DevEventSpec(
        name: 'ad_loaded',
        group: 'Monetisation',
        description: 'Ad loaded.',
      ),
      DevEventSpec(
        name: 'ad_dismissed',
        group: 'Monetisation',
        description: 'Ad dismissed.',
      ),
      DevEventSpec(
        name: 'interstitial_load_requested',
        group: 'Monetisation',
        description: 'Interstitial load requested.',
      ),
      DevEventSpec(
        name: 'interstitial_load_failed',
        group: 'Monetisation',
        description: 'Interstitial load failed.',
      ),
      DevEventSpec(
        name: 'interstitial_show_requested',
        group: 'Monetisation',
        description: 'Interstitial show requested.',
      ),
      DevEventSpec(
        name: 'interstitial_show_skipped',
        group: 'Monetisation',
        description: 'Interstitial show skipped.',
      ),
      DevEventSpec(
        name: 'interstitial_show_failed',
        group: 'Monetisation',
        description: 'Interstitial show failed.',
      ),
      DevEventSpec(
        name: 'interstitial_show_result',
        group: 'Monetisation',
        description: 'Interstitial show result.',
      ),
      DevEventSpec(
        name: 'purchase_pending',
        group: 'Monetisation',
        description: 'Purchase pending.',
      ),
      DevEventSpec(
        name: 'paywall_not_presented',
        group: 'Monetisation',
        description: 'Paywall not presented.',
      ),
      DevEventSpec(
        name: 'paywall_failed',
        group: 'Monetisation',
        description: 'Paywall failed.',
      ),
      DevEventSpec(
        name: 'customer_center_failed',
        group: 'Monetisation',
        description: 'Customer center failed.',
      ),
      DevEventSpec(
        name: 'restore_purchases_requested',
        group: 'Monetisation',
        description: 'Restore purchases requested.',
      ),
      DevEventSpec(
        name: 'restore_purchases_failed',
        group: 'Monetisation',
        description: 'Restore purchases failed.',
      ),
      DevEventSpec(
        name: 'contact_support',
        group: 'Support',
        description: 'Contact support.',
      ),
      DevEventSpec(
        name: 'view_privacy_policy',
        group: 'Support',
        description: 'View privacy policy.',
      ),
      DevEventSpec(
        name: 'view_terms',
        group: 'Support',
        description: 'View terms.',
      ),
      DevEventSpec(
        name: 'share_app_failed',
        group: 'Support',
        description: 'Share app failed.',
      ),
      DevEventSpec(
        name: 'goto_app_store_page_failed',
        group: 'Support',
        description: 'Goto app store page failed.',
      ),
      DevEventSpec(
        name: 'contact_support_failed',
        group: 'Support',
        description: 'Contact support failed.',
      ),
      DevEventSpec(
        name: 'view_privacy_policy_failed',
        group: 'Support',
        description: 'View privacy policy failed.',
      ),
      DevEventSpec(
        name: 'view_terms_failed',
        group: 'Support',
        description: 'View terms failed.',
      ),
      // ----------------------------------------------------- lifecycle
      DevEventSpec(
        name: 'app_open',
        group: 'Lifecycle',
        description: 'Emitted by AnalyticsBloc on AnalyticsStarted.',
      ),
      DevEventSpec(
        name: 'goto_splash_screen',
        group: 'Lifecycle',
        description: 'Splash screen shown.',
      ),
      DevEventSpec(
        name: 'goto_home_page',
        group: 'Lifecycle',
        description: 'Home reached from splash.',
      ),
      DevEventSpec(
        name: 'onboarding_complete',
        group: 'Lifecycle',
        description: 'Final onboarding page dismissed.',
      ),

      // -------------------------------------------------------- media
      DevEventSpec(
        name: 'save_status',
        group: 'Media',
        description:
            'A status was saved; source is manual, bulk, or auto_save.',
      ),
      DevEventSpec(
        name: 'download_all',
        group: 'Media',
        description: 'Bulk download started.',
      ),
      DevEventSpec(
        name: 'auto_save_enabled',
        group: 'Media',
        description: 'Auto-save switched on in settings.',
      ),
      DevEventSpec(
        name: 'auto_save_disabled',
        group: 'Media',
        description: 'Auto-save switched off in settings.',
      ),
      DevEventSpec(
        name: 'switch_to_business_mode',
        group: 'Media',
        description: 'Source switched to WhatsApp Business.',
      ),
      DevEventSpec(
        name: 'switch_to_normal_mode',
        group: 'Media',
        description: 'Source switched back to WhatsApp, or premium was lost.',
      ),

      // -------------------------------------------------- permissions
      // The pre-kit spellings, restored. An earlier step shortened three of
      // these at the emitter and then changed the bench to match, which
      // made them agree with each other and disagree with every dashboard
      // and funnel built on the original names. The names are the contract.
      DevEventSpec(
        name: 'request_whatsapp_folder_permission',
        group: 'Permissions',
        description:
            'Status folder permission requested. Fires for both '
            'the regular and business flows, as it always has.',
      ),
      DevEventSpec(
        name: 'grant_whatsapp_folder_permission',
        group: 'Permissions',
        description: 'WhatsApp status folder granted.',
      ),
      DevEventSpec(
        name: 'denied_whatsapp_folder_permission',
        group: 'Permissions',
        description: 'WhatsApp status folder refused.',
      ),
      DevEventSpec(
        name: 'grant_business_folder_permission',
        group: 'Permissions',
        description: 'Business status folder granted.',
      ),
      DevEventSpec(
        name: 'denied_business_folder_permission',
        group: 'Permissions',
        description: 'Business status folder refused.',
      ),
      DevEventSpec(
        name: 'app_error_operation_failed',
        group: 'Permissions',
        description:
            'The folder picker itself failed, as opposed to the '
            'user refusing. Reported alongside the denial event.',
      ),
      DevEventSpec(
        name: 'grant_android_media_folder_permission',
        group: 'Permissions',
        description: 'Android media permission granted.',
      ),

      // ------------------------------------------------- monetisation
      DevEventSpec(
        name: 'view_paywall',
        group: 'Monetisation',
        description: 'RevenueCat paywall presented.',
      ),
      DevEventSpec(
        name: 'view_paywall_modal',
        group: 'Monetisation',
        description: 'In-app premium modal shown.',
      ),
      DevEventSpec(
        name: 'remove_ads_clicked',
        group: 'Monetisation',
        description: 'Remove-ads entry tapped in settings.',
      ),
      DevEventSpec(
        name: 'custom_purchase',
        group: 'Monetisation',
        description: 'A purchase completed.',
        parameters: <DevParamSpec>[
          DevParamSpec(
            name: 'currency',
            kind: DevParamKind.text,
            example: 'USD',
          ),
          DevParamSpec(
            name: 'value',
            kind: DevParamKind.number,
            example: 4.99,
            description: 'Price paid.',
          ),
          DevParamSpec(
            name: 'item_id',
            kind: DevParamKind.text,
            example: 'premium_yearly',
            description: 'Product identifier.',
          ),
          DevParamSpec(
            name: 'item_name',
            kind: DevParamKind.text,
            example: 'Pro',
            description: 'Entitlement identifier.',
          ),
          DevParamSpec(
            name: 'quantity',
            kind: DevParamKind.integer,
            example: 1,
          ),
        ],
      ),
      DevEventSpec(
        name: 'custom_paywall_cancelled',
        group: 'Monetisation',
        description: 'Paywall dismissed without purchasing.',
        parameters: <DevParamSpec>[
          DevParamSpec(
            name: 'entitlement_id',
            kind: DevParamKind.text,
            example: 'Pro',
          ),
        ],
      ),
      DevEventSpec(
        name: 'custom_purchases_restored',
        group: 'Monetisation',
        description: 'Purchases restored.',
        parameters: <DevParamSpec>[
          DevParamSpec(
            name: 'entitlement_id',
            kind: DevParamKind.text,
            example: 'Pro',
          ),
        ],
      ),
      DevEventSpec(
        name: 'custom_customer_center_viewed',
        group: 'Monetisation',
        description: 'RevenueCat customer centre opened.',
      ),
      DevEventSpec(
        name: 'ad_impression',
        group: 'Monetisation',
        description:
            'Impression-level revenue from Appodeal, for every '
            'placement. value and currency are what Firebase counts as ad '
            'revenue.',
        parameters: <DevParamSpec>[
          DevParamSpec(
            name: 'ad_platform',
            kind: DevParamKind.text,
            example: 'appodeal',
          ),
          DevParamSpec(
            name: 'ad_source',
            kind: DevParamKind.text,
            example: 'admob',
          ),
          DevParamSpec(
            name: 'ad_format',
            kind: DevParamKind.text,
            example: 'banner',
          ),
          DevParamSpec(
            name: 'ad_unit_name',
            kind: DevParamKind.text,
            example: 'default',
          ),
          DevParamSpec(
            name: 'value',
            kind: DevParamKind.number,
            example: 0.0015,
          ),
          DevParamSpec(
            name: 'value_micros',
            kind: DevParamKind.number,
            example: 1500,
          ),
          DevParamSpec(
            name: 'currency',
            kind: DevParamKind.text,
            example: 'USD',
          ),
        ],
      ),
      DevEventSpec(
        name: 'ad_show',
        group: 'Monetisation',
        description:
            'An ad was shown, on any placement and from any '
            'network, test ads included. ad_impression fires only when '
            'the winning network reports revenue.',
        parameters: <DevParamSpec>[
          DevParamSpec(
            name: 'ad_platform',
            kind: DevParamKind.text,
            example: 'appodeal',
          ),
          DevParamSpec(
            name: 'ad_format',
            kind: DevParamKind.text,
            example: 'banner',
          ),
          DevParamSpec(
            name: 'placement',
            kind: DevParamKind.text,
            example: 'banner',
            description: 'App placement ID: banner or interstitial.',
          ),
        ],
      ),
      DevEventSpec(
        name: 'custom_ad_click',
        group: 'Monetisation',
        description:
            'An ad was clicked, on any placement. Not ad_click, '
            'which Firebase reserves and refuses.',
        parameters: <DevParamSpec>[
          DevParamSpec(
            name: 'ad_type',
            kind: DevParamKind.text,
            example: 'interstitial',
          ),
        ],
      ),

      // ------------------------------------------------------ support
      DevEventSpec(
        name: 'share_app',
        group: 'Support',
        description: 'App shared.',
      ),
      DevEventSpec(
        name: 'goto_app_store_page',
        group: 'Support',
        description: 'Store listing opened.',
      ),
      DevEventSpec(
        name: 'show_help',
        group: 'Support',
        description: 'Help modal opened.',
      ),

      // ------------------------------------------------------- rating
      DevEventSpec(
        name: 'rating_submitted',
        group: 'Rating',
        description: 'A rating was submitted.',
        parameters: <DevParamSpec>[
          DevParamSpec(
            name: 'star_count',
            kind: DevParamKind.integer,
            example: 5,
          ),
        ],
      ),
      DevEventSpec(
        name: 'rating_4_stars',
        group: 'Rating',
        description: 'Four stars given.',
      ),
      DevEventSpec(
        name: 'rating_5_stars',
        group: 'Rating',
        description: 'Five stars given.',
      ),
      DevEventSpec(
        name: 'rating_maybe_later',
        group: 'Rating',
        description: 'Rating prompt postponed.',
      ),
      DevEventSpec(
        name: 'rating_never',
        group: 'Rating',
        description: 'Rating prompt declined permanently.',
      ),
    ],
  );
}
