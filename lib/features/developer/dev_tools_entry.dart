import 'package:flutter/material.dart';
import 'package:genrevibes_ads/genrevibes_ads.dart';
import 'package:genrevibes_analytics/genrevibes_analytics.dart';
import 'package:genrevibes_consent/genrevibes_consent.dart';
import 'package:genrevibes_crash/genrevibes_crash.dart';
import 'package:genrevibes_developer_access/genrevibes_developer_access.dart';
import 'package:genrevibes_device_identity/genrevibes_device_identity.dart';
import 'package:genrevibes_device_identity_platform/genrevibes_device_identity_platform.dart';
import 'package:genrevibes_devtools/genrevibes_devtools.dart';
import 'package:genrevibes_engagement/genrevibes_engagement.dart';
import 'package:genrevibes_feedback/genrevibes_feedback.dart';
import 'package:genrevibes_iap/genrevibes_iap.dart';
import 'package:genrevibes_notifications/genrevibes_notifications.dart';
import 'package:genrevibes_permissions/genrevibes_permissions.dart';
import 'package:genrevibes_remote_config/genrevibes_remote_config.dart';
import 'package:genrevibes_remote_policy/genrevibes_remote_policy.dart';
import 'package:genrevibes_starter_kit/genrevibes_starter_kit.dart';
import 'package:genrevibes_storage/genrevibes_storage.dart';

import '../../bootstrap/app_env.dart';
import '../../bootstrap/app_runtime.dart';
import '../../container_injector.dart';
import '../analytics/domain/entities/app_analytics_catalogue.dart';

/// Opens the Starter Kit Lab.
///
/// The bench lives in `genrevibes_devtools` so every application in the
/// portfolio gets the same one. This file is the seam: it hands the bench the
/// instances this application composed, and its own event catalogue. Anything
/// Story Saver has not adopted is simply left out, and the hub shows it as
/// unavailable rather than pretending otherwise.
void openStarterKitLab(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => StarterKitLabScreen(host: _host())),
  );
}

DevToolsHost _host() {
  return DevToolsHost(
    kit: sl<GenRevibesStarterKit>(),
    eventLog: sl<AppRuntime>().eventLog,
    logger: sl<AppRuntime>().kitLog,
    catalogue: AppAnalyticsCatalogue.catalogue,
    analytics: sl<AnalyticsPipeline>(),
    sessionReplay: sl<SessionReplayController>(),
    ads: sl<AdProvider>(),
    adPolicy: sl<AdPolicyController>(),
    adPlacements: AppPlacements.all,
    consent: sl<ConsentGate>(),
    iap: sl<IapProvider>(),
    push: sl<PushNotificationProvider>(),
    permissions: sl<PermissionProvider>(),
    remoteConfig: sl<RemoteConfigCoordinator>(),
    remoteConfigSchema: PortfolioRemoteConfigSchema.build(),
    // Analytics-name overrides are left out: this app does not rename events
    // remotely, and their forty-two keys buried the three it does configure.
    identity: sl<DeviceIdentityResolver>(),
    // Read only when the developer access page asks, to register this phone as
    // an ad test device. The app's own identity never includes it.
    advertisingId: const PlatformAdvertisingIdSource(),
    developerAccess: sl<DeveloperAccessController>(),
    retention: sl<RetentionTracker>(),
    crash: sl<CrashCoordinator>(),
    feedback: sl<FeedbackProvider>(),
    store: sl<KeyValueStore>(),
    storageKeys: _storageKeys,
    // Not adopted yet: local notifications still run through AutoSaveService,
    // and rating and onboarding keep their own app-side services.
  );
}

/// The keys the inspector reads, paired with what they adopted from.
///
/// `KeyValueStore` cannot enumerate what it holds, so these are named. Pairing
/// each with its legacy key is the point: it shows at a glance whether a
/// migration carried a real user's data across.
const _storageKeys = <DevStorageGroup>[
  DevStorageGroup(
    title: 'Engagement',
    entries: <DevStorageEntry>[
      DevStorageEntry(
        key: 'genrevibes.engagement.installed_at.v1',
        legacyKey: 'first_install_date',
      ),
      DevStorageEntry(
        key: 'genrevibes.engagement.last_opened_at.v1',
        legacyKey: 'last_open_date',
      ),
      DevStorageEntry(
        key: 'genrevibes.engagement.total_opens.v1',
        legacyKey: 'total_app_opens',
      ),
      DevStorageEntry(
        key: 'genrevibes.engagement.session_timestamps.v1',
        legacyKey: 'session_timestamps',
      ),
      DevStorageEntry(
        key: 'genrevibes.engagement.daily_open_dates.v1',
        legacyKey: 'daily_open_dates',
      ),
    ],
  ),
  DevStorageGroup(
    title: 'Device identity',
    entries: <DevStorageEntry>[
      DevStorageEntry(
        key: 'genrevibes.device_identity.install_id.v1',
        legacyKey: 'device_uuid',
      ),
    ],
  ),
  DevStorageGroup(
    title: 'Onboarding',
    entries: <DevStorageEntry>[
      DevStorageEntry(
        key: 'genrevibes.onboarding.completed.v1',
        legacyKey: 'has_seen_onboarding',
      ),
    ],
  ),
  DevStorageGroup(
    title: 'Rating',
    entries: <DevStorageEntry>[
      DevStorageEntry(
        key: 'genrevibes.app_rating.app_opens.v1',
        legacyKey: 'app_opens_count',
      ),
      DevStorageEntry(
        key: 'genrevibes.app_rating.installed_at.v1',
        legacyKey: 'app_install_date',
      ),
      DevStorageEntry(
        key: 'genrevibes.app_rating.last_prompted_at.v1',
        legacyKey: 'last_rating_shown_date',
      ),
      DevStorageEntry(
        key: 'genrevibes.app_rating.opted_out.v1',
        legacyKey: 'never_show_rating',
      ),
      DevStorageEntry(
        key: 'genrevibes.app_rating.trigger.download.v1',
        legacyKey: 'download_count',
      ),
    ],
  ),
  DevStorageGroup(
    title: 'Session replay',
    entries: <DevStorageEntry>[
      DevStorageEntry(
        key: 'genrevibes.analytics.session_replay.bucket.v1',
        label: 'Rollout bucket, 0-99',
      ),
      DevStorageEntry(
        key: 'genrevibes.analytics.session_replay.override.v1',
        label: 'Developer force on/off',
      ),
    ],
  ),
  DevStorageGroup(
    title: 'Developer access',
    entries: <DevStorageEntry>[
      DevStorageEntry(
        key: DeveloperAccessKeys.failedPasscodeAttempts,
        label: 'Wrong passcode attempts',
      ),
    ],
  ),
  DevStorageGroup(
    title: 'Not yet migrated',
    entries: <DevStorageEntry>[
      DevStorageEntry(key: 'debug_premium_override', label: 'Dev override'),
    ],
  ),
];
