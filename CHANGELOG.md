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

## [Unreleased]

### Planned Features
- Workout progress analytics and charts
- Personal records (PR) tracking
- Workout templates and routines
- Training splits and schedules
- Apple Watch companion app
- Exercise notes and form tips
- Workout statistics dashboard
