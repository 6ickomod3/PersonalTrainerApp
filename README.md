# Sigma Training

An iOS strength-training log built with SwiftUI and SwiftData.

## Version 1.7.0 — Strength focus

- **Train:** continue your last exercise, browse muscle groups, and add, rename, or reorder groups and exercises.
- **Log sets:** choose reps and weight, repeat a previous set, edit a record, delete a set, or undo the last addition.
- **History:** a strength-only calendar with editable daily records and dated progress charts.
- **Rest timer:** a separate compact row across both tabs, with Start/Pause and adjustments that expand by tapping the empty area or arrow. Content resizes above it. Includes the existing Lock Screen/Dynamic Island Live Activity.
- **Instructions:** exercise notes and video links have their own screen.
- **Keep history:** opening an exercise no longer prunes or disconnects older sets.

Warm-up, cool-down, and cardio screens are temporarily removed pending redesign. Their existing records remain saved on the device. New installations no longer seed guides. The calendar only reports strength training days.

## Existing data

The app retains the original seven SwiftData model types, persisted fields, relationships, app identifier, and store location. No store reset is required for this update. Existing cardio, guides, guide associations, and guide completion preferences remain intact during normal use and upgrades. The old retention setting is preserved in storage but no longer deletes workouts.

Invalid legacy weight ranges receive safe temporary picker choices until corrected in Exercise Settings; historical values remain unchanged. Missing group-name references are repaired only when there is one unambiguous case/whitespace match. Unassigned historical sets remain visible in History without guessing their exercise.

Settings → Erase All App Data deliberately removes **all** records, including retained cardio and guides, and restores default strength exercises. Settings → Reset settings changes only the settings draft until Save is tapped.

## Build and test

Requires iOS 18.5+ and Xcode 16.4+.

Open `PersonalTrainerApp.xcodeproj`, select the `PersonalTrainerApp` scheme and an iPhone simulator, then run.

```sh
xcodebuild -project PersonalTrainerApp.xcodeproj \
  -scheme PersonalTrainerApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' test
```

Unit tests exercise numeric validation, actual logging/edit/delete/undo operations, complete retained-data reopen checks, initialization/reset, calendar locales, and deterministic timer transitions. UI tests cover Train/History navigation, logging/correction, group creation, and timer settings/shared state. Debug UI tests use `--ui-testing` for an isolated in-memory store and disable external timer effects.

Run `./TestsSupport/LegacyCompatibility/verify.sh` on macOS to build a real SQLite store using the old Git model source and verify that the current app code preserves it through preparation, saving, and reopening. See [the compatibility check](TestsSupport/LegacyCompatibility/README.md) for fixture contents and requirements.

Notification delivery and Live Activities during real-device suspension/termination still need device validation. The countdown is not restored after the app process is terminated.

See [PROJECT_REVIEW.md](PROJECT_REVIEW.md) for the original audit and implementation direction, and [CHANGELOG.md](CHANGELOG.md) for release history.
