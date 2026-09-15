# Agents skills detail revision

Completed 15 September 2026. Changes remain uncommitted.

## What was corrected

The initial rewrite made the instructions too short to explain the project.
This revision restores implementation detail and explains the current app/kit
structure in plain language. It does not treat fewer lines as evidence of quality.

The operating rules now explicitly require preserving useful procedures,
examples, architecture, failure behavior, and project-specific constraints.

## Main entry points

- [Skills index](../../../agents/skills/mobile-app-skills/README.md)
- [Architecture](../../../agents/skills/mobile-app-skills/ARCHITECTURE_ANALYSIS.md)
- [Working conventions](../../../agents/skills/mobile-app-skills/references/working-conventions.md)
- [Complete feature walkthrough](../../../agents/skills/mobile-app-skills/references/feature-walkthrough.md)
- [Shared integration examples](../../../agents/skills/mobile-app-skills/references/integration-examples.md)

## Detail added

The architecture guide explains the repository tree, app layers, kit contracts
and adapters, startup sequence, GetIt registrations, and object ownership. It
states the portfolio default of BLoC, GetIt, Either/Failure, and use cases while
preserving another existing app's architecture during kit adoption.

The feature walkthrough includes twelve complete Dart files: main, router,
registration, failure/use-case types, feature injector, data source, repository
interface/implementation, use cases, BLoC, and screen. It stores one preference
and handles loading, saving, storage failure, and late completion. It does not
implement a device screen-awake capability. Instructions explain which demo
files to replace with the host's existing types and registrations.

A separate Dart file contains typed integration functions for bounded consent
and deferred startup, developer access, contact forms, entitlement policy,
paywalls/restores, remote config, permissions, reminders, pending taps, and Lab.
The accompanying guide names when to call each function and what remains the
caller's responsibility. These are individual integration examples, not a
complete replacement bootstrap.

Feature skills now explain integration steps, state meanings, failure recovery,
instance reuse, ownership, migration, and product choices. Platform and app-owned
skills explain their actual work boundaries, including identity changes,
network/cache behavior, backend authorization, quotas, assets, signing, and
submodule pointers.

## Useful older guidance retained and corrected

| Older material | Current treatment |
|---|---|
| Feature layers and registration | Restored as explicit architecture and a complete working example. |
| Naming, entities/models, BLoC ownership | Preserved and explained in working conventions. |
| Manual code preference | Preserved for new work; existing generated code keeps its maintenance process. |
| Always block on connectivity precheck | Replaced with handling actual request failures and deliberate cache policy. |
| Hypothetical network helpers | Described as optional app architecture; not claimed to exist in current Story Saver. |
| Old copied starter feature tree | Replaced with the actual modular kit and app composition structure. |
| Generic SDK snippets | Replaced or supplemented with current exports, source-backed signatures, and explicit caller responsibilities. |

Consent still gets a bounded attempt before ads, then lets initialization
continue on failure/timeout without fabricating consent. Shared developer
defaults remain reusable and app-configurable. Existing storage and deliberate
app policies remain migration inputs, not data to clear.

## Checks performed

- All 55 skill files passed the skill-creator validator.
- All 326 local links within agents Markdown resolved.
- Six JSON and three XML configuration files parsed.
- All 13 Dart example files passed targeted Flutter analysis with no issues.
- Git whitespace checks passed for the host and agents repositories.
- Source walkthroughs covered preference load/save failure, GetIt/BLoC ownership,
  consent timeout followed by ads initialization, and connecting Lab to existing
  runtime instances. These were document/source reviews, not device runs.

See [check results](agents-detail-verification.json). The YAML validator dependency
was installed in a temporary directory; app dependencies were not changed.

## Limits and unchanged scope

No production app/kit Dart or native source was changed in this skills revision.
Tests, builds, native SDK/device flows, external publication, and fresh-clone
verification were not run. Existing unrelated changes were preserved. The kit
working tree remains clean at the revision recorded in the compatibility guide.

These checks establish document structure, local references, and example source
compatibility. They do not prove that every model, including older models, will
follow the instructions correctly. No cross-model evaluation was performed.

CI remains a deferred TODO.
