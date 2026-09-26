# Project guidance

Sigma Training is an iOS 18.5+ SwiftUI/SwiftData strength-training app. Use Xcode 16.4+ and the `PersonalTrainerApp` scheme. The widget extension contains only the rest-timer Live Activity.

## Build and test

```sh
xcodebuild -project PersonalTrainerApp.xcodeproj -scheme PersonalTrainerApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' test
```

Unit tests use Swift Testing; UI tests use XCTest. Debug UI tests launch with `--ui-testing`, which selects an in-memory store and disables external timer effects.

## Compatibility boundary

`PersonalTrainerAppApp.swift` registers seven model types: Exercise, MuscleGroup, WorkoutSet, AppSettings, CardioLog, GuideItem, and MuscleGroupGuide. Keep all seven types, their persisted properties/defaults, and their relationships compatible with existing stores. Warm-up, cool-down, and cardio UI was retired in 1.7; their data models remain intentionally. Do not remove or rename these models as dead code.

Exercise still refers to its group by name. Group renames must update exercises in the same save, preserve guide relationships and completion preferences, and reject ambiguous/duplicate names. A later stable-ID redesign requires a separately tested schema migration.

## Data lifecycle

`TrainingStore.prepare(context:)` seeds strength content only for a truly new store. An existing AppSettings row preserves intentionally empty stores. No guides are seeded. `DataMigration.performMigrations` repairs uniquely matched missing group-name links, duplicate references/invalid duplicate set IDs, and missing inverses with unique relationship evidence, then refreshes last-log caches. Do not guess orphan ownership, capitalize user names, reset stores, or prune workout history at startup.

`TrainingStore.resetAll` is the explicit full-erase operation, including retained feature data and guide preference keys. Normal settings changes must not call it.

Use draft form state. Call `try modelContext.save()` and show errors; roll back failed operations. Only show success or dismiss an editor after a successful save. Preserve explicit set relationship changes and context insert/delete operations until regression tests prove an alternative safe.

`WeightConfiguration` bounds picker arrays and validates numeric settings. Invalid legacy settings get safe fallback choices without altering the stored configuration or old sets. Historical editing permits finite nonnegative weights outside the current picker range.

## UI

ContentView owns Train and History navigation paths and one TimerManager. Each tab lays out its navigation stack above a separate TimerView row, so scrolling content cannot extend behind the timer. The timer's empty area and arrow toggle inline adjustments; timer action buttons do not toggle expansion. Reset clears both navigation paths.

Train shows continue-training and managed muscle groups. ExerciseListView uses stable user ordering and search. ExerciseDetailView prioritizes set entry and today’s sets, with repeat/edit/delete/undo. Progress and Instructions are separate destinations. History displays only WorkoutSet records, grouping by exercise identity and preserving unassigned sets.

Use Theme tokens, semantic buttons, accessible labels, and layouts that expand at larger text sizes.

## Timer

TimerManager is main-actor isolated with an injectable clock and external-effects switch for tests. Keep notification scheduling independent of Live Activity authorization. Clear the old activity handle before awaiting its end. Changing settings updates idle timers immediately and active/paused timers for their next reset/rest. Scene activation reconciles the deadline without replaying a late alarm. The process-termination/relaunch case does not currently restore a timer.
