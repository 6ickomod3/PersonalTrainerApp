# Old-store compatibility check

Run from the repository on macOS 14 or later with Xcode selected:

```sh
./TestsSupport/LegacyCompatibility/verify.sh
```

The script compiles the actual model declarations from baseline commit
`043069d6d81733989fb4437c4463d8cda852ce89`, writes a temporary SQLite store, then
compiles the current production models and store preparation code using the same
module name. The current reader prepares, saves and reopens that store twice.

The fixture includes all seven persisted model types: custom muscle group and
exercise, ten days of strength sets, an orphan set, custom warm-up and cool-down
guides with ordering and group relationships, cardio with distance/calories, and
nondefault settings. It also includes a zero weight increment from the old app.
Every persisted scalar field, ID and relationship is compared against the original
snapshot. Only an explicit reset should erase this retained data.

The test never opens the app's real database. Its temporary sources, executables,
SQLite files and snapshots are removed at exit. Set
`KEEP_COMPATIBILITY_FIXTURE=1` to retain that temporary directory for diagnosis.
The baseline commit must be present in the local Git history.

The app's unit tests separately cover safe repair of capitalization mismatches,
intentional empty stores, initialization, reset, picker validation and logging.
