# Agents and skills revamp plan

Status: implemented. See [completion notes](agents-revamp-completed.md) for changes and checks.
The steps below record the agreed plan.

Rewrite the agents guidance to match the current modular starter kit. Make it
useful across the portfolio without making every app copy Story Saver.

## 1. Fix where agents start

- Replace the mobile-skills README's chatbot boilerplate and personal device
  commands with a short index: start an app, update an app, or add a feature.
- Rewrite `starter-kit/SKILL.md`. Remove the old `StarterKit` facade, kit-owned
  GetIt/BLoC claims, and `packages/starter_kit` dependency. Explain how to select
  packages from `packages/genrevibes_starter_kit/modules` and connect them in the app.
- Replace outdated parts of `ARCHITECTURE_ANALYSIS.md`. Keep useful portfolio
  conventions, but distinguish them from requirements imposed by the kit.
  Existing apps do not need a state-management rewrite to adopt a kit feature.
- Make new-project, refactor, and project-structure instructions agree on the
  app layout. Explain that a package can still use its own private `lib/src`.
- Add a short repository entry point that directs agents to `agents/AGENTS.md`
  and the relevant skill. Check existing entry points before adding another.
- Keep operating rules in one place. Preserve the current analyzer permission
  and opt-in rules for tests and builds.

Done when a reader can find the right instructions without encountering two
different ways to initialize the kit.

## 2. Rewrite the app workflows

Update `projects/new` and `projects/refactor`, then add focused instructions for
upgrading the kit and replacing a provider.

- New app: choose features, add their packages, configure the selected providers,
  connect startup and cleanup, then connect the UI.
- Existing app: inspect what already works, replace one integration at a time,
  and preserve its routes, saved data, and product choices.
- Kit upgrade: compare the pinned revision and changed APIs, update affected
  integrations, and document any saved-data migration.
- Provider replacement: keep the shared feature interface and replace the
  adapter, credentials, and native configuration that actually differ.
- Fix template references to `agents/skills/mobile-app-skills/templates`.
- Update the submodule skill to use the actual checked-out paths. Document
  pinned revisions, nested repository changes, and clone verification. Do not
  describe the submodule as verified until a fresh recursive clone succeeds.

Do not copy the kit source into each app or recreate shared controllers there.
Do not install every provider by default.

## 3. Update the existing feature skills

Review all 47 existing skills. Use the earlier inventory as a starting list,
then check each instruction against the current code. A skill without an old
API reference still needs review.

| Area | Required changes |
|---|---|
| Ads and consent | Use the current providers and startup sequence. Let the SDK decide who needs a consent form. Attempt consent before ads; on failure or timeout, continue startup without inventing a consent grant. Preserve premium and placement rules. |
| Developer access | Reuse the kit's controller, passcode entry, registered devices, and switches. Explain how an app keeps defaults, overrides them, restricts actions, or opts out. Keep premium simulation separate from purchases. |
| IAP, paywall, content locking | Use one entitlement snapshot and the shared access policy. Handle purchased, restored, cancelled, pending, and failed outcomes separately. App product and entitlement IDs remain configurable. |
| Analytics, retention, crash reporting | Replace static facade examples with current providers and explicit startup wiring. Prevent duplicate events and listeners. Explain who owns cleanup. |
| Remote config and replay | Use one schema for the runtime and Lab. Distinguish kit defaults from app overrides, requested recording from applied recording, and changes that need a restart. |
| Feedback and settings | Open the shared form and settings components. Document attachment limits, timeout behavior, preserved input, provider limitations, and sensitive-content masking. |
| Push, onboarding, rating, splash, exit | Replace obsolete APIs and identify the callbacks, navigation, persistence, and platform setup owned by the app. |
| Auth, profile, Firebase | Separate shared interfaces and adapters from app identity, profile data, and backend authorization. Configure only the Firebase services the app uses. |
| Remaining mobile skills | Check commands, examples, links, and blanket rules. Keep useful branding, navigation, signing, localization, and release guidance. Remove irrelevant boilerplate. |
| Backend and commit skills | Review separately from Flutter integration. Preserve useful instructions; do not rewrite them merely because the kit changed. Inspect supporting files as well as SKILL.md. |

Story Saver settings must be labelled as examples. Its entitlement name, replay
rollout, WhatsApp permissions, navigation, and provider choices are not automatic
defaults for every app.

## 4. Fill the missing feature instructions

Add these skills where the current folder has no complete recipe:

| Skill | What it must explain |
|---|---|
| Runtime setup | Required and optional modules, visible loading/retry UI, deferred startup, timeouts, listener ownership, and cleanup before retry. |
| Kit Lab | Connect the same running modules, logger, and event recorder. Guard access. Explain unavailable modules and release-build logging choices. |
| Permissions | Request after the relevant user action, handle denial/settings, and recheck on resume without prompting again. Keep app-specific folder access separate. |
| Local notifications | Configure channels and permissions, handle taps after navigation is ready, update timezones, restore saved schedules, and cancel only owned notification IDs. |
| Storage migration | Preserve existing preferences with explicit key mappings. Cover onboarding, identity, developer settings, and rollout assignments. |

Keep control-panel instructions with Kit Lab and remote config. Keep
feedback/contact forms in the feedback skill. State clearly that the kit does
not currently provide a general form builder. Add another form skill only when
there is shared code for it to teach.

## 5. Make templates safe to reuse

- Compare environment templates with the current configuration readers. Add
  missing supported keys and explain which feature needs each key.
- Use placeholders for credentials and app identifiers. Remove personal device
  addresses and Story Saver values from generic templates.
- Make IDE configurations point to the files that are actually supplied.
- Keep one maintained example for repeated setup. Link to it from skills rather
  than maintaining several slightly different copies.
- Link API details to the kit documentation using portable relative paths.
  Record which kit revision the examples were checked against. The current
  uncommitted kit changes must not be presented as an available release.

## 6. Write every instruction plainly

Use these rules during the rewrite:

- Say what to do, where to do it, and why when the reason is not obvious.
- Use short sentences and ordinary words. Remove marketing language and claims
  such as “production-ready” without evidence.
- Replace “ensure robust integration” with the actual action, such as
  “Register the listener's cancel callback with the runtime scope.”
- State conditions explicitly: “If the app uses PostHog, mask the feedback
  route.” Do not turn optional integrations into universal requirements.
- Distinguish a required step, a shared default, and an app choice.
- Give exact imports and real API names in examples. Mark incomplete snippets
  and explain the values supplied by the app.
- Keep each skill focused on its task. Move lengthy provider setup into a
  linked reference only when it makes the skill easier to use.
- Remove repeated rules and generic Flutter tutorials. Keep enough explanation
  for a developer to understand the instructions without guessing.
- Do not add permission questions for routine work already authorized by the
  user. Keep the existing explicit limits on tests, builds, and external actions.

## 7. Check the rewritten guidance

- Check every skill's name, description, links, template paths, and referenced APIs.
- Search active guidance for the old facade and obsolete paths. Keep old API
  names only where they explain a migration; remove obsolete setup instructions.
- Walk through three cases using the written instructions: create a small app,
  add a shared feature to an existing app, and upgrade an older kit integration.
- Confirm that an app can omit ads, Firebase, or developer tools without the
  remaining instructions forcing them back in.
- Check that common features reuse kit code and need only app configuration
  and integration code.
- Run lightweight document/template checks. Use `flutter analyze` when checking
  changed Dart examples is useful. Tests and builds remain opt-in.
- Report exactly what was checked and what still needs a device or build.

CI: deferred TODO. Do not treat it as a blocker or repeat it in later audits
unless the user asks about CI.

## Order and completion

Do sections 1 and 2 first, then rewrite the feature skills and templates together.
Finish with the checks in section 7 and a short list of retained, rewritten,
merged, removed, and added skills. Update links before moving or merging files.

The revamp is complete when the guidance matches the current kit, covers the
shared features above, preserves app choices, and contains no active instructions
that require the old kit architecture. This plan does not authorize app changes,
commits, pushes, or deployment.
