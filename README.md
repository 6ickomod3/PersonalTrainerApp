# Sigma Training
(Formerly Personal Trainer App)

A comprehensive iOS fitness companion for tracking workouts, managing exercises, and organizing your training routine by muscle group.

## Features

- 📋 **unified Dashboard** - All-in-one view with Strength, Cardio, and Calendar tracking
- 💪 **comprehensive Guides** - Workouts now include Warm-up and Cool-down sections with detailed instructions
- 🏃 **Cardio Logging** - Track runs, cycles, and more with daily filtering
- 📅 **Activity Calendar** - Visual monthly history with color-coded workout dots
- 🗑️ **Smart Data Management** - Configurable data retention (1-30 days) with automatic cleanup
- ⏱️ **Rest Timer & Live Activities** - Built-in countdown timer with Lock Screen support, Dynamic Island integration, and background alarms
- ✏️ **Native Edit Mode** - Safe and intuitive management for adding, deleting, renaming, and reordering items
- 🎨 **Glass Morphism Design** - Modern frosted glass aesthetic for timer matching iOS 15+ design language
- 💾 **Data Persistence** - Reliable local storage using SwiftData
- 🔄 **Smart Migrations** - Automatic data handling for app updates
- 📱 **Professional App Icon** - Custom icon with auto-generated sizes for all devices

## Getting Started

### Requirements
- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

### Installation

1. Clone the repository:
```bash
git clone https://github.com/6ickomod3/PersonalTrainerApp.git
cd PersonalTrainerApp
```

2. Open in Xcode:
```bash
open PersonalTrainerApp.xcodeproj
```

3. Build and run on simulator or device:
   - Select target device
   - Press Cmd+R or click Run

## Usage

### Main Screen
- View all muscle groups
- Tap to explore exercises in each group
- Swipe left to delete muscle groups
- Use menu (⋯) to add new groups or reset data

### Exercise List
- View exercises for selected muscle group
- Tap to log workouts
- Tap + to add new exercises
- Swipe left to delete exercises

### Logging a Workout
1. Select an exercise
2. Use wheel pickers to set reps and weight
3. Tap "Add Set" to log
4. View your workout history organized by day below
5. See volume calculated for each set (reps × weight)
6. View daily totals and total daily volume
7. Swipe left on sets to delete if needed

### Exercise Settings
1. Open any exercise detail view
2. Tap the gear icon (⚙️) in the top right
3. Customize weight range (min, max, step) for that exercise
4. Tap "Done" to save - settings persist automatically

### App Settings
1. Tap the menu (⋯) on the main screen
2. Select "Settings"
3. Configure data retention (1-30 days)
4. Older workout logs automatically delete to manage storage

### Rest Timer
1. Timer appears at the bottom of the screen (always visible)
2. Default countdown is 1:30 (90 seconds) - configurable in settings
3. Adjust time:
   - Tap **–15s** to decrease by 15 seconds
   - Tap **+15s** to increase by 15 seconds
   - Adjusted time is remembered on reset
4. Control timer:
   - Tap **Start** to begin countdown
   - Tap **Pause** to pause the timer
   - Tap **Reset** to return to your set duration (or 1:30 default)
5. Collapse/Expand:
   - Drag timer down 50+ points to minimize (shows only time)
   - Tap minimized timer or drag up to expand again
   - Haptic feedback (vibration) triggers when timer reaches 0:00
6. Configure timer duration:
   - Tap the menu (⋯) on the main screen
   - Select "Settings"
   - Update "Default Duration (seconds)" field
   - Common values: 60 (1:00), 90 (1:30), 120 (2:00)
   - Tap "Done" to save

## Default Content

### Muscle Groups
- Chest
- Back
- Leg
- Shoulder
- Arm

### Sample Exercises
- **Chest:** Bench Press, Push Up
- **Back:** Pull Up, Deadlift
- **Leg:** Squat, Lunge
- **Shoulder:** Overhead Press, Lateral Raise
- **Arm:** Bicep Curl, Tricep Extension

## Architecture

### Technology Stack
- **UI Framework:** SwiftUI
- **Data Storage:** SwiftData
- **Architecture:** MVVM-inspired reactive design

### Data Models
- `MuscleGroup` - Exercise categorization
- `Exercise` - Workout exercise with metadata
- `WorkoutSet` - Individual set logging with timestamps

## Changelog

See [CHANGELOG.md](./CHANGELOG.md) for detailed version history and upcoming features.

**Current Version:** v1.2.0 (December 7, 2025) - The Complete Dashboard Update ⭐️

## Future Roadmap

- 📊 Progress analytics and visualizations
- 🏆 Personal records (PR) tracking
- 📅 Workout routines and templates
- ⌚ Apple Watch companion app
- 📝 Exercise notes and form tips
- 📱 Dark mode support

## License

MIT License - See LICENSE file for details

## Author

Ji Dai (@6ickomod3)

## Support

For issues, feature requests, or feedback, please open an issue on GitHub.

---

**Made with ❤️ for fitness enthusiasts**
