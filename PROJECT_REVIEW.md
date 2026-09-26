**Sigma Training — project review and improvement plan**

Reviewed September 25–26, 2026, at commit `043069d`.

**Updated release direction — strength training only**

The implemented 1.7 release removes warm-up, cool-down, and cardio from the active interface while those features await redesign. This supersedes the original recommendations below to improve their current screens.

The interface has two main destinations:

| Destination | Contents |
| --- | --- |
| Train | A compact today summary, Continue last exercise, muscle groups with exercise counts/last trained dates, and visible add/manage actions. A settings icon opens settings directly. |
| History | A strength-only calendar with selectable days and editable set history. Historical cardio does not contribute to its marks or totals. |
| Exercise screen | Name and brief previous-training summary; reps/weight and primary Log Set action; today's sets with repeat/edit/delete; older history and clearly labeled Progress/Instructions destinations. |
| Compact rest bar | Remaining time, start/pause, and an expand arrow. Empty-area tapping also expands/collapses adjustments. Its separate layout row resizes the content above without overlap. |

Retain the existing palette, but reduce nested cards, category headings, oversized progress summaries, and decorative content. Use flexible row/card heights and accessible controls. Day-based summaries can be derived from existing sets; this release does not require a new workout-session data model.

**Compatibility approach for this release**

1. Keep the existing app identifier, store location, all seven registered SwiftData model types, and their persisted fields/relationships unchanged. Remove the retired screens, navigation, active queries, and default-guide seeding. Retained model definitions are an intentional compatibility boundary.
2. Preserve existing CardioLog, GuideItem, MuscleGroupGuide records, their IDs/links/order/custom instructions, and existing guide completion values in UserDefaults. The guide completion values contain the last checked date, not a complete historical log. These records become hidden retained data, not a new archive schema. Fresh installations no longer create unused guides.
3. Preserve exercise/set IDs, timestamps, weights, reps, custom ranges, instructions/videos, group assignments, and settings. An ordinary update must not reset, reseed, or erase the store. An explicitly requested full-data erase must accurately include retained hidden data; resetting settings must not erase records.
4. Fix the existing retention defect before shipping: opening an exercise must not detach older records. Prefer retaining all training history. Keep the old retention field readable for compatibility even if automatic pruning and its setting are retired. Do not automatically discard or guess ownership of existing orphan sets.
5. Avoid introducing the name-to-ID relationship migration in the same UI simplification. Stop the harmful capitalization mismatch and repair only unambiguous existing links. Introduce deeper schema changes later with versioned schemas, explicit migration steps, and real upgrade fixtures.
6. Test an actual old on-disk store with the new build, then save, close, and reopen it. Compare record counts, IDs, values, and relationships before/after, including hidden entities and guide preferences. Cover populated/custom/empty stores, existing invalid weights, duplicate names, old settings, and orphan records. Back up fixtures and never overwrite a real user's store to recover from an upgrade error.

Removing view code alone does not require a database transformation when the persistent schema remains unchanged. Future model changes should use SwiftData's schema migration mechanisms; see [Apple's schema migration guidance](https://developer.apple.com/videos/play/wwdc2025/291/).

**Implementation and verification**

- Implemented Train/History navigation, visible group management, stable exercise ordering/search, focused set entry with repeat/edit/delete/undo, separate Progress/Instructions, and one shared compact rest timer.
- Removed the retired screens and template widgets. Kept all seven persisted model types, fields/defaults/relationships, and the original app identifier/store location.
- Removed history pruning and guide seeding. Added bounded weight validation, draft forms, explicit save errors, complete full-erase handling, conservative legacy repairs, and calendar locale fixes.
- Final Xcode simulator run passed all 28 unit tests and both workflow UI tests with zero failures. Coverage includes logging/edit/undo, cross-tab deletion navigation, history preservation, invalid inputs, retained data, reset/save failures, timer transitions, and calendar arithmetic. Train, Exercise, and History screenshots were inspected, with an additional large-text/dark-mode Train check.
- Build 3 follow-up: both workflow UI tests passed again, including checks that final exercise/history rows scroll completely above the collapsed and expanded timer. Empty-area and arrow toggles work independently of Start/Pause and adjustment actions. Installed and launched the signed build on the connected iPhone for user verification.
- The reproducible [old-store check](TestsSupport/LegacyCompatibility/README.md) writes SQLite using model source from the baseline Git commit, opens/prepares/saves/reopens it with current production code, and compares every persisted field, ID, and relationship across all seven types.
- Notification delivery and Live Activities still need physical-device validation. Full VoiceOver and small-phone walkthroughs remain follow-up checks; timer restoration after process termination remains outside this release.

**Completed order of work**

1. Repair the test baseline and add upgrade fixtures; fix history preservation and weight validation.
2. Remove the retired UI and seeding, simplify the calendar to strength, and preserve its underlying legacy records.
3. Implement Train/History navigation and the streamlined set-entry/rest flow; complete group management and set correction.
4. Remove unused view code and template widgets; validate timer behavior, accessibility, and real old-store upgrades.

The first release should finish when existing strength history remains intact, retained cardio/guides survive an upgrade and relaunch, the retired sections are absent from the active UI, and the log–rest–repeat flow works without hidden actions.

**Original audit findings**

The following is the pre-change audit at `043069d`. Findings and line references describe that baseline; several referenced files have since been removed or rewritten. The implementation status above supersedes its baseline test and source-change statements.

The app has a useful foundation: native SwiftUI navigation and forms, a consistent visual theme, reusable exercise guides, a return-to-last-exercise shortcut, and helpful logging defaults. The first investment should be reliability and completing existing workflows. A broad rewrite is unnecessary.

**Scope and verification**

- Reviewed interaction design, UI structure, functionality, persistence, timer/widget behavior, tests, and redundant code across the roughly 4,400 lines of app and widget Swift source.
- The app and widget extension build successfully with Xcode 16.4 for the iOS simulator.
- The existing test command fails during compilation: `PersonalTrainerAppTests.swift:192` has an extra closing brace. No passing test-suite result is claimed.
- A disposable harness using the real model, migration, and view-model code reproduced orphaned history records, missing guide links after reset, a group-name migration mismatch, and an out-of-range initial logged weight. This ran against macOS SwiftData with an in-memory store; iPhone regression tests remain necessary.
- A separate Swift executable confirmed that a zero stride crashes. Source tracing confirms the Add Exercise flow accepts and persists that value before opening the affected picker.
- Interactive simulator inspection stalled. UI findings below come from source inspection, not a completed visual, VoiceOver, or large-text walkthrough. Live Activity/background behavior still requires physical-device checks.
- No application source was changed. This report is the only added project file.

**1. Interaction design**

The main flow should make selecting an exercise, recording a set, resting, and recording the next set fast and predictable.

| Finding | User impact | Recommended change |
| --- | --- | --- |
| The collapsed timer shows a time and progress bar without a start/pause control or clear expand affordance. | Every rest requires opening a large panel. | Add a compact “Rest” label, start/pause, and expand button; preserve the detailed panel for adjustments. |
| The exercise screen puts a tall progress section above set entry when prior history exists. | Repeated logging receives less prominence than secondary information. | Put the set composer first and reduce progress to a compact summary. |
| Exercise order changes after logging and only five items are initially shown. | Users lose stable positions and must expand to find less-recent exercises. | Offer a clear Recent/All choice and a stable order; add search if the library grows. |
| Tapping a historical set copies its values without an explicit affordance. | The shortcut is useful but hard to discover and can be mistaken for editing. | Name the action “Repeat set”; provide a separate Edit action and undo after logging. |
| The instructions destination starts with progress charts, followed by video and instructions. | The destination does not match its “Exercise instructions” label. | Separate Progress and Instructions, or place instructions first. |
| “Log Run” immediately inserts a 30-minute run. | A button that appears to open a form instead records an undisclosed value. | Open a prefilled form, or label the action “Log 30-min run” and offer undo. |
| Groups can be deleted, but the AddMuscleGroupSheet is unreachable. | A removed group cannot be restored individually; the empty-state instruction has no action. | Add visible group management, including add/rename and an intentional restore-defaults action. |

Evidence: [TimerView.swift:122](/Users/jdai/Documents/APPS/personaltrainerapp/PersonalTrainerApp/PersonalTrainerApp/TimerView.swift:122), [ExerciseDetailView.swift:30](/Users/jdai/Documents/APPS/personaltrainerapp/PersonalTrainerApp/PersonalTrainerApp/ExerciseDetailView.swift:30), [ExerciseListView.swift:34](/Users/jdai/Documents/APPS/personaltrainerapp/PersonalTrainerApp/PersonalTrainerApp/ExerciseListView.swift:34), [ExerciseInstructionView.swift:19](/Users/jdai/Documents/APPS/personaltrainerapp/PersonalTrainerApp/PersonalTrainerApp/ExerciseInstructionView.swift:19), [CardioSectionView.swift:48](/Users/jdai/Documents/APPS/personaltrainerapp/PersonalTrainerApp/PersonalTrainerApp/CardioSectionView.swift:48), [StrengthTrainingView.swift:84](/Users/jdai/Documents/APPS/personaltrainerapp/PersonalTrainerApp/PersonalTrainerApp/StrengthTrainingView.swift:84).

**2. UI and accessibility**

Keep the existing palette and native controls. Focus on hierarchy, readable data, and adaptable layouts.

- Muscle cards have a fixed 110-point height and two columns; cardio cards also use fixed dimensions. Replace rigid heights with content-driven layouts, and allow one column at larger text sizes. Clipping has not been visually reproduced.
- Calendar days use tap gestures and roughly 30-point-wide content without full date, activity, and selected-state accessibility labels. Use semantic buttons with appropriately sized hit regions and combined labels. Give the collapsed timer and guide completion controls explicit actions and states.
- Selected/today calendar activity dots turn white, but their colored background is behind the day number rather than the dots. Inspect and correct this in light mode. Verify selected-day contrast in dark mode as well.
- Charts hide their horizontal axes and space training days equally. Show actual dates or clearly describe “Last N training days”; provide exact values and a useful single-entry state.
- Keep essential text readable without relying on category colors alone. Verify all key screens in light/dark mode, large Dynamic Type, VoiceOver, and a smaller phone width before accepting the UI changes.

Evidence: [StrengthTrainingView.swift:226](/Users/jdai/Documents/APPS/personaltrainerapp/PersonalTrainerApp/PersonalTrainerApp/StrengthTrainingView.swift:226), [CalendarSectionView.swift:143](/Users/jdai/Documents/APPS/personaltrainerapp/PersonalTrainerApp/PersonalTrainerApp/CalendarSectionView.swift:143), [CalendarSectionView.swift:219](/Users/jdai/Documents/APPS/personaltrainerapp/PersonalTrainerApp/PersonalTrainerApp/CalendarSectionView.swift:219), [ExerciseAnalyticsView.swift:52](/Users/jdai/Documents/APPS/personaltrainerapp/PersonalTrainerApp/PersonalTrainerApp/ExerciseAnalyticsView.swift:52).

**3. Functional defects, ranked by impact**

P1 means fix before further feature work. P2 means fix in the next reliability iteration.

| Priority | Finding and evidence | Improvement |
| --- | --- | --- |
| P1 | **Reachable weight-picker crash.** Add Exercise only validates the name. A zero step reaches `Array(stride(...))`, which traps; tiny increments and huge ranges also risk excessive allocation. Existing settings mutate the model before Done validation. [AddExerciseSheet.swift:78](/Users/jdai/Documents/APPS/personaltrainerapp/PersonalTrainerApp/PersonalTrainerApp/AddExerciseSheet.swift:78), [ExerciseDetailView.swift:101](/Users/jdai/Documents/APPS/personaltrainerapp/PersonalTrainerApp/PersonalTrainerApp/ExerciseDetailView.swift:101). | Use draft form state and shared validation for finite values, ordered bounds, positive increments, and a bounded choice count. Guard picker construction and repair invalid saved configurations. |
| P1 | **History cleanup creates orphan records.** Opening an exercise runs cleanup. With five logged days and a limit of four, the harness found four linked sets but five stored records, including one orphan. Calendar can display the leftover record as “Unknown.” [Models.swift:150](/Users/jdai/Documents/APPS/personaltrainerapp/PersonalTrainerApp/PersonalTrainerApp/Models.swift:150). | Stop automatic disconnection of history. Preserve history by default; if deletion is retained, use explicit context deletion and clear consent. Audit existing orphans without guessing their original exercise or silently discarding them. |
| P2 | **New custom exercises can log an invalid default weight.** A 50–100 lb range retains the constructor's 20 lb default, and Add Set records 20. Reproduced using the real view model. [ExerciseDetailViewModel.swift:19](/Users/jdai/Documents/APPS/personaltrainerapp/PersonalTrainerApp/PersonalTrainerApp/ExerciseDetailViewModel.swift:19). | Normalize the selection after creation/settings changes and validate again when logging. |
| P2 | **Capitalization migration can hide legacy exercises.** It changes group names without changing the string used by exercises to reference those groups. Reproduced with a lowercase custom group. [DataMigration.swift:58](/Users/jdai/Documents/APPS/personaltrainerapp/PersonalTrainerApp/PersonalTrainerApp/DataMigration.swift:58). | Repair both sides atomically; migrate to a stable group identity/relationship. |
| P2 | **Reset leaves guides in an inconsistent state.** Group deletion removes guide links, while GuideItem records remain. Reseeding skips links whenever any guide exists. Reproduced in the persistence harness. [SettingsSheet.swift:119](/Users/jdai/Documents/APPS/personaltrainerapp/PersonalTrainerApp/PersonalTrainerApp/SettingsSheet.swift:119), [ContentView.swift:107](/Users/jdai/Documents/APPS/personaltrainerapp/PersonalTrainerApp/PersonalTrainerApp/ContentView.swift:107). | Centralize initialization/reset and deliberately recreate both catalog items and associations. Define which settings and custom content reset should remove. |
| P2 | **Calendar weekday alignment is wrong in Monday-first regions.** Headers honor firstWeekday; the date offset assumes Sunday. [CalendarSectionView.swift:181](/Users/jdai/Documents/APPS/personaltrainerapp/PersonalTrainerApp/PersonalTrainerApp/CalendarSectionView.swift:181). | Compute the offset from the calendar's firstWeekday and test both conventions. Give padding cells distinct identities. |
| P2 | **Past cardio entries have no correction path.** Users can choose any date when adding cardio, but delete is available only for today's cards and calendar history is read-only. [CardioSectionView.swift:163](/Users/jdai/Documents/APPS/personaltrainerapp/PersonalTrainerApp/PersonalTrainerApp/CardioSectionView.swift:163). | Reuse a detail/edit/delete sheet for both dashboard and calendar entries. |
| P2 | **Changing the default rest duration does not update the current timer.** The setting is used only to initialize persistent view state. [TimerView.swift:10](/Users/jdai/Documents/APPS/personaltrainerapp/PersonalTrainerApp/PersonalTrainerApp/TimerView.swift:10). | Define an update policy: apply immediately while idle and to the next rest while running. |
| P2 | **Live Activity ownership has a pause/resume race.** An asynchronous end of the old activity clears the stored handle after a new activity may have been assigned. [TimerManager.swift:209](/Users/jdai/Documents/APPS/personaltrainerapp/PersonalTrainerApp/PersonalTrainerApp/TimerManager.swift:209). | Clear the old handle before awaiting or compare identities; isolate timer state and serialize lifecycle operations. This interleaving is source-proven, not reproduced on a device. |
| P2 | **The widget bundle exposes unfinished templates.** A “Favorite Emoji” widget ships alongside a timer control whose provider always reports running and whose action does nothing. [WidgetBundle.swift:14](/Users/jdai/Documents/APPS/personaltrainerapp/PersonalTrainerApp/PersonalTrainerAppRestTimerWidget/PersonalTrainerAppRestTimerWidgetBundle.swift:14). | Remove template registrations now; retain the real Live Activity. Implement other widgets only with working shared state and actions. |

Additional functional decisions:

- Retention currently means the last four distinct training dates per exercise by default, runs only when that exercise opens, and does not apply to cardio. “Keep Last N days” does not describe this accurately. It also undercuts charts intended to show seven logged days. Prefer full history with explicit export/archive/delete controls.
- Bodyweight exercises use zero external weight, so their volume and suggested volume remain zero. Support rep-based progress or an explicit bodyweight/added-load mode. This is a metric-design limitation, not an arithmetic bug.
- Calendar grouping uses exercise names, so different exercises with identical names are merged. Group by persistent identity and display name/group separately.
- Empty-store checks are treated as first-launch detection, so deliberately removed defaults can reappear. Track completed initialization separately.
- Timer completion needs an explicit policy for returning from background, notification delivery, and relaunch. The source lacks reconciliation, creating a risk of delayed duplicate alarms and disconnected activities. Verify this on a physical device.

**4. Code quality**

The existing SwiftUI/SwiftData structure is adequate for the app's size. Improve ownership and testability through small extractions.

- **Restore the test baseline first.** Fix the unmatched brace, check missing imports, then run the suite and resolve any subsequent failures. Existing UI tests mainly launch the app; they do not protect workout workflows. [PersonalTrainerAppTests.swift:192](/Users/jdai/Documents/APPS/personaltrainerapp/PersonalTrainerApp/PersonalTrainerAppTests/PersonalTrainerAppTests.swift:192).
- **Give persistence operations an explicit success/failure result.** `safeSave()` logs errors but callers still dismiss or trigger success feedback. Keep forms open and offer retry on failure. [SeedHelper.swift:21](/Users/jdai/Documents/APPS/personaltrainerapp/PersonalTrainerApp/PersonalTrainerApp/SeedHelper.swift:21).
- **Centralize initialization, reset, and data upgrades.** Migrations currently run as multiple full-store passes from view appearance. Add migration completion/version tracking and distinguish one-time transformations from integrity checks. Preserve compatibility repairs until tests establish that they can be retired.
- **Replace name-based references with stable identity.** This removes rename/capitalization coupling and supports accurate calendar grouping. Implement an explicit migration for existing stores.
- **Consolidate derived statistics.** Daily grouping and volume calculations are repeated in models, view models, calendar, and analytics. Use a shared, tested calculation layer with an injectable calendar/date; profile before adding caches.
- **Make timer state transitions explicit.** Idle/running/paused/finished states, a controllable clock, and separate notification/activity adapters will make lifecycle tests possible. Request alert permission in context when the user first needs it, and handle denial.

**5. Redundant and unused logic**

These are concrete cleanup candidates, after establishing regression coverage:

| Candidate | Action |
| --- | --- |
| `TimerState.swift` is comment-only. | Remove the obsolete file and its documentation. |
| `TimerWidgetCode.swift` duplicates unused Live Activity UI in the app target. | Remove it after confirming the extension remains the sole implementation. |
| `TimerManager.initialDuration` is assigned but never subsequently read. | Remove the unused stored property. |
| `TimerView.dragOffset` is written but never affects rendering. | Remove it or implement intentional drag feedback. |
| ContentView keeps unused group-add/rename/reorder state. | Remove it or connect it as part of the missing management flow. |
| AddMuscleGroupSheet has no call sites. | Wire it into group management; it represents missing functionality, so deletion alone is not a product fix. |
| ExerciseListView keeps a commented-out old deletion implementation. | Delete obsolete comments/code and retain history in Git. |
| Volume calculations are duplicated. | Consolidate and verify equivalent results. |
| Timer polls ten times per second but exposes integer-second progress. | Use a suitable update schedule or deliberately continuous progress; measure before claiming performance gains. |
| README, CLAUDE.md, and release metadata disagree with the implementation. | Update documentation: TimerState/ZStack guidance is obsolete, README says iOS 17 while the target is 18.5, and build marketing version remains 1.0 despite v1.6.0 release notes. |

Do not remove the explicit relationship insertion/removal safeguards simply because they look repetitive. The project records prior SwiftData bugs that motivated them; first test the actual persistence behavior.

**Recommended implementation sequence**

| Phase | Work | Completion criteria |
| --- | --- | --- |
| 1 — Protect records and restore validation | Repair the test target; prevent invalid weight configurations and selections; stop orphan-producing cleanup; return save failures; remove exposed template widgets. | App builds and tests run. Zero/tiny steps and invalid ranges cannot crash or create invalid sets. Logging, reopening, and deleting preserve expected stored-record counts. |
| 2 — Complete existing functions | Fix group identity migration, initialization/reset, calendar alignment, historical cardio editing, group management, and timer setting propagation/ownership. | Reset restores guide associations; legacy names retain exercises; Sunday/Monday calendars agree; historical entries are editable; timer changes and rapid pause/resume behave predictably. |
| 3 — Improve the workout loop | Put logging first; provide compact rest controls; expose repeat/edit/undo; clarify quick logging and exercise ordering; separate progress and instructions. | A user can select, log, start rest, repeat, and correct an entry without hidden actions or unnecessary navigation. |
| 4 — Finish UI and maintenance | Adaptive layouts, accessibility semantics, chart labeling, light/dark checks, dead-code removal, shared calculations, updated docs/version metadata, automated build/test checks. | Key workflows pass on compact/large screens and large text; VoiceOver can operate them; device timer checks pass; unused templates and obsolete guidance are gone. |

Keep each phase reviewable in small changes. Defer new platforms, social features, cloud sync, and a major visual redesign until the current logging and history workflows are reliable.
