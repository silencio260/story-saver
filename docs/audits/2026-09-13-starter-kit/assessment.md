# Starter kit, agent guidance and portfolio reuse audit

Date: 13 September 2026. Assessment: source and documentation audit of the local working tree.

Owner decision after this audit: CI is intentionally deferred and should appear
only as a small TODO in future reviews, not as a production-readiness blocker
for internal use. The CI analysis below is historical evidence, not an active
request. The current remediation scope is the starter kit and Story Saver;
agents/skills and other portfolio apps are excluded. See the
[active hardening plan](/Users/faruqshabi/AndroidStudioProjects/story_saver/packages/genrevibes_starter_kit/docs/production-hardening-plan.md).

## Verdict

**The revamped kit is a credible modular foundation for controlled reuse, but I would not approve it as the default production baseline for every portfolio app yet.** Much of the difficult extraction is already done. The weak points are release verification, some shared defaults, integration lifecycle ownership, and instructions that still describe a different architecture.

**The agents repository needs a coordinated rewrite of its entry points and old capability instructions.** Adding another skill will not fix the existing contradictions. Newer ads, developer-access, onboarding, splash and exit-prompt guidance contains useful current knowledge worth preserving.

**Many of the features you want are reusable now at the package level.** They are not equally ready as complete, documented app recipes. Forms are a feedback/contact implementation under active revision, rather than a general form system; its page API was reconciled during this audit. Kit Lab is reusable code with incomplete host wiring and no package README. Subscription and notification infrastructure are extracted, while app policy and journeys still require explicit composition.

| Dimension | Assessment | Meaning |
|---|---|---|
| Architectural separation | Strong foundation | Neutral contracts, adapters, optional UI, host-owned DI and instance-based lifecycle exist. |
| Production release evidence | Insufficient | CI configuration has demonstrable gaps; no fresh build/device evidence was produced in this audit. |
| Reuse by an engineer familiar with this app | Good, with conditions | Selected packages can be composed without copying the app. |
| Reuse by another developer or agent from instructions | Weak | The central skill teaches obsolete dependencies, APIs and DI. |
| Safety of universal defaults | Needs revision | Replay, developer unlock and entitlement interpretation should not be inherited unquestioningly. |
| Documentation coverage | Broad but inconsistent | 59 of 60 packages have READMEs; depth, correctness and onboarding instructions vary substantially. |
| Portfolio-wide portability | Not established | Appodeal native UI is Android-only; old Dart 2 apps cannot consume the current kit unchanged. |

These are qualitative assessments, not measured readiness percentages. No percentage would honestly represent store behavior or device coverage from source inspection alone.

## Scope and evidence

Inspected package manifests and inventories, architectural and migration documents, CI and verification scripts, the lifecycle coordinator, app composition and runtime registration, subscription facades, analytics/replay wiring, developer tools, forms, notification scheduling, permissions and representative capability tests. Inventoried all **47 SKILL.md files**, searched them for obsolete APIs and paths, and read the central workflows plus key capability guidance. Supporting backend, branding and release skills were inventoried for relevance; they were not exhaustively validated against external services.

The active kit contains **60 packages, 331 Dart files under package lib directories and 53 package test files** at the inventory point. Story Saver has **one test file**, containing multiple composition tests. Test-file counts do not measure coverage. Shared test-harness packages are intentionally different from production adapters. See the [complete package inventory](/Users/faruqshabi/AndroidStudioProjects/story_saver/docs/audits/2026-09-13-starter-kit/package-inventory.md) and [agent inventory](/Users/faruqshabi/AndroidStudioProjects/story_saver/docs/audits/2026-09-13-starter-kit/agent-inventory.md).

Baseline commits: app `5b335c6d29b30599c846fa61dc8e979eaa2c6e35`; kit `cab7f4f56a891f57982c192e0821e37aa6302530`; agents `ccc5ad07f71361083cb8aa73febab1b0a2df07c3`. The app, kit and agents have existing uncommitted edits, including concurrent settings, Lab and system-UI work. In particular, feedback UI changed while this audit was reading it. Findings about that package describe observed work in progress, not a defect claimed against a shipped release.

I also read top-level manifests in sibling AndroidStudioProjects directories as a limited compatibility sample. This is not a complete inventory of your commercial portfolio, and a sibling tutorial project is not assumed to be a portfolio product. No other app was modified or certified.

No Flutter analyzer, test suite, native build, store purchase, push delivery or hosted CI run was executed. The local [agents rule][agentrules] says: “Do not run `flutter test`, `flutter analyze`, builds, or other long validation suites unless the user explicitly asks for that command.” This audit therefore uses static checks and distinguishes code evidence from unverified runtime behavior. It does not give release sign-off. Production source and agent instructions were left unchanged.

## What the revamp got right

The actual [dependency model][architecture] is application → selected adapter → neutral capability → core. The coordinator depends only on core and does not impose GetIt or BLoC. That is the right basis for sharing features across apps using different state-management approaches.

Provider seams and typed `KitResult` failures make error behavior explicit. Clocks, injected vendor clients, module health, disabled registrations and legacy-key adoption are substantive engineering assets. [Existing tests][bootstraptests] exercise required/optional startup failures, identity migration, onboarding migration, consent ordering and premium-to-ad policy changes; this is more than an empty test directory.

Reusable UI often accepts app-owned content and rendering hooks. Onboarding accepts artwork builders and optional ad slots; settings is embeddable; permissions separates runtime policy from app-specific folder access. Optional RevenueCat UI, analytics sinks and native adapters avoid forcing every vendor into every consumer.

A read-only scan of the 20 neutral packages listed by the boundary script found no imports matching its vendor list. That is positive boundary evidence, but the hand-maintained list is not a complete dependency-graph proof.

Keep this architecture. The remediation should strengthen its adoption and release discipline rather than rebuild the old monolith around a new global facade.

## Findings that block broad production adoption

### F1 — CI can miss the code being changed, and its compatibility claims are stale

**Status: deferred owner backlog. Retained as historical configuration evidence;
not an active CI task. Actual package constraint defects are handled separately.**

The [pull-request workflow][ci] watches `packages/**`, although active code is in `modules/**`. A PR changing only modules can miss the workflow. Main/master pushes and manual dispatch still trigger it; the issue is the missing PR gate, not an assertion that CI never runs.

The [base tier][tiers] includes `genrevibes_analytics_posthog` at Flutter 3.19, but its [manifest][posthogspec] requires Flutter 3.27 and Dart 3.6. The same tier includes devtools, whose [dependency graph][devspec] includes `genrevibes_exit_prompt`, which requires Flutter 3.27. These minimum-tier combinations are internally inconsistent before any device testing.

Eight packages have no explicit minimum-tier assignment: Appodeal ads, Appodeal native ads, Appodeal consent, developer access, exit prompt, feedback UI, splash and system UI. The dynamic current tier discovers them, so this is missing lower-bound verification rather than complete exclusion from every check.

The [native smoke app][smoke] does not include the new Appodeal ads/native/consent packages, despite being described as covering every native provider. It cannot prove Story Saver's current ad graph.

**Acceptance:** watch modules, examples and relevant metadata; generate or validate tier membership and transitive floors; add native graphs for supported provider combinations; capture successful exact-version runs. Keep a distinct Android-only expectation for Appodeal native rendering.

### F2 — Shared developer unlock can grant app premium behavior

**Priority: high before widespread store-build reuse. Confirmed code path; not a claim of remote exploitation.**

[Developer configuration][devconfig] has a shared fallback passcode, and the [skill][devskill] documents shared unlock values. [SubscriptionManager][subscription] honors the saved premium override whenever developer access is granted. Therefore a store build using these access settings exposes more than read-only diagnostics: unlock can change premium behavior and ad eligibility.

Session-only grants, device allowlists, lockout and test-ad switching are useful safeguards. They do not make a compiled shared passcode a strong authorization boundary. The current developer-access skill itself acknowledges binary extraction.

**Acceptance:** separate diagnostic access from entitlement simulation and destructive actions. Disable the shared passcode fallback for ordinary store builds, or make the limited scope an explicit product decision. For stronger authorization, use revocable, scoped authorization appropriate to the app. Never treat local developer access as authorization for a paid backend resource. Add tests for unlock/relock, list removal, restart, premium override and ad-mode transitions.

### F3 — Replay defaults are unsuitable as an unquestioned portfolio default

**Priority: high for apps displaying private user content. Confirmed defaults; actual captured data not inspected.**

The [shared replay policy][replay] enables replay for 100% of users with text and image masking off. [App bootstrap][bootstrap] initializes product analytics as granted. These are deliberate current choices, not accidental missing values, but they should not silently propagate into chat, notes, accounts or feedback screens.

The remote-policy comments suggest masking can be enabled immediately. The [PostHog recorder][recorder] states masking is fixed during SDK setup; runtime controls only start/stop recording. Turning recording off and changing masking are different operations. A displayed policy change does not establish that an already-running SDK changed its mask behavior.

The app also forwards push title, body and arbitrary additional data into [analytics properties][payload]. That may copy sensitive notification content into multiple analytics sinks in another app.

**Acceptance:** specify analytics/replay policy per product; default new consumers to conservative capture; protect sensitive routes and fields; allowlist notification analytics properties. Document which changes apply immediately and which require reinitialization/relaunch. Verify on actual recordings. This is a data-handling assessment, not a legal compliance determination.

### F4 — The agents entry points would scaffold the obsolete kit

**Priority: high. Confirmed documentation/code contradiction.**

The [starter-kit skill][starterskill] teaches `packages/starter_kit`, `package:starter_kit`, a static `StarterKit.initialize`, internal GetIt, BLoCs and automatic vendor dependencies. The current kit has no such consumption model.

The [new-project workflow][newskill] copies the old package and creates `lib/src`, while the [project-structure skill][structureskill] explicitly forbids `lib/src`. The analytics skill tells consumers to inspect a [root kit pubspec][analyticsskill] that no longer exists and assumes vendors appear through the kit public surface.

**18 of the 47 skills contain old `StarterKit.` or old starter-kit path references.** This count identifies migration candidates, not 18 identically broken files: some mention the old API in explanatory prose.

**Acceptance:** rewrite starter integration, new/refactor workflows and their linked capability recipes together; quarantine old facade examples as legacy migration references. Validate examples against a pinned kit revision. All four shipped environment templates currently omit the Appodeal and developer-access keys required by newer guidance, and new-project copy commands point at the wrong template directory. Do not let an agent choose between contradictory current instructions.

### F5 — Fresh-clone submodule setup is broken

**Priority: high for reproducible adoption. Reproduced by read-only Git inspection.**

The app index contains a gitlink named `agents`, while [.gitmodules][submodules] declares `.agents`. `git submodule status` returned:

```text
fatal: no submodule mapping found in .gitmodules for path 'agents'
```

A setup guide that recommends recursive submodule initialization is not reliable in this checkout. The newer git-submodules skill repeats the mismatched `.agents` path. Existing dirty submodule state also means the parent commit alone does not identify the complete source being reviewed.

**Acceptance:** reconcile the actual gitlink, mapping and documented location; validate a fresh recursive clone; explicitly pin kit and guidance revisions in each app's adoption record. Do not mass-update every app to a floating kit branch.

### F6 — Lifecycle ownership is incomplete around the shared coordinator

**Priority: high for repeated composition and reliable failure handling. Static risk; not a reproduced crash.**

The coordinator provides coalesced initialization, per-module startup timeouts and reverse disposal. Its [dispose path][coordinator] awaits foreground initialization, but not deferred startup; `_disposed` is set only after disposal work. A deferred initialization can still be active while its module is disposed. A throwing module disposal can interrupt cleanup of the remaining modules.

App bootstrap creates policy binders, stream subscriptions, a singleton subscription listener, developer ad switches and recorders without collecting them into a disposable runtime owner. Calling `kit.dispose()` would not remove all host-side resources. This matters for tests, runtime replacement and future account/provider switching; process termination alone hides the issue in a simple app.

The claim that deferred startup begins “after the first frame” is also stronger than the implementation: [_startDeferred()][deferred] is launched before `kit.initialize()` returns, while `runApp` occurs later. It is off the awaited module chain, but not synchronized to a rendered frame.

**Acceptance:** provide one runtime owner that cancels host listeners and disposes owned resources, protect disposal against active deferred work and failures, and define when interactive deferred initialization may begin. Add meaningful deferred-start/dispose and late-callback regression cases.

### F7 — Required-module failure is recorded but has no app-level recovery decision

**Priority: medium/high, depending on which modules are required. Confirmed integration gap.**

[main.dart][main] continues registration and `runApp` without checking the initialization result. [AppRuntime.isHealthy][runtime] retains the startup result, but does not drive a retry screen, degraded mode or module-specific capability gate. The existing composition tests verify that failure is returned, not that the user can recover.

Do not indiscriminately refuse to launch when optional analytics fails. Conversely, a capability called “required” needs a defined user-visible failure behavior. Firebase initialization can throw before the Flutter app is rendered, and bootstrap contains awaits outside the coordinator's timeout protection. The splash package's bounded wait does not bound work before `runApp`.

**Acceptance:** define launch-critical versus optional capabilities, a total launch budget and recovery UI; route module failures to diagnostics; test a fresh offline launch and stalled/failed providers.

### F8 — Kit Lab can give a misleading picture of adoption and logs

**Priority: medium. Confirmed wiring gaps.**

The [host factory][labhost] omits local notifications, rating and onboarding even though AppRuntime contains them. Its comment says they are not adopted, which is stale. The [hub][lab] has a local-notifications page but no rating/onboarding entries despite host fields for both. “Capabilities wired” counts UI entries, not a complete package or migration inventory.

Bootstrap creates a [RecordingKitLogger][logger] and passes it to the Lab, but modules and the coordinator receive `BootstrapLogger`, not that recorder. The Kit log can be empty even while modules log elsewhere. Recorders are absent in release by design, so a store-build developer unlock does not retroactively create an event history.

The package has **no README, changelog or test files** in this snapshot. It is a high-value shared tool whose onboarding documentation is weaker than many simpler modules.

**Acceptance:** wire the actual runtime services, connect the recording logger, distinguish unavailable/not wired/not supported, document release diagnostics, and add a standalone host example. Gate the Lab route and sensitive actions explicitly in every consumer.

### F9 — Subscription infrastructure is reusable; current app policy is not generic

**Priority: medium/high before apps with multiple entitlements adopt the app facade.**

The neutral IAP provider, [entitlement policy][iap], RevenueCat adapter and optional hosted UI are reusable. However, [the app bridge][premiumbridge] treats any active entitlement as premium, while paywall methods default to `Pro`. That assumption can be correct for Story Saver and wrong for an app with separate “remove ads”, “pro tools” and content entitlements.

SubscriptionManager also holds WhatsApp folder-access and first-status milestones. Copying it would import Story Saver's ad-eligibility journey into other products. Additional snapshot state exists in RevenueCatService and presentation BLoCs.

[Custom purchase telemetry][revenue] emits USD with price zero and picks the first entitlement. This is not trustworthy revenue attribution across currencies or multiple products. Restore failures are logged inside a void-returning facade, limiting the UI's ability to distinguish failure from no active entitlement.

**Acceptance:** use named feature-to-entitlement mappings, preserve typed purchase/restore outcomes, choose one entitlement state authority, and record actual transaction data or clearly label non-revenue conversion events. Exercise pending/cancelled/restored/expired/offline/identity-change cases before rolling out to another monetized app.

### F10 — Feedback form API is now coherent; resilience and broader form reuse remain incomplete

**Priority: medium for resilience. Earlier transient export mismatch resolved before handoff.**

During initial inspection, [exports][formexports] still referenced sheet files while the implementation had moved to a page API. At the final recheck, the exports, app helper, [README][forms] and feedback skill all used `openFeedbackPage` / `FeedbackPage`. The two missing relative exports were gone. Concurrent work resolved that mismatch; this audit did not change production code. The package remains untracked and has not been compiled or exercised by this audit.

The implementation provides email/message validation, optional screenshot injection, labels, theme options and send-result handling. That makes it a reusable feedback/contact feature. It does not establish a general forms library for login, profile editing, dynamic fields, async validation, drafts, upload progress and submission policies.

The [form submission][formpage] awaits the provider without timeout/finally protection, while back navigation is blocked during sending. A provider that never settles can strand the page. The [FeedbackNest adapter][feedbackadapter] does not forward `FeedbackSubmission.metadata` into `submitCommunication`, despite metadata being exposed in the form contract.

**Acceptance:** keep the now-aligned exports, consumers, README and skill together in a coherent revision; verify keyboard/large text/back navigation/error recovery; define timeout behavior and honest metadata support. Extract a general form foundation only after a second different form establishes the shared requirements.

## Reuse and documentation assessment by feature

“Reusable” below means the abstraction already exists. It does not assert current release verification. Package README presence is not the same as a complete onboarding recipe.

| Feature | What is already shared | What stays in the app / still needs work | Documentation and readiness |
|---|---|---|---|
| Forms, feedback, contact | Neutral submission/attachments/provider, FeedbackNest adapter, UI extraction | Screenshot picker, product copy, sensitive-field policy; generic form engine absent | New page API, README and skill agree at final recheck; no package tests. Verify behavior before distribution. |
| Developer access | Controller, hashed device lists, lockout, remote binder, ad switches | Store access policy and permitted actions | Detailed newer skill; no package tests. Revise shared access defaults. |
| Kit Lab and controls | Nullable DevToolsHost, health, events, config, ads, purchases, permissions, storage and replay pages | Runtime wiring, route authorization, app event catalogue and storage keys | Inline docs useful; no README/tests; several host gaps. Good reuse candidate after F8. |
| Permissions | [Platform facts, policy, throttle, coordinator, rationale UI][permissions], permission_handler adapter | Native declarations, app copy, correct request moment, WhatsApp SAF grants | Good ownership explanation, limited full composition guidance. Validate permanent denial, limited access and resume. |
| Push notifications | Neutral state/events, OneSignal adapter; token-presence diagnostics | Credentials, APNs/FCM setup, identity/tags, notification routes and prompt timing | Package docs are brief; agent skill teaches obsolete repository API. |
| Local notifications | [OS-backed scheduler][notifications], timezone input, immediate/daily/interval scheduling, launch interaction handling | Native setup, channel/ID conventions, interaction subscription timing, timezone-change handling | Useful README/migration notes; no complete portfolio recipe. Device reboot/upgrade/DST/delivery not verified. |
| Notification campaigns | [Provider-neutral source and reconciliation][campaigns] | Targeting, quiet hours, frequency policies, localization and route meaning | Contracts exist; not a turnkey retention campaign product. Managed IDs must be configured deliberately. |
| Subscriptions/paywalls | Neutral IAP, RevenueCat and optional UI, contract harness | Product catalogue, account identity, entitlement policy and customer messaging | Thin/experimental package docs; IAP/paywall skills outdated. Sandbox-store proof still required. |
| Ads/consent | Ad policy, placements, provider adapters, separate consent | Provider choice, native mediation setup, app journey gates and placement decisions | Newer skills are substantial; Appodeal packages lack tests and smoke coverage. |
| Native ads | Styled Appodeal native view and event attribution | Platform alternative, layout and app placement | [Explicitly Android-only][native]. Other platforms show placeholder, not equivalent native ads. |
| Analytics/replay | Pipeline, multiple sinks, event naming, delivery observer, replay rollout | Product event catalogue, allowed properties, capture policy, actual revenue data | App analytics catalogue/docs are useful; central skill and replay comments conflict with code. |
| Remote config/control | Typed schema/codecs, provider/cache adapters, policy binders, per-key origin | Product keys, targeting, rollout ownership and refresh lifecycle | New refresh guidance is valuable. Generate templates from schema to prevent drift. |
| Onboarding | [Completion migration, flow, actions, artwork/ad slots][onboarding] | Brand assets, localization, routes, paywall/permission sequence | Among the better documented modules. Current UI growth needs corresponding widget/lifecycle evidence. |
| Settings | [Embeddable typed rows and list][settings] | Product settings, persistence, feature visibility and actions | Clear package scope; old settings skill still teaches a static facade. |
| Splash | [Bounded flow, progress and optional ad seam][splash] | Pre-runApp startup, destination selection and approved ad policy | Good package/skill guidance; no package tests and missing minimum tier. |
| Exit and system UI | Configurable exit styles and navigation-bar ownership | Appropriate experience per app/platform | Useful new skills; test/minimum-tier gaps. Do not force immersive behavior into every product. |
| Rating/engagement | Eligibility, cooldowns, storage migration, outcomes, retention | Trigger definitions, copy, feedback/store routing | Reusable policy exists; app-rating/retention agent guidance still old. |
| Storage and identity | Key-value adapter, legacy adoption, install/vendor identity seams | Per-app namespaces, migration aliases and identity purpose | Strong reuse building blocks. Portfolio scope depends on installation/distribution context. |
| Links | Store/support/privacy/share actions and launcher adapter | Real per-platform URLs and localized messages | Reusable mechanism; verify iOS URLs, because current bootstrap supplies a Play URL only. |
| Crash reporting | Neutral coordinator, Crashlytics adapter and hooks | Pre-start failures, redaction, error/retry UX | Package extraction exists; crashlytics skill still describes direct old wiring. |
| Auth/database | Neutral contracts, Firebase adapters and harnesses | Account deletion, rules, authorization, profile/domain models, migrations | Present but not exercised by Story Saver's real product flows. Need an authenticated-app pilot. |
| Media/status/background saving | Some generic helper algorithms could be extracted later | WhatsApp folders, media pipeline, WorkManager jobs, gallery and first-status journey | App-specific behavior docs exist. Do not put this into the universal baseline. |

## How I would structure portfolio reuse

Use four ownership layers:

1. **Shared capability packages:** stable contracts, models, lifecycle, persistence seams and provider-independent policies.
2. **Selected adapter and UI packages:** vendor/native integration plus optional reusable presentation.
3. **Versioned portfolio recipes:** composition, env/schema templates, diagnostics wiring and release checks for a particular app profile. These recipes must be executable examples, not just prose.
4. **App-owned product behavior:** brand, navigation, event names, permission rationale, entitlements, store links, business rules and background work.

Almost-every-app defaults can include error handling, storage, settings primitives, app links/support, a protected developer entry and Kit Lab integration. Permissions should be available where needed, not eagerly requested. Notifications, subscriptions, ads, auth and replay should be selected modules; installing every vendor would reverse the benefit of this revamp.

Useful profiles are a minimal app, an ad-supported utility, a subscription app, and an authenticated content app. Keep monetization policy and provider selection explicit in each. State management should remain the consumer's choice; copying the app's GetIt singleton services is not a requirement of the kit.

The sibling manifest sample includes newer Dart 3 projects such as `tiktok_video_downloader` (declares Dart ^3.7.0), as well as many older projects constrained below Dart 3. Those older projects need a language/toolchain migration first. A Dart constraint alone does not prove native adapter compatibility. Native Appodeal UI has a separate Android-only limitation. `ai_chatbot` and `note_ai` appear in kit planning docs, but their implementations were not available in the inspected sibling manifests, so auth/database readiness for them remains unverified.

The next adoption should be one real second app, preferably a different domain, using only its chosen packages. A fresh-clone build plus an actual end-to-end feature journey there is a much better portability proof than copying all of Story Saver into another directory.

## Agents revamp plan

### Rewrite the control documents first

Replace the boilerplate mobile-skills README with an index that declares the current kit architecture, supported revision range, workflow entry points and deprecated material. Fix the agents submodule path. Add an explicit repository entry point for discovering these instructions; `agents/AGENTS.md` should not be assumed to automatically govern all application files simply because it exists in a nested folder.

The central integration recipe should teach selected dependencies, root-level consumer overrides where needed, native setup, composition, legacy-state adoption, one runtime owner, health and diagnostics. Document the difference between a kit requirement and a portfolio preference such as BLoC.

### Migrate the old skills as one linked change

Rewrite starter-kit, new/refactor, IAP/paywall/content-locking, settings, app-rating, notifications, analytics/extension/retention, consent, auth/profile, navigation, crash and Firebase integration examples. Keep app-specific behavior out of their generic instructions. The [remote-config claim][remoteskill] that missing startup refresh “cannot be caught by a test” should be corrected: a composition test with a spy provider can verify that bootstrap requests refresh. A text search cannot prove runtime invocation.

Preserve and reconcile the newer ads, developer access, onboarding, splash, exit prompt, immersive UI, feedback, env and remote-config content. These are partly current; they need a common contract, not deletion. The newly updated feedback skill also refers to Story Saver's `SettingsPageStyle.feedback`; document that as a host example rather than a kit-provided API. Avoid stating Appodeal or immersive navigation as universal requirements when the architecture supports selection.

Add missing recipes for Kit Lab, runtime/lifecycle composition, permission journeys, local notifications/campaigns, storage migration, provider replacement and release verification. Keep reusable field/form patterns separate from the feedback recipe if a genuine second form requires them.

Each skill should declare: trigger/scope, kit revision or API version, selected packages, host/native requirements, working composition example, configurable product decisions, migration keys, failure/lifecycle behavior, validation expectations and links to canonical docs. Remove duplicated sample passcodes and app-specific identifiers from generic templates.

### Prevent drift rather than adding more prose

Maintain a machine-readable capability manifest containing package role, platform support, Flutter floor, provider/native requirements, skill/doc/example references and verification status. Generate package/skill indexes and compatibility membership from it. Check broken links, missing exports, stale package names and schema/template keys automatically. Compile the examples against the revision the skills claim to support.

The current opt-in validation policy should remain a deliberate user preference, but it must not support a “production ready” label without evidence. Clarify lightweight checks versus expensive/device commands, and let CI supply mandatory release verification independently of interactive agent work.

## Prioritized implementation sequence

| Order | Work | Completion evidence |
|---|---|---|
| 1 | Verify the reconciled feedback API and snapshot all existing work coherently | Exports, consumer, README and skill agree; app resolves that pinned package. |
| 2 | Repair submodule mapping and CI triggers/tiers/native graphs | Fresh recursive clone; every changed package is gated; successful supported-tier and native builds. |
| 3 | Decide developer access, replay defaults and named entitlement policy | Explicit per-app policy; release-mode behavior verified; no accidental premium/replay inheritance. |
| 4 | Close lifecycle, startup recovery and Lab wiring gaps | Deferred-disposal/retry coverage; populated logs; actual capability availability shown. |
| 5 | Rewrite agent entry points and obsolete recipes against the stabilized kit | New-app example builds using only documented instructions; obsolete APIs confined to legacy references. |
| 6 | Migrate one second app and document every host-specific step | Real store-sandbox purchase/restore, permissions, notifications and device journeys for its selected features. |
| 7 | Establish portfolio releases | Per-app pins, changelogs, upgrade/rollback notes, adoption matrix and repeatable release checks. |

Suggested commands for a later validation run, after the static defects are fixed:

```sh
# In the starter-kit repository:
bash tool/test_compatibility_tier.sh current
# Run each documented minimum tier with its matching installed Flutter SDK.

# In Story Saver:
flutter analyze
flutter test test/bootstrap/app_bootstrap_test.dart

# In each supported native smoke graph:
flutter build apk --release
flutter build ios --release --no-codesign
```

Build success is still not proof of purchase settlement, ad gating, push receipt, permission recovery, replay masking or notification delivery after reboot. Record those separately with app/provider/toolchain/OS/revision details.

## Release decision

**Controlled pilot reuse: yes, once the selected graph is stable and verified. Universal production adoption: no, pending the findings above. Public package publishing: not ready by the repository's own release gates.**

All packages inspected use private prerelease publication settings; no package-local license was found. Internal reuse does not require pub.dev, and lack of a publish dry run does not by itself make an internal app unsafe. What internal reuse does require is reproducible dependency resolution, compatible versions, supported native setups, reliable behavior and instructions that build the actual kit.

The most valuable next investment is to turn the code that already exists into a tested, documented adoption path. There is enough reusable architecture here to justify that work.

[architecture]: /Users/faruqshabi/AndroidStudioProjects/story_saver/packages/genrevibes_starter_kit/docs/architecture.md:17

[ci]: /Users/faruqshabi/AndroidStudioProjects/story_saver/packages/genrevibes_starter_kit/.github/workflows/package-compatibility.yml:4

[tiers]: /Users/faruqshabi/AndroidStudioProjects/story_saver/packages/genrevibes_starter_kit/tool/test_compatibility_tier.sh:33

[posthogspec]: /Users/faruqshabi/AndroidStudioProjects/story_saver/packages/genrevibes_starter_kit/modules/analytics/genrevibes_analytics_posthog/pubspec.yaml:6

[devspec]: /Users/faruqshabi/AndroidStudioProjects/story_saver/packages/genrevibes_starter_kit/modules/devtools/genrevibes_devtools/pubspec.yaml:10

[smoke]: /Users/faruqshabi/AndroidStudioProjects/story_saver/packages/genrevibes_starter_kit/examples/genrevibes_smoke_app/pubspec.yaml:10

[kitreadme]: /Users/faruqshabi/AndroidStudioProjects/story_saver/packages/genrevibes_starter_kit/README.md:7

[roadmap]: /Users/faruqshabi/AndroidStudioProjects/story_saver/packages/genrevibes_starter_kit/docs/package-roadmap.md:68

[risks]: /Users/faruqshabi/AndroidStudioProjects/story_saver/packages/genrevibes_starter_kit/docs/toolchain-risks.md:7

[submodules]: /Users/faruqshabi/AndroidStudioProjects/story_saver/.gitmodules:1

[agentrules]: /Users/faruqshabi/AndroidStudioProjects/story_saver/agents/AGENTS.md:3

[starterskill]: /Users/faruqshabi/AndroidStudioProjects/story_saver/agents/skills/mobile-app-skills/starter-kit/SKILL.md:8

[newskill]: /Users/faruqshabi/AndroidStudioProjects/story_saver/agents/skills/mobile-app-skills/projects/new/SKILL.md:19

[structureskill]: /Users/faruqshabi/AndroidStudioProjects/story_saver/agents/skills/mobile-app-skills/skills/project-structure/SKILL.md:12

[analyticsskill]: /Users/faruqshabi/AndroidStudioProjects/story_saver/agents/skills/mobile-app-skills/skills/analytics/SKILL.md:18

[remoteskill]: /Users/faruqshabi/AndroidStudioProjects/story_saver/agents/skills/mobile-app-skills/skills/remote-config/SKILL.md:89

[devconfig]: /Users/faruqshabi/AndroidStudioProjects/story_saver/packages/genrevibes_starter_kit/modules/devtools/genrevibes_developer_access/lib/src/developer_access_config.dart:8

[devskill]: /Users/faruqshabi/AndroidStudioProjects/story_saver/agents/skills/mobile-app-skills/skills/developer-access/SKILL.md:75

[subscription]: /Users/faruqshabi/AndroidStudioProjects/story_saver/lib/features/monetization/data/services/subscription_service.dart:74

[premiumbridge]: /Users/faruqshabi/AndroidStudioProjects/story_saver/lib/bootstrap/app_bootstrap.dart:303

[revenue]: /Users/faruqshabi/AndroidStudioProjects/story_saver/lib/features/monetization/data/services/revenue_cat_service.dart:123

[replay]: /Users/faruqshabi/AndroidStudioProjects/story_saver/packages/genrevibes_starter_kit/modules/remote_config/genrevibes_remote_policy/lib/src/session_replay_policy_keys.dart:22

[recorder]: /Users/faruqshabi/AndroidStudioProjects/story_saver/packages/genrevibes_starter_kit/modules/analytics/genrevibes_analytics_posthog/lib/src/posthog_session_replay_recorder.dart:48

[bootstrap]: /Users/faruqshabi/AndroidStudioProjects/story_saver/lib/bootstrap/app_bootstrap.dart:129

[payload]: /Users/faruqshabi/AndroidStudioProjects/story_saver/lib/bootstrap/app_bootstrap.dart:395

[main]: /Users/faruqshabi/AndroidStudioProjects/story_saver/lib/main.dart:77

[runtime]: /Users/faruqshabi/AndroidStudioProjects/story_saver/lib/bootstrap/app_runtime.dart:164

[coordinator]: /Users/faruqshabi/AndroidStudioProjects/story_saver/packages/genrevibes_starter_kit/modules/foundation/genrevibes_starter_kit/lib/src/starter_kit.dart:217

[deferred]: /Users/faruqshabi/AndroidStudioProjects/story_saver/packages/genrevibes_starter_kit/modules/foundation/genrevibes_starter_kit/lib/src/starter_kit.dart:206

[labhost]: /Users/faruqshabi/AndroidStudioProjects/story_saver/lib/features/developer/dev_tools_entry.dart:41

[lab]: /Users/faruqshabi/AndroidStudioProjects/story_saver/packages/genrevibes_starter_kit/modules/devtools/genrevibes_devtools/lib/src/dev_tools_hub_screen.dart:29

[logger]: /Users/faruqshabi/AndroidStudioProjects/story_saver/packages/genrevibes_starter_kit/modules/devtools/genrevibes_devtools/lib/src/recording_kit_logger.dart:51

[forms]: /Users/faruqshabi/AndroidStudioProjects/story_saver/packages/genrevibes_starter_kit/modules/feedback/genrevibes_feedback_ui/README.md:8

[formexports]: /Users/faruqshabi/AndroidStudioProjects/story_saver/packages/genrevibes_starter_kit/modules/feedback/genrevibes_feedback_ui/lib/genrevibes_feedback_ui.dart:4

[formpage]: /Users/faruqshabi/AndroidStudioProjects/story_saver/packages/genrevibes_starter_kit/modules/feedback/genrevibes_feedback_ui/lib/src/feedback_page.dart:134

[feedbackadapter]: /Users/faruqshabi/AndroidStudioProjects/story_saver/packages/genrevibes_starter_kit/modules/feedback/genrevibes_feedbacknest/lib/src/feedbacknest_feedback_provider.dart:89

[permissions]: /Users/faruqshabi/AndroidStudioProjects/story_saver/packages/genrevibes_starter_kit/modules/permissions/genrevibes_permissions/README.md:3

[notifications]: /Users/faruqshabi/AndroidStudioProjects/story_saver/packages/genrevibes_starter_kit/modules/notifications/genrevibes_notifications_local/README.md:3

[campaigns]: /Users/faruqshabi/AndroidStudioProjects/story_saver/packages/genrevibes_starter_kit/modules/notifications/genrevibes_notifications/lib/src/notification_campaign_coordinator.dart:8

[iap]: /Users/faruqshabi/AndroidStudioProjects/story_saver/packages/genrevibes_starter_kit/modules/iap/genrevibes_iap/lib/src/entitlement/entitlement_access_policy.dart:1

[onboarding]: /Users/faruqshabi/AndroidStudioProjects/story_saver/packages/genrevibes_starter_kit/modules/onboarding/genrevibes_onboarding/README.md:24

[settings]: /Users/faruqshabi/AndroidStudioProjects/story_saver/packages/genrevibes_starter_kit/modules/settings/genrevibes_settings/README.md:3

[splash]: /Users/faruqshabi/AndroidStudioProjects/story_saver/packages/genrevibes_starter_kit/modules/splash/genrevibes_splash/README.md:38

[native]: /Users/faruqshabi/AndroidStudioProjects/story_saver/packages/genrevibes_starter_kit/modules/ads/genrevibes_ads_appodeal_native/README.md:71

[boundaries]: /Users/faruqshabi/AndroidStudioProjects/story_saver/packages/genrevibes_starter_kit/tool/verify_package_boundaries.sh:17

[bootstraptests]: /Users/faruqshabi/AndroidStudioProjects/story_saver/test/bootstrap/app_bootstrap_test.dart:30

[coordinatortests]: /Users/faruqshabi/AndroidStudioProjects/story_saver/packages/genrevibes_starter_kit/modules/foundation/genrevibes_starter_kit/test/starter_kit_test.dart:73

[appdocs]: /Users/faruqshabi/AndroidStudioProjects/story_saver/ARCHITECTURE_MIGRATION_MAP.md:3
