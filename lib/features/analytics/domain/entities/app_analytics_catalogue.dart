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
/// When an event is added, it goes here and the emitter reads it from here.
abstract final class AppAnalyticsCatalogue {
  /// Attached to every event by `AnalyticsService`.
  ///
  /// Events sent through `AnalyticsBloc` do not currently carry this, which is
  /// a real inconsistency between the two paths rather than something the
  /// bench should paper over.
  static Map<String, Object?> get alwaysAttached => <String, Object?>{
        'platform': Platform.operatingSystem,
      };

  /// The catalogue, grouped for navigation.
  static DevAnalyticsCatalogue get catalogue => DevAnalyticsCatalogue(
        alwaysAttached: alwaysAttached,
        events: const <DevEventSpec>[
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
            description: 'A single status was saved.',
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
            description:
                'Source switched back to WhatsApp, or premium was lost.',
          ),

          // -------------------------------------------------- permissions
          // The pre-kit spellings, restored. An earlier step shortened three of
          // these at the emitter and then changed the bench to match, which
          // made them agree with each other and disagree with every dashboard
          // and funnel built on the original names. The names are the contract.
          DevEventSpec(
            name: 'request_whatsapp_folder_permission',
            group: 'Permissions',
            description: 'Status folder permission requested. Fires for both '
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
            description: 'The folder picker itself failed, as opposed to the '
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
            description: 'Impression-level revenue from Appodeal, for every '
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
            description: 'An ad was shown, on any placement and from any '
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
            description: 'An ad was clicked, on any placement. Not ad_click, '
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
