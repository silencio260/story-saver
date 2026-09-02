---
name: shorebird
description: OTA code push updates via Shorebird for instant Flutter patches without app store review
---

# Shorebird (Code Push)

## Overview

Shorebird enables **over-the-air (OTA) code push** for Flutter apps. Ship Dart code fixes instantly to users without going through app store review. Used for hot-fixing bugs, updating UI, and deploying urgent patches.

> **Key Benefit**: Fix critical bugs in production within minutes instead of waiting days for app store review.

## Prerequisites

- Shorebird CLI installed: `curl --proto '=https' --tlsv1.2 https://raw.githubusercontent.com/shorebirdtech/install/main/install.sh -sSf | bash`
- Shorebird account created: `shorebird login`
- Env config set up (see `skills/env-config/SKILL.md`)

## Setup

### 1. Initialize in Project

```bash
shorebird init
```

This creates `shorebird.yaml` in the project root with your app ID.

### 2. shorebird.yaml

```yaml
# shorebird.yaml
app_id: your-app-id-here
flavors: {}
```

## Workflow

### Release → Patch cycle

```
1. Build & submit release via Shorebird
2. Users install from app store
3. Find a bug? Create a patch
4. Users get the fix instantly on next app open
```

### Creating a Release

A release creates the baseline binary that goes to the app store:

```bash
# Android release with env config
shorebird release android -- --dart-define-from-file=env/release.json

# iOS release with env config
shorebird release ios -- --dart-define-from-file=env/release.json
```

> **IMPORTANT**: Always include `--dart-define-from-file` to match the env config used in production.

### Building for Store Submission

After `shorebird release`, build the artifact normally:

```bash
# Android App Bundle for Play Store
flutter build appbundle --dart-define-from-file=env/release.json

# iOS for App Store
flutter build ipa --dart-define-from-file=env/release.json
```

### Creating a Patch (OTA Update)

Ship a Dart code fix instantly:

```bash
# Patch the latest release
shorebird patch android --release-version latest

# Patch a specific version
shorebird patch android --release-version 0.1.0+1

# iOS patch
shorebird patch ios --release-version latest
```

### Patch Limitations

Shorebird can patch **Dart code only**. It **cannot** patch:
- Native code (Kotlin/Swift/Objective-C)
- Assets (images, fonts)
- `pubspec.yaml` changes
- Native plugin upgrades
- `AndroidManifest.xml` or `Info.plist` changes

## CI/CD Integration

```yaml
# Example GitHub Actions step
- name: Shorebird Release
  run: shorebird release android -- --dart-define-from-file=env/release.json

- name: Shorebird Patch
  run: shorebird patch android --release-version latest
```

## Common Commands

| Command | Purpose |
|---|---|
| `shorebird init` | Initialize Shorebird in project |
| `shorebird login` | Authenticate CLI |
| `shorebird release android` | Create release baseline |
| `shorebird release ios` | Create iOS release baseline |
| `shorebird patch android` | Push OTA patch to Android |
| `shorebird patch ios` | Push OTA patch to iOS |
| `shorebird patch android --release-version latest` | Patch the latest release |
| `shorebird patch android --release-version 0.1.0+1` | Patch a specific version |
| `shorebird doctor` | Check Shorebird setup |
| `shorebird apps list` | List registered apps |

## Interaction Map

- **Env Config** → `--dart-define-from-file` must match between release and normal builds
- **Remote Config** → Use remote config for feature flags instead of patching for toggles
- **Analytics** → Track patch adoption rates
- **Error Handling** → Shorebird patches fix crash-causing bugs instantly

## Best Practices

1. **Always use env config** — Include `--dart-define-from-file=env/release.json` in release commands
2. **Test patches locally** — Run `shorebird preview` before patching production
3. **Version discipline** — Track which versions have been patched
4. **Don't patch native changes** — If you changed native code, do a full release instead
5. **Monitor patch adoption** — Check Shorebird dashboard for rollout progress

## Checklist

- [ ] Shorebird CLI installed and authenticated
- [ ] `shorebird init` run in project
- [ ] `shorebird.yaml` committed to git
- [ ] First release created via `shorebird release android`
- [ ] Patch flow tested
- [ ] Env config included in all release/patch commands
- [ ] CI/CD pipeline updated with Shorebird steps (if applicable)
