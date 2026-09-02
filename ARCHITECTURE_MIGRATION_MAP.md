# Story Saver Clean Architecture Migration Map

## Migration contract

- `deprecated_old_version_1/` is an immutable reference snapshot of the
  original application. Active code must never import from it.
- The migration changes ownership, dependency direction, and state wiring. It
  does not intentionally redesign screens or remove behavior.
- Original helper APIs that are still useful are retained in a clearly named
  `legacy/` directory and adapted only where Provider or an old import path
  would violate the new dependency structure.
- Provider state containers are replaced by BLoCs. Their file-system and
  persistence algorithms are retained in data sources, repositories, and use
  cases.

## Original-to-clean mapping

| Original area | Clean Architecture destination | Preservation status |
| --- | --- | --- |
| `Provider/getStatusProvider.dart` | `features/statuses/data`, `domain`, and `presentation/bloc/status_bloc` | Status discovery engine and thumbnail/cache operations retained; notifications replaced by BLoC states. |
| `Provider/savedMediaProvider.dart` | `features/saved_media/data`, `domain`, and `presentation/bloc/saved_media_bloc` | Album paging, deduplication, thumbnail loading, refresh, deletion, sharing, and gallery resolution retained. |
| `Provider/PermissionProvider.dart` | `features/permissions/data`, `domain`, and `presentation/bloc/permissions_bloc` | Storage and SAF folder state retained. |
| `Provider/topNavProvider.dart` | `features/navigation/presentation/bloc/navigation_bloc` | Selected-tab state retained. |
| `Provider/themeProvider.dart` | `core/widgets/legacy/dark_mode_toggle_button.dart` | Original unused UI helper retained as a compatibility widget; it is not wired into active app state because the original app did not provide `ThemeProvider` in `main.dart`. |
| `Screens/home_page.dart` | `features/home/presentation/screens/home_screen.dart` | Original AppBar, three tabs, WhatsApp mode button, settings, premium/download-all action, exit dialog, rating trigger, and banner placement restored. |
| Image/video status screens and `MediaListItem.dart` | `features/statuses/presentation/widgets/status_grid.dart` | Original grid dimensions, permission/empty states, thumbnails, video badge, saved badge, free-first-three rule, premium flow, ad suppression, and download trigger restored. |
| `GalleryPhotoViewWrapper.dart`, `Image_view.dart`, `video_view.dart` | `features/statuses/presentation/screens/media_viewer_screen.dart` | Paging, zoom, video playback, gallery restriction, banner, and back/download/share/WhatsApp controls restored. |
| Saved-media screen/widgets/viewer | `features/saved_media/presentation` plus the shared media viewer | Original mixed-media gallery, paging, thumbnails, video badge, deletion confirmation, and full-screen navigation retained. |
| Folder permission screens | `features/permissions/presentation/screens/status_folder_permission_screen.dart` | Original instructional screen and loading flow restored for regular and Business WhatsApp. |
| `Screens/Settings/settings_page.dart` | `features/settings/presentation/screens/settings_screen.dart` | Original visual design, menu items, auto-save, dialogs, subscription actions, and developer options restored. |
| Onboarding and splash screens | `features/onboarding/presentation` and `features/splash/presentation` | Original layouts, text, two-second splash, gallery preload, page indicator, paywall, and completion flow restored. |
| Analytics services | `features/analytics` | Firebase/PostHog tracking and original event helpers retained. |
| Ads, IAP, and subscription services | `features/monetization` | Original ad configuration, suppression, premium state, RevenueCat flows, and compatibility facades retained. |
| App rating, feedback, help, and premium dialogs | Feature-local `presentation/**/legacy` directories | Original implementations retained and used by the active UI. |
| File, share, cache, device, and thumbnail helpers | `core/**/legacy` or the owning feature's `data`/`presentation` legacy directory | Original APIs retained or adapted to BLoC-backed equivalents. |

## Compatibility names intentionally retained

The active tree retains compatibility APIs including `AdmobWrapper`,
`DisplayBannerAdWidget`, `AdHelper`, `OnboardingManager`,
`GrantPermissionButton`, `LoadStatusUtils`, `deleteSavedMeidaUtils`,
`DarkModeToggleButton`, `LocalImageCache`, `MyRouteObserver`, the WhatsApp SVG
icons, asset-entity helpers, thumbnail helpers, media save/delete helpers,
sharing helpers, rating/feedback helpers, and the original folder-permission
screen class names.

## Intentional architectural replacements

The following old classes are not active state sources because retaining them
would create two competing state-management systems:

- `GetStatusProvider` -> `StatusBloc`
- `GetSavedMediaProvider` -> `SavedMediaBloc`
- `PermissionProvider` -> `PermissionsBloc`
- `TopNavProvider` -> `NavigationBloc`

The duplicate experimental/retired screens (`onboardingPage.dart`,
`ThumbnailExperiment.dart`, and the unused sidebar) remain available verbatim
in `deprecated_old_version_1/`, but are not routed into the running app.

## Reference snapshot

The reference was created from Git commit
`5818a6832f11d09beb2aeae784265cccf2f2a5fa`, including the pinned `agents` and
starter-kit submodule contents. The analyzer excludes the snapshot so it cannot
interfere with the active build.
