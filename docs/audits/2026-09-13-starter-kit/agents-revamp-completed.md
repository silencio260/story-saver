# Initial agents revamp report

This records the initial rewrite, which removed too much useful detail. The
[detail revision](agents-detail-revision.md) supersedes its completion assessment
and records the expanded instructions and analyzer-checked examples.

Completed 14 September 2026. Changes are uncommitted.

## Changes

Rewrote all 47 existing skills in plain language and added eight focused skills.
Existing skill names and paths remain available. The current
[skills index](../../../agents/skills/mobile-app-skills/README.md) lists every skill.

- Replaced the old starter facade, copied-package instructions, and conflicting
  app folder layouts with modular integration and app-owned lifecycle.
- Replaced the large architecture tutorial with ownership rules and links to
  current package APIs/examples. Removed repeated boilerplate from feature skills.
- Preserved consent continue-on-error behavior and configurable shared developer
  defaults, including listed devices and Appodeal relaunch behavior.
- Separated app-specific branding, entitlement IDs, navigation, replay choices,
  provider selection, and database schemas from shared kit requirements.
- Updated backend HTTP auth guidance to diagnose the rejecting layer before
  changing invocation access. Removed unsafe generic Firestore rules and silent
  debug-signing fallback instructions.
- Kept the three Noir Glass reference images and moved optional style descriptions
  to a linked reference. Missing/kept images no longer imply user rejection/approval.
- Replaced stale environment values with blank supported configuration. Documented
  optional provider readers and why a blank entitlement override is omitted.
- Corrected IDE tool arguments and the Android Studio Dev template flag.
- Replaced the Remote Config export with 27 current shared defaults and plain
  descriptions. Removed old export metadata and the duplicate app-specific export.
- Added a root AGENTS.md that points to the shared operating rules and skills index.
  Analyzer permission and opt-in test/build rules remain in place.

## Added skills

- [kit-upgrade](../../../agents/skills/mobile-app-skills/projects/kit-upgrade/SKILL.md)
- [replace-provider](../../../agents/skills/mobile-app-skills/projects/replace-provider/SKILL.md)
- [kit-lab](../../../agents/skills/mobile-app-skills/skills/kit-lab/SKILL.md)
- [local-notifications](../../../agents/skills/mobile-app-skills/skills/local-notifications/SKILL.md)
- [permissions](../../../agents/skills/mobile-app-skills/skills/permissions/SKILL.md)
- [runtime-setup](../../../agents/skills/mobile-app-skills/skills/runtime-setup/SKILL.md)
- [session-replay](../../../agents/skills/mobile-app-skills/skills/session-replay/SKILL.md)
- [storage-migration](../../../agents/skills/mobile-app-skills/skills/storage-migration/SKILL.md)

## Retained, merged, and removed

All 47 original skills remain under their original names with rewritten content.
No skills were merged or deleted. Overlapping setup details now link to the
relevant shared skill or current kit documentation.

Removed one obsolete app-specific Remote Config JSON from active templates.
Its history remains in Git. The templates folder now points to the single shared
export. Existing image assets and the pre-existing .DS_Store edit were preserved.

## Checks performed

- 55 skill files passed the skill-creator validator, including YAML frontmatter.
- 285 local documentation links resolved.
- Six JSON files and three XML files parsed.
- IDE environment targets matched the files supplied by the documented copy steps.
- All base environment keys matched existing host define readers.
- All 27 Remote Config names, types, and defaults matched current declarations.
- Active guidance contained none of the checked obsolete facade/setup references.
- Named kit types and relevant lifecycle methods were checked against source.
  This caught and corrected the old retention method names.
- Git whitespace checks passed for the app and agents repositories.

The validator's PyYAML dependency was installed in a temporary directory only.
No app dependencies were installed or changed.

## Workflow review

These were document/source walkthroughs, not app launches:

| Request | Result of following the guidance |
|---|---|
| Create a small settings/onboarding app | Selects the neutral/runtime/UI/storage packages. Dependency traversal found no Firebase, ad, or developer-tool requirement. |
| Add feedback to an existing app | Reuses the existing router and shared feedback page/provider. Dependency traversal found no Firebase, ad, or developer-tool requirement. Credentials, theme, and callbacks remain app-owned. |
| Upgrade an old integration | Identifies the pinned revision, changed APIs, legacy storage mappings, and app policy overrides before replacing callers. Preserves existing state management and avoids running duplicate listeners. |
| Restrict developer access | Uses shared config/action checks. Diagnostics-only grants do not permit simulated premium; disabling passcodes does not remove listed-device access. |

See [machine-readable checks](agents-revamp-verification.json) and
[checked kit revision](../../../agents/skills/mobile-app-skills/references/kit-compatibility.md).
The kit was clean at local commit c1f264086a00d957cf4959a5df9c1c195a88a789.
Remote availability of that commit was not verified.

## Limits

No app or kit Dart/native source was changed. No Flutter analyzer, tests, builds,
or device flows were run for this documentation change. The walkthroughs do not
prove native SDK behavior or fresh-clone readiness. No commits, pushes, store
uploads, Firebase deployment, or Remote Config publication were performed.

CI remains deferred; it is not a completion blocker for this work.
