# Guided WhatsApp connection

The connection screen explains the benefit, previews “Use this folder” and
“Allow”, and offers Connect, Not now, and expandable folder help. The reusable
`FolderAccessPreview` lives in the starter kit onboarding module. It uses no
remote media and respects reduced animation settings. It is explicitly labeled
as a preview; it does not draw over Android's picker.

## Folder access

The recommended selection is Android/media, covering regular and Business
WhatsApp together. The initial URI is only a hint: the visual guide also starts
from the phone storage root and explains how to leave Downloads/Recent. If the
hint is rejected, retry the normal picker without it. Users do not have to open
com.whatsapp or show hidden files. A deeper route is optional only if the picker
will not allow selecting media.

Seven supplied screenshots are bundled unchanged, with captions, previous/next
controls and zoom. Personal status photos and the screenshots containing them
are not included. The primary route uses only the storage and Android screens;
the media confirmation is a labeled UI preview, avoiding the screenshot whose
annotation incorrectly encourages going deeper for the recommended route.
The action button stays visible at the bottom. Folder help never sends users
out to WhatsApp. Open WhatsApp is retained only for the connected-but-empty
status screen, where viewing a status is the relevant next action.

Exact status folders and valid ancestors for either app remain accepted.
After selection, both permission flags are checked independently and updated.
Selecting one app never releases the other app's grant. Selecting the other
variant offers a precise message to choose Android/media to connect both.
Wrong selections receive instructions to recover rather than false success.
Android controls whether a folder is selectable; arbitrary inaccessible or
unrelated folders cannot truthfully be treated as connected.

The status loader resolves `.Statuses` directly beneath the persisted tree using
a native metadata query. DocMan.fromUri resolves the root of a tree URI even when
it includes a child ID, so it must not be used for this lookup. Missing statuses
remain an empty state with Open WhatsApp and Refresh controls. The app refreshes
when returning from its Open WhatsApp action. The Android channel opens the
specific installed regular or Business package without composing a message.

## First use and permissions

Permission checks never prompt. SAF status browsing no longer depends on gallery,
notification or all-files access. The saved-media loader checks permission and
returns an empty page when unavailable. Explicit saving and the Saved tab's
Show saved statuses button can request gallery access. Enabling auto-save asks
for gallery access and then notification permission; notification denial does
not prevent auto-save. There is no automatic all-files/settings redirect.

Onboarding native ads are enabled again, subject to consent, premium and remote
configuration. Ordinary ad loading is enabled after a verified status-folder
grant (including restored grants), rather than waiting for the first thumbnail.
The connection route still suppresses ads while Android's picker is active.
Interstitial loading/showing waits for the grant, even during onboarding.
The first-status-rendered flag remains an analytics/rating milestone.
The detailed tutorial starts at storage root and proceeds through Android,
media, WhatsApp package, WhatsApp, Media, hidden files, .Statuses and confirmation.

## Funnel

Events are registered in AppAnalyticsCatalogue:

- status_connection_viewed
- status_connection_picker_opened
- status_connection_granted
- status_connection_cancelled / status_connection_failed / status_connection_skipped
- status_connection_help_opened / status_connection_open_whatsapp
- status_connection_first_status_displayed
- status_connection_first_save

Properties are business_mode and elapsed_ms where a setup session is active.
Timings begin at the first connection screen in the current process; they are
not cross-session elapsed times. The first-save event is persisted once per
install. No folder URIs, filenames or status content are recorded by this funnel.
The first-status event measures a decoded thumbnail in the active tab, not merely
files returned by the loader. Existing permission analytics are retained.

## Validation

Dart formatting, Git whitespace checks, manifest XML parsing, and targeted source
inspection are used. No analyzer, build, install or device run was performed.
A full Android rebuild is required for the new stat and openWhatsApp channel
methods; hot reload does not install them.

Proposed opt-in command:

```sh
flutter analyze lib/features/permissions lib/features/statuses lib/features/saved_media lib/features/home lib/features/splash lib/features/onboarding lib/features/monetization/data/services/subscription_service.dart lib/features/monetization/presentation/bloc/ads_bloc lib/features/settings/presentation/screens/settings_screen.dart lib/features/analytics/domain/entities/app_analytics_catalogue.dart lib/bootstrap/app_bootstrap.dart packages/genrevibes_starter_kit/modules/onboarding/genrevibes_onboarding/lib
```

Device acceptance checks after a requested rebuild: fresh install, cancellation,
wrong folder, hidden/missing .Statuses using Media fallback, regular and Business
folders, persisted grant after restart, revoked access, no statuses, returning
from WhatsApp, first image/video display, first save and gallery denial, reduced
motion, large text, and premium/free ad suppression.

## Automatic descendant discovery

The tutorial now uses short tap labels, with explanations kept out of the main
path. Any readable SAF tree can be searched, not only a hard-coded WhatsApp
ancestor. Native discovery runs on the executor: validate remembered locations,
try standard and legacy paths within the grant, then traverse directory children
until the requested .Statuses folder is found or reachable folders are exhausted.
Only directory metadata is examined during discovery. Unreadable branches are
skipped, visited document IDs prevent cycles, and successful locations are saved
and revalidated on reuse. Regular/Business classification follows WhatsApp folder
and package names; an otherwise unidentified .Statuses folder is treated as regular.
Search stops when the requested variant is found so another missing variant does
not delay loading. Large unrelated trees can take time; no arbitrary depth limit
causes a reachable deep folder to be rejected. Access remains confined to the
granted tree. A sibling outside the grant cannot be discovered or read.

A native rebuild is required. These changes have been formatted and inspected,
but not compiled or tested on a device.

## Picker starting location and failure feedback

The initial location now uses a document URI for primary:Android/media rather
than a bare tree URI. If opening the picker throws, the fallback is an explicit
primary:Android document URI; no fallback intentionally omits the location.
The OS may still ignore an initial-location hint, and this API cannot clear
DocumentsUI history or force OEM picker behavior. Folder selection remains
user-controlled. Failure and cancellation messages are displayed persistently
above the fixed retry button, announced as a live region, and shown in a snackbar.
The listener handles terminal outcomes while a request is outstanding even if
an intervening state was emitted. A wrong folder says: “Wrong folder. Choose
Android → media and try again.”

Proposed focused validation (not run):
`flutter analyze lib/features/permissions`

## Native preloading during splash

When splash resolves onboarding as the destination, it starts a nonblocking
native preload for onboarding_native. It waits for deferred consent/SDK startup
and known free entitlement, then rechecks premium, global/onboarding remote
switches and suppression before loading. The onboarding allowance is handed
over across navigation so splash disposal does not discard the cached ad.
The native view and preload use the provider's coalesced load operation.
A late or failed preload never holds navigation. The onboarding view can load
when startup finishes after splash. No first-use interstitial is introduced.

Proposed validation (not run):
`flutter analyze lib/features/splash/presentation/screens/splash_screen.dart lib/features/analytics/domain/entities/app_analytics_catalogue.dart`
