# Story Saver Remote Config review

Project: `whatsapp-status-saver-fl-6c420`.

Downloaded on 2026-09-24. The live template contains 3 parameters and no conditions. The proposed template contains all 27 keys in `buildAppRemoteConfigSchema()`: 24 additions, with the 3 existing parameters preserved exactly. Published to production on 2026-09-24 and verified by downloading the live template again; it matches the proposed template exactly.

## Existing values preserved

| Parameter | Value |
| --- | --- |
| `min_insta_ad_interval` | `7` |
| `min_banner_ad_interval` | `3` |
| `time_before_first_insta_ad` | `3` |

## Added parameters

| Parameter | Value |
| --- | --- |
| `ads_enabled` | `true` |
| `time_before_first_rewared_ad` | `0` |
| `min_rewarded_ad_interval` | `0` |
| `min_native_interval` | `0` |
| `min_app_open_ad` | `0` |
| `should_show_app_open_ad` | `true` |
| `banner_ad_id` | `` |
| `interstitial_ad_id` | `` |
| `rewarded_ad_id` | `` |
| `native_ad_id` | `` |
| `app_open_ad_id` | `` |
| `session_replay_enabled` | `true` |
| `session_replay_percent` | `100` |
| `session_replay_mask_text` | `false` |
| `session_replay_mask_images` | `false` |
| `developer_device_hashes` | `["5251fe14611f35ccae754f48c9d4db497a123df2072e454c39357af2930a0d4f"]` |
| `onboarding_ads_enabled` | `true` |
| `splash_ad_enabled` | `true` |
| `splash_ad_provider` | `appodeal` |
| `splash_ad_format` | `interstitial` |
| `splash_ad_max_wait_seconds` | `8` |
| `splash_ad_on_first_launch` | `true` |
| `exit_prompt_style` | `features_sheet` |
| `exit_prompt_exit_button` | `standard` |

## Behavior and validation

- Checked the template key set against the six policy groups included by the app schema. Analytics event-name overrides are excluded because the app does not enable them.
- Checked unique keys, parameter types, numeric ranges, JSON values, and exact preservation of existing parameters and conditions.
- Replay values match Story Saver’s explicit bundled policy: enabled, 100% rollout, global text/image masking off. Sensitive-route masks remain app-controlled. PostHog project settings and saved replay overrides can still prevent recording.
- The developer-device list includes the hash calculated from the connected phone’s App Set ID. This grants developer access and test ads after fetch/activation; relaunch afterward to align Appodeal SDK test mode.
- Production fetching uses a 12-hour minimum interval. Relaunching alone does not force a fresh fetch within that interval.
- Empty ad-unit overrides match the schema. Appodeal uses its compiled app key and placement configuration; these legacy unit-ID keys do not supply Appodeal inventory.
- Missing remote keys fall back to bundled defaults. Adding these keys makes policy configurable but does not establish or fix the root cause of the reported missing ads/replays.
- The live template was downloaded again immediately before publishing and matched the original backup. For future updates, re-download and merge any intervening changes.
