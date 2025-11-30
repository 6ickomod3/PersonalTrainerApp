# Changelog

All notable changes to Personal Trainer App will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-11-29

### Added
- **Muscle Group Management**
  - 5 pre-loaded default muscle groups (Chest, Back, Leg, Shoulder, Arm)
  - Create custom muscle groups dynamically
  - Delete muscle groups with swipe-to-delete
  - Organized exercise viewing by muscle group

- **Exercise Library**
  - 10 sample exercises across all muscle groups
  - Create custom exercises with personalized settings
  - Set default reps (0-50) and weight (0-200 lbs) per exercise
  - Delete exercises with swipe-to-delete

- **Workout Logging**
  - Log individual workout sets with reps and weight
  - Intuitive wheel picker interface for data entry
  - Automatic timestamp recording for each set
  - View complete workout history sorted by date/time
  - Delete previous sets to correct mistakes

- **Data Management**
  - Persistent local storage using SwiftData
  - Automatic default data seeding on first launch
  - Smart data migration for future updates
  - One-tap data reset to restore defaults

- **User Interface**
  - Clean, hierarchical navigation
  - Modal sheets for adding muscle groups and exercises
  - Responsive SwiftUI design
  - Professional visual layout

### Technical Details
- Built with **SwiftUI** and **SwiftData**
- MVVM-inspired architecture
- Automatic data persistence
- Schema migration support
- iOS 17+ compatible

---

## [0.2.0] - 2025-11-29

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

## [Unreleased]

### Planned Features
- Workout progress analytics and charts
- Personal records (PR) tracking
- Workout templates and routines
- Training splits and schedules
- Apple Watch companion app
- Exercise notes and form tips
- Workout statistics dashboard

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
