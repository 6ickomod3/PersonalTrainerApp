# Changelog

All notable changes to Personal Trainer App will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.4.1] - 2025-12-15

### Added
- **Enhanced Calendar Log Display**: Daily logs in the calendar now display the Muscle Group alongside the Exercise Name (e.g., "Core - Ab Crunch") for better context and clarity.


## [1.4.0] - 2025-12-15

### Major Release - UI Refinement & Polish :sparkles:

This release focuses on refining the visual consistency of the application and simplifying the user interaction model. It introduces a coherent list design for exercises, warm-ups, and cool-downs, and streamlines the home screen for a cleaner look.

### Added
- **Visual Coherence in Exercise List**
  - **Checkmark Indicator**: Exercises now feature a read-only checkmark that turns green when you log a set for the day, matching the visual style of Warm-up and Cool-down items.
  - **Target Volume Subtitle**: Added a second line of text referencing "Target Volume" to `ExerciseRow`, ensuring all list items share the same height and alignment.
- **Context Menus**: Replaced long-press Edit Mode with native Context Menus for "Rename" and "Delete" actions in the Exercise List.

### Changed
- **Home Screen Simplification**:
  - Removed decorative background icons from Muscle Group cards for a cleaner, less cluttered aesthetic.
  - Reduced Muscle Group card height from 100 to 70 for a more compact grid.
- **Interaction Model**: Removed the global "Edit Mode" triggered by long-press in the Exercise List to prevent jarring UI shifts.
- **Typography**: Enforced Title Case for all new Muscle Groups and Exercises to ensure consistent presentation.

### Technical Details
- **Logic Refactor**: Moved `suggestedVolume` and `todaysVolume` calculation logic from `ExerciseDetailViewModel` to the `Exercise` model to support reuse in the list view.
- **Performance**: Broke down `ExerciseListView` body into smaller `@ViewBuilder` properties to resolve compiler timeout errors.

---
## [1.3.0] - 2025-12-07

### Major Release - Customizable Workout Guides 🛠️

This release unlocks the full potential of Workout Guides by making them completely dynamic. You can now reorder, add, remove, and create custom warm-ups and cool-downs for every muscle group, giving you total control over your workout flow.

### Added
- **Dynamic Guide Management**
  - **Reorder & Organizing**: Drag-and-drop support for Warm-up and Cool-down items.
  - **Global Pools**: Select from a master list of guide items to add to any muscle group.
  - **Custom Items**: improved creation flow for custom warm-ups or stretches with personalized instructions and duration.

- **Enhanced Editing Experience**
  - **Manage Mode**: Dedicated "Manage" view for guide sections to prevent accidental edits.
  - **Smart Seeding**: Automatically preserves your existing hardcoded guides while migrating them to the new dynamic system.

### Visual Design Updates 🎨
- **Workout Phase Coloring**: Distinct color themes for each workout phase to signify intensity:
  - 🟧 **Warm-Up**: Energizing Orange tint.
  - 🟥 **Exercises**: High-intensity Red tint.
  - 🟦 **Cool-Down**: Calming Blue tint.
- **Unified Interface**: Consistent "Edit" buttons and capsule styling across all sections for a premium look and feel.

### Technical Details
- **SwiftData Architecture**: Introduced `GuideItem` and `MuscleGroupGuide` models for robust many-to-many relationships.
- **Performance Optimization**: Refactored `ExerciseListView` using `@ViewBuilder` to significantly reduce compiler type-checking time.
- **Seeding Logic**: Intelligent data migration strategy to populate initial databases without duplication.

---

## [1.2.0] - 2025-12-15
### Major Release - The Complete Dashboard ⭐️

This release introduces a completely redesigned Home Screen with a unified dashboard, bringing together Calendar tracking, Cardio logging, and a modernized Strength training interface. It also transforms the Exercise Detail view into a comprehensive workout guide with warm-ups and cool-downs.

### Added
- **Unified Dashboard**
  - **Dynamic Greetings**: Welcomes you with the date and a motivational message ("Let's crush it, Ji!").
  - **Training Calendar**: Monthly view with color-coded dots (Red for Strength, Blue for Cardio) to track activity at a glance.
  - **3-Section Layout**: seamlessly integrates Strength, Cardio, and Calendar in one scrollable view.

- **Cardio Tracking**
  - **New Log Type**: Track Run, Cycle, Walk, Swim, HIIT, and more.
  - **Smart Filtering**: Dashboard only displays today's cardio logs to keep the view focused.
  - **Quick Add**: dedicated "+" button for fast cardio entry.

- **Comprehensive Muscle Guide**
  - **3-Phase Workout Flow**: Muscle detail pages now include **Warm Up**, **Exercises**, and **Cool Down** sections.
  - **Vertical List Layout**: Consistent, clean list design for all sections.
  - **Guide Instructions**: Tap any warm-up or stretch to see detailed "How-to" instructions.
  - **Smart Daily Reset**: Checkboxes for guide items persist for the day and auto-reset tomorrow.

- **Settings & Data Safety**
  - **Danger Zone**: "Reset All Data" moved to Settings to prevent accidents, protected by a confirmation alert.
  - **Timer Defaults**: Rest timer now starts collapsed by default to maximize screen real estate.

### Changed
- **Home Screen Redesign**
  - Replaced simple list with a modern Grid Layout for Muscle Groups.
  - Removed "Add Muscle Group" button from main toolbar for a cleaner look.
- **Visual Extensions**
  - Timer view now functions as a full-width bottom sheet with improved safe area handling.
  - Muscle Group cards feature primary text color for better readability in Light Mode.
  - **Unified List Styling**: "Exercises" list now matches the Card-style visual design of Warm-up and Cool-down sections.
  - **Color Hierarchy**: 
    - Strength Cards use **Red** text to match the header.
    - Warm-up items use **Orange** text.
    - Cool-down items use **Blue** text.
    - Exercise items use **Black** (.primary) text.

### Fixed
- **Alignment**: Fixed indentation inconsistency in the Exercise list to align perfectly with other guide items.
- **Link Styling**: Removed default blue tint from Navigation Links in the exercise list.

### Technical Details
- Implemented `CardioLog` SwiftData model.
- Created `GuideRow` and `GuideDetailView` components.
- Added `UserDefaults` persistence logic for daily reset of Guide items.
- Refactored `ContentView` into modular sub-views (`StrengthTrainingView`, `CardioSectionView`, `CalendarSectionView`).

---

## [1.1.0] - 2025-11-30

### Major Update - Refinement & Polish 💎

This release focuses on refining the user experience with a native edit mode, improved navigation flows, and a significant rebranding to **Sigma Training**. It also introduces Live Activities for the timer and critical bug fixes.

### Added
- **Native Edit Mode**
  - Unified "Edit" button in the top-right corner
  - Consolidated Add, Delete, Rename, and Reorder actions
  - Clean UI with dedicated controls for each action
  - Removed swipe actions to prevent accidental deletions
  - Safe and intuitive list management

- **Live Activities & Lock Screen Timer**
  - Track rest intervals directly from the Lock Screen
  - Dynamic Island support for iPhone 14 Pro/15 Pro
  - Real-time countdown updates while app is in background
  - Interactive widget for instant status checks

- **Timer Alarm**
  - Audio feedback when timer completes
  - Works in background with local notifications
  - "Calypso" sound alert for gentle notification

- **Enhanced Add Exercise Flow**
  - New input fields for Weight Range (Min, Max, Step)
  - New input for Volume Improvement Goal (%)
  - Auto-navigation to the newly created exercise
  - Streamlined creation process

### Changed
- **Rebranding**
  - App renamed to **Sigma Training**
  - Updated display name on Home Screen

- **UI/UX Improvements**
  - Moved Menu button (⋯) to top-left for better reachability
  - Consolidated Edit and Add buttons in top-right
  - Side-by-side picker layout in Exercise Detail for compact logging
  - "Log a set" section redesigned for better usability

### Fixed
- **Critical Data Safety**
  - Fixed data corruption when renaming Muscle Groups (cascading updates)
  - Fixed issue where deleting one set deleted all sets for the day
  - Fixed validation errors during deletion
  - Implemented bidirectional relationships in SwiftData models

### Technical Details
- Refactored `ExerciseDetailView` to MVVM architecture
- Implemented `TimerWidget` extension for Live Activities
- Optimized build performance and reduced closure complexity

---

## [1.0.0] - 2025-11-30

### Major Release - Production Ready ✨

This release marks the official v1.0 stable version with comprehensive fitness tracking features, professional UI design, and configurable training goals.

### Added
- **Customizable Volume Improvement Goals**
  - Per-exercise improvement percentage (default 3%)
  - Configure target progression for each exercise
  - Suggested volume calculated based on custom goals
  - Reset to defaults option in exercise settings

- **Smart Suggested Volume System**
  - Based on most recent previous workout (excludes today's data)
  - Uses custom improvement percentage per exercise
  - Shows dynamic improvement % in Training Progress section
  - Helps users set realistic daily targets

- **Professional App Icon**
  - Custom app icon with auto-generated sizes
  - Displays on home screen and in app switcher
  - High-quality 1024×1024 base image

### Enhanced
- Volume tracking now excludes today's data for unbiased suggestions
- Training Progress section dynamically shows custom improvement %
- Exercise settings reorganized with "Training Volume Goals" section

### Technical Details
- Schema migration for `volumeImprovementPercent` property
- Improved date filtering logic for baseline calculations
- Enhanced settings UI with better organization

---

## [0.4.0] - 2025-11-29

### Added
- **Per-Exercise Customization**
  - Customize weight range (min, max, step) for individual exercises
  - Access settings via gear icon on exercise detail view
  - Weight picker automatically uses exercise-specific settings
  - Independent weight configurations for each exercise

- **Volume Tracking & Analytics**
  - Automatic volume calculation for each set (reps × weight)
  - Daily aggregated history view with total daily volume
  - Volume displayed prominently in blue for quick overview
  - Individual set breakdown showing: reps × weight = volume

- **Intelligent History View**
  - Daily containers grouped by date
  - Shows date, set count per day, and total daily volume
  - Chronological ordering with most recent days first
  - Clean visual hierarchy with exercise context

- **Configurable Data Storage**
  - User-customizable data retention (1-30 days)
  - Automatic cleanup of old workout logs based on setting
  - Default: keep last 4 days of data
  - Smart cleanup removes only data older than configured days

- **Simplified Settings**
  - Focused app settings with only essential configuration
  - Single storage setting instead of multiple unused options
  - Reset to defaults button for one-click restoration

### Improved
- App Settings model refactored to minimal core properties
- SettingsSheet streamlined for better UX
- Automatic cleanup runs when opening exercise detail view
- Empty daily containers auto-remove when last set is deleted
- Better memory management with intelligent data retention

### Technical Details
- Volume as computed property (reps × weight) for automatic calculation
- Daily aggregation via computed `setsByDate` property
- Automatic cleanup triggered on view appearance
- Enhanced ModelContainer configuration with all required models
- Improved data consistency with schema validation

---

## [0.3.0] - 2025-11-29

### Added
- **Rest Timer Feature**
  - Built-in 1-minute countdown timer fixed at bottom of app
  - Adjustable duration with ±15 second buttons
  - Smart reset function remembers user-adjusted duration
  - Start/Pause toggle for flexible workout breaks
  
- **Collapsible Timer UI**
  - Expanded view with full controls and timer display
  - Minimized view showing only time (tap to expand)
  - Drag-down gesture (50+ points) to collapse
  - Smooth 0.3-second animations for state transitions
  - Centered time display in minimized state

- **Haptic Feedback System**
  - 3-second continuous vibration pattern when timer ends
  - 15 haptic pulses at 0.2-second intervals for noticeable alert
  - Medium impact strength for gym-friendly feedback
  - Works in silent mode without audio alerts

### Improved
- Timer display uses system default font family matching app styling
- Button fonts standardized across timer and app (system .body font)
- Clean white card design with rounded corners matching exercise cards
- Double bottom padding (24pt) to avoid phone rounded bottom edge
- Better visual hierarchy with chevron indicators for collapse/expand
- Larger 50x50pt touch target on expand button for easy control

### Technical Details
- `TimerManager` class with Observable pattern for state management
- DragGesture implementation for collapse/expand functionality
- UIImpactFeedbackGenerator for haptic feedback pattern
- Computed `formattedTime` property for MM:SS display
- Efficient timer cleanup with deinit pattern
- Smooth state transitions with SwiftUI animations

---

## Core Features (All Versions)

### Muscle Group Organization
- 5 pre-loaded default muscle groups (Chest, Back, Leg, Shoulder, Arm)
- Create custom muscle groups dynamically
- Drag-to-reorder muscle groups with Edit mode
- Delete muscle groups with swipe-to-delete
- Organized exercise viewing by muscle group

### Exercise Management
- 10 sample exercises across all muscle groups
- Create custom exercises with personalized settings
- Per-exercise weight customization (min, max, step)
- Per-exercise volume improvement goals
- Drag-to-reorder exercises within muscle groups
- Delete exercises with swipe-to-delete
- Access exercise settings via gear icon

### Workout Logging & History
- Log individual workout sets with reps and weight
- Intuitive wheel picker interface for data entry
- Automatic timestamp recording for each set
- View complete workout history organized by date
- Daily aggregated history with total volume per day
- Delete previous sets to correct mistakes
- Automatic data cleanup (1-30 days configurable)

### Volume Tracking & Analytics
- Automatic volume calculation for each set (reps × weight)
- Daily aggregated volume totals
- Previous workout volume reference
- Customizable suggested volume based on improvement goals
- Visual progress tracking with blue accent colors

### Rest Timer
- Built-in countdown timer (default 1:30, customizable)
- Start/Pause/Reset controls
- Adjustable ±15 seconds for flexibility
- Collapsible/Minimizable UI with drag gesture
- 3-second haptic feedback when complete
- Modern glass morphism design

### Settings & Customization
- Per-exercise weight range and step size
- Per-exercise volume improvement percentage
- Global timer duration configuration
- Data retention settings (1-30 days)
- One-tap reset to defaults

### Technical Foundation
- Built with **SwiftUI** and **SwiftData**
- MVVM-inspired reactive architecture
- Automatic data persistence and migration
- iOS 17+ compatible
- No external dependencies

---

## [Unreleased]

### Planned Features
- Workout progress analytics and charts
- Personal records (PR) tracking
- Workout templates and routines
- Training splits and schedules
- Apple Watch companion app
- Exercise notes and form tips
- Workout statistics dashboard
- Dark mode support
- Export workouts to CSV/PDF
- Cloud synchronization (iCloud)

---

## [0.4.0] - 2025-11-29

### Added
- **Glass Morphism Timer Design**
  - Modern frosted glass aesthetic matching iOS 15+ design language
  - Unified glass container for timer header and countdown
  - Semi-transparent white overlay with blur effect
  - Consistent visual cohesion between all components

- **Dynamic Scroll Endpoints**
  - Automatic timer height detection using GeometryReader
  - Scroll endpoints adapt to expanded/collapsed timer states
  - Works seamlessly across ContentView and ExerciseDetailView
  - Eliminates hardcoded values for future-proof design

- **Configurable Timer Duration**
  - Default timer duration changed from 1:00 to 1:30 (90 seconds)
  - User-editable timer duration in App Settings
  - Helpful guide showing common values (60, 90, 120 seconds)
  - Reset to defaults button includes timer reset

- **Enhanced Navigation Labels**
  - Main screen title updated from "Workout" to "Target Muscle Group"
  - Better describes primary navigation purpose

### Improved
- Timer container now spans full width aligned with Form sections
- Header and countdown box unified in single glass container
- No more text bleed-through from background content
- Better visual separation and professional appearance
- Responsive height measurements for all screen sizes

### Technical Details
- `TimerState` observable class with dynamic height tracking
- `VisualEffectBlur` UIViewRepresentable for native iOS blur effects
- `systemThickMaterial` blur style for enhanced opacity
- `TimerManager` init accepts configurable duration parameter
- `AppSettings` model includes `defaultTimerDuration` property
- GeometryReader background for automatic size measurement
- Form-aligned padding matching native iOS design patterns
