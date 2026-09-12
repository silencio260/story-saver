# Switching the startup ad

The existing default stays `appodeal` + `interstitial`. This does not guarantee
AdMob exclusion: lack of fill today is not a network exclusion rule.

| Remote Config key | Default | Purpose |
| --- | --- | --- |
| `splash_ad_enabled` | `true` | Set false to disable launch ads only |
| `splash_ad_provider` | `appodeal` | Select an integrated, registered provider |
| `splash_ad_format` | `interstitial` | `interstitial`, `rewarded`, `app_open`, `none` |
| `splash_ad_max_wait_seconds` | `8` | Startup and ad-loading budget, 1–30 seconds |
| `splash_ad_on_first_launch` | `true` | Allow launch ad before onboarding |

`none` also disables launch ads. The global `ads_enabled` switch and premium
access still suppress them. Unknown provider IDs and unsupported formats skip
without a fallback. Appodeal + `app_open` currently skips because that adapter
does not support the format. Rewarded remains a technical option, not approval
for an automatic rewarded placement without user opt-in.

The template is in agents/skills/mobile-app-skills/skills/remote-config/
remote_config_template.json (Splash Ad Group). It has not been published.
Remote switches apply once fetched and activated on the device; offline clients
retain their config. Settings are rechecked before load and show. They do not
close an ad already on screen.

## Adding another provider later

1. Integrate a compatible `AdProvider` adapter in the starter kit. Configure its
   dedicated launch ad unit and consent initialization; prevent requests until
   entitlement is confirmed free. Include premium discard handling, analytics
   subscriptions, lifecycle handling and cleanup for that provider.
2. Add its initialized instance to `SplashAdRegistry` in runtime_registrar.dart
   under a stable ID such as `admob`. Keep the ordinary `AdProvider` registration
   pointing at Appodeal, preserving its in-app placements and demand.
3. Map `AppPlacements.splashAppOpen` (`splash_app_open`) to the new App Open unit.
   Integrate shared full-screen suppression if the provider introduces other
   full-screen entry points. Do not apply ordinary interstitial startup delays
   to the splash placement.
4. Ship the integration, then select `splash_ad_provider=admob` and
   `splash_ad_format=app_open` together in Remote Config. Target supported app
   versions; older versions may not understand these settings.

Remote Config selects shipped integrations; it cannot add an SDK or ad unit
configuration to an old binary. No additional provider is integrated by this
change, and the splash screen remains independent of the chosen adapter.

## Validation

Dart formatting, JSON parsing and Git whitespace checks passed. No analyzer,
build or device run was performed. Proposed opt-in analyzer command:

```sh
flutter analyze lib/bootstrap/app_env.dart lib/bootstrap/runtime_registrar.dart lib/features/splash/presentation/screens/splash_screen.dart packages/genrevibes_starter_kit/modules/remote_config/genrevibes_remote_policy/lib/src/splash_ad_policy_keys.dart packages/genrevibes_starter_kit/modules/splash/genrevibes_splash/lib/src/splash_ad.dart packages/genrevibes_starter_kit/modules/splash/genrevibes_splash/lib/src/splash_flow.dart
```
