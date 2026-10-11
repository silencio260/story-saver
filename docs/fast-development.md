# Fast Android development

## Normal flutter run

Normal `flutter run` uses the project's Gradle daemon and local build cache.
Android and Kotlin build plugins are declared once in `android/settings.gradle`;
Appodeal dependencies go directly to its Maven repository rather than first
being searched for in Google Maven and Maven Central. The existing Gradle and
Kotlin heap limits and two-worker cap remain in place.

The daemon remains available for 30 idle minutes so coding breaks do not force
a cold JVM on every run. G1 periodic concurrent collection considers reclaiming
unused heap after a minute without collection; this can return unused memory to
the OS without increasing the heap cap. Changing JVM options requires a new
daemon once before subsequent runs can reuse it. This does not eliminate active
build memory demand or memory pressure from other applications.

Keep the generated build directories and Gradle caches between runs. Changing
native dependencies, the Flutter SDK or build settings can still require more
work than a repeat run with Dart changes. A two-minute normal run is a target
that needs measurement on the development machine, not a guaranteed duration.

Debug builds write tasks taking at least one second to
`build/reports/build-timing/latest.tsv`. The report also records time from root
project evaluation to task graph readiness. It does not include earlier Gradle
startup/settings/plugin resolution, concurrent Dart compilation, dependency
resolution before Gradle, or device installation. Task durations can overlap;
do not sum them as wall-clock build time. Completed task rows survive if a run
is interrupted, and the next debug build replaces the report.

## Reuse the APK

Use the existing debug APK for routine Dart changes instead of running Gradle
again. The native ad SDKs remain in the APK, and hot reload and hot restart
remain available. This skips the Android build and dependency resolution; it
does not eliminate Dart compilation, APK installation or device connection time.

## Run

Select **Fast Dev (reuse debug APK)** or **Fast Real Ads (reuse debug APK)** in
VS Code, Cursor or Android Studio. The latter enables live ad diagnostics in
the Dart code just like the normal Real Ads Diagnostics profile.

For the terminal, run from the project root:

```sh
flutter run --debug --no-pub --dart-define-from-file=env/dev.json --dart-define=ads_live_diagnostics=true --use-application-binary=build/app/outputs/flutter-apk/app-debug.apk -d 10.235.107.187:5555
```

Use the currently connected device ID if the phone's address changes. USB avoids
the wireless ADB connection dropping during a run.

**After connecting, press `R` in the Flutter terminal, or click Hot Restart in
the IDE, before testing.** The APK initially contains the Dart code and defines
from its last build. Hot restart loads the current Dart code and defines from
this run, including the live-ad diagnostic switch. Hot reload alone does not
rerun startup or reset existing state.

Then keep that run open. Press `r` for ordinary Dart edits, or `R` for startup
and state changes. Avoid `flutter clean` during routine development; it removes
outputs needed for incremental builds, including this APK.

## When to rebuild

Use the normal Dev or Real Ads Diagnostics profile after changing Android
code, manifests, Gradle files, ad SDKs, native plugin dependencies or the Flutter
SDK. Also rebuild after changing native asset hooks or native resources. A
prebuilt APK cannot pick up those changes. Run dependency resolution before
using a fast profile after any package dependency change.

The APK must exist at `build/app/outputs/flutter-apk/app-debug.apk` and must be
a debug APK built with the current native dependencies and Flutter SDK. Fast
profiles intentionally do not fall back to a full build if it is missing.

A full Android build remains necessary when native inputs change. Sub-minute
launches are a target for this reuse workflow, not a measured guarantee.
