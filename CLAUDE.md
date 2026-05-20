# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

"Sigma Training" (target name `PersonalTrainerApp`) — an iOS 18.5+ SwiftUI fitness app using SwiftData for persistence. The Xcode project also ships a Live Activity widget extension target.

## Build & Test

Open the workspace with `open PersonalTrainerApp.xcodeproj`. From the command line:

```bash
# List schemes / targets
xcodebuild -list -project PersonalTrainerApp.xcodeproj

# Build the app for the simulator
xcodebuild -project PersonalTrainerApp.xcodeproj \
  -scheme PersonalTrainerApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run unit tests (Swift Testing framework — `import Testing`, `@Test`)
xcodebuild -project PersonalTrainerApp.xcodeproj \
  -scheme PersonalTrainerApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' test

# Run a single test by name
xcodebuild test -project PersonalTrainerApp.xcodeproj \
  -scheme PersonalTrainerApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:PersonalTrainerAppTests/testDeleteSet
```

There are two schemes: `PersonalTrainerApp` (main app + tests) and `PersonalTrainerAppRestTimerWidgetExtension` (Live Activity widget). Targets: `PersonalTrainerApp`, `PersonalTrainerAppTests`, `PersonalTrainerAppUITests`, `PersonalTrainerAppRestTimerWidgetExtension`.

## Architecture

### SwiftData schema and container

The full model schema is registered in **one place**: `PersonalTrainerAppApp.swift` in the `.modelContainer(for:)` call. When adding a new `@Model` class, it MUST be added to that array or queries will fail at runtime. Current models:

- `MuscleGroup` (in `Models.swift`) — groups exercises; cascade-owns `MuscleGroupGuide` join records.
- `GuideItem` (in `Models.swift`) — a warmup or cooldown drill. Stored once and **reused across muscle groups** via the join model below ("Global Pool" pattern, see `ContentView.seedGuides`).
- `MuscleGroupGuide` (in `Models.swift`) — join entity with `displayOrder` and `category` linking a `MuscleGroup` to a `GuideItem`. `category` and `GuideItem.type` are stored as raw `String`; use the `GuideCategory` / `GuideType` enums when reading/writing them.
- `Exercise` (in `Models.swift`) — links to muscle group **by name string** (`muscleGroupName`), not by relationship. Cascade-owns its `WorkoutSet`s.
- `WorkoutSet` (in `Models.swift`) — has back-reference `exercise: Exercise?`; computed `volume = reps × weight`.
- `CardioLog` (in `Models.swift`) — standalone, not linked to muscle groups.
- `AppSettings` (in `AppSettings.swift`) — singleton (one row); stores `maxStorageDays` and `defaultTimerDuration`. Read with `@Query` and create one if missing (see `ContentView.onAppear`).

### Seeding & migrations on first launch

`ContentView.onAppear` runs three idempotent steps in order: `DataMigration.performMigrations`, then `SeedHelper.seedMuscleGroups` / `seedExercises` if empty, then `seedGuides()`. **All schema/data changes that need to handle existing user data must be added to `DataMigration.performMigrations`** — that struct already deduplicates set references, regenerates duplicate `WorkoutSet.id`s, backfills nil dates, infers missing `muscleGroupName` from the exercise name, and Title-Cases names. Read these existing migrations before changing model defaults; they exist because users already have stores in the field.

Use the `ModelContext.safeSave()` extension (defined in `SeedHelper.swift`) instead of `try? context.save()` so failures are logged with file+line.

### View composition

`ContentView` is a single-screen dashboard wrapping `NavigationStack` with three scrolling sections (`StrengthTrainingView`, `CardioSectionView`, `CalendarSectionView`) and a `TimerView` pinned at the bottom via a `ZStack`. Navigation pushes `ExerciseListView` (for a `MuscleGroup`) and `ExerciseDetailView` (for an `Exercise`) using value-based `navigationDestination(for:)`.

`ExerciseDetailViewModel` is `@Observable` and owns form state plus computed groupings (`setsByDate`, `lastTrainingVolume`, `suggestedVolume`). When adding a set it both appends to the relationship array AND calls `modelContext.insert(...)`; deleting calls `modelContext.delete(...)` AND removes from the array. Both steps are required — keep this pattern, the comments in `addSet` / `deleteSet` flag a SwiftData validation bug that motivated it.

### Timer + Live Activity

Two distinct objects, do not conflate:

- **`TimerState`** (`TimerState.swift`, `@Observable`) — UI-only state for the floating timer (expanded vs. collapsed, height for spacer math). Injected via `.environment(timerState)` so any view that needs to reserve scroll-space below the timer reads `timerState.spacerHeight`.
- **`TimerManager`** (`TimerManager.swift`, `@Observable`) — countdown engine. Drives a 0.1s `Timer`, an ActivityKit `Activity<TimerAttributes>` (Lock Screen + Dynamic Island via the widget extension), and a `UNCalendarNotificationTrigger` so the alarm still fires when backgrounded. `TimerAttributes` is shared with the widget extension target.

When the timer's user-set duration changes (via `addTime`), all three must stay in sync: `secondsRemaining`, `userSetDuration`, the activity's content state, and the rescheduled notification. Look at `addTime` for the canonical pattern.

### Theming

`Theme.swift` defines the design system (earthy palette, gradients, corner radii, spacing tokens, materials). The app-wide tint is applied once in `PersonalTrainerAppApp.swift` via `.tint(Theme.accent)`. Use `Theme.*` tokens and the `.themeCard()` view modifier for new surfaces rather than inlining colors or radii.
