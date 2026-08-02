# Sigma Training v1.6.0 - Polish & Personalization 🎨

**Release Date:** May 20, 2026
**Status:** Production Ready ✅

---

## 🎉 What's New in v1.6.0

This release is a deep visual refresh and a personalization upgrade — the dashboard greets you by name with a fresh phrase every day, the rest timer gained a real progress ring with a clear primary action, and the entire color system was restructured so every section reads as distinct. Every change is additive on the data side, so your existing logs, settings, and history come along untouched.

---

## ✨ Headline Features

### Personalized, Time-Aware Greeting
- Set your name once in **Settings → Profile**.
- The dashboard now greets you with one of 24 phrases that rotate by **time of day** (morning / afternoon / evening / late-night) and **day of the year**.
- Example transitions across a single day:
  - Morning → *"Rise and grind, Ji ☀️"*
  - Afternoon → *"Crushing it, Ji? 💪"*
  - Evening → *"End the day strong, Ji!"*
  - Late night → *"Late-night grind, Ji 🌙"*
- Leave the name blank and the phrase still works — just without the personal touch.

### Richer Muscle Group Cards
- Every group card now shows an **SF Symbol** (chest, back, leg, shoulder, arm, …) so you can scan the grid by shape, not just text.
- A small **"N exercises"** chip in the brand accent makes the catalog size visible at a glance.
- A **"Trained today / yesterday / Nd ago / Nw ago / 1mo+ ago"** subline tells you which groups have been neglected without opening anything.

### Rest Timer Visual Upgrade 🟦
- **Circular progress ring** around the countdown — see remaining time at a glance, no arithmetic needed.
- **Primary-action hierarchy** — Start/Pause is now a filled accent capsule; Reset and ±15s are tinted text only. Your eye knows where to go.
- **Haptic feedback on Start/Pause** — every toggle confirms with a `.success` haptic.
- **Tappable chevron** in the expanded header (drag-down still works too).
- **Minimized progress strip** — a thin slate-blue bar at the top edge shrinks as the countdown runs, so you can still see progress without expanding.
- Countdown digits and ring share the same color for a more cohesive feel.

### Color System Overhaul
The palette was restructured into two clear tiers:

**Categorical** (one per workout domain):
- Strength → terracotta
- Cardio → **deeper forest green** (was olive sage)
- Warm-up → **golden saffron** (was amber clay — no longer blurs with strength)
- Cool-down → **deeper teal**

**Functional** (UI semantics, not categories):
- `primaryAction` — action chrome
- `dataHighlight` — volume totals + charts
- `timerActive` — timer running state
- `success` — **vivid green** (was sage — no longer blurs with cardio)
- `destructive` — system red for danger zones
- `muted` — chevrons / dividers

The big win: you can now tell at a glance whether a green dot means *cardio* or *logged today*. Before, both were sage.

### Improved Settings Sheet
- New **Profile** section at the top with a name field (auto-capitalizes words).
- `Stepper` controls (with `M:SS` formatting for timer duration) replace freeform text fields — clearer affordance, less typing.
- "Reset Settings to Defaults" merged into the **Danger Zone** alongside "Reset All App Data".

---

## 🛠️ Quality-of-Life Improvements

### Exercise Detail History
- Each day is now its own section with date + total-volume header.
- Per-row trash button replaced with **native swipe-to-delete**.
- **Add Set** button moved **below** the reps/weight pickers — configure first, then add.

### Calendar
- Activity dots now stay visible when a day is selected (recolored to white).
- Today is the brand accent color; selected day is a neutral tint (semantic swap).
- Dots no longer clip on smaller screens.
- Weekday header is now **localized** via `Calendar.veryShortStandaloneWeekdaySymbols` and rotated by `firstWeekday` (was hardcoded English / Sunday-first).

### Timer Controls
- `–15s` and `+15s` work **while the timer is running** (were previously disabled).
- All control buttons are now 44×44pt tap targets per Apple HIG.

### Accessibility
- VoiceOver labels added to every icon-only button — cardio "+", calendar chevrons, exercise info / settings / trash, list "+" affordances, timer ±15s, etc.
- Haptic confirmation on Add Set, Jump Back In, calendar day-select, and timer Start/Pause.

### Layout & Code Health
- Floating timer migrated to `.safeAreaInset(edge: .bottom)`, replacing the manual `ZStack` + spacer-height plumbing.
- Empty states across Cardio, Strength, ExerciseList, warm-ups, and cool-downs unified into a single reusable `EmptyStateView`.

---

## 🧱 Under the Hood

### Schema (additive, lightweight migrations)
- `AppSettings.userName: String = ""` — existing rows auto-populate.
- `Exercise.cachedLastLogDate: Date?` — backfilled from existing sets on first launch via `DataMigration.performMigrations`.

### New Types
- `Greeter` — time-bucketed, name-interpolating, deterministic-by-day greeting generator.
- `EmptyStateView` — reusable empty-state primitive with optional capsule action.
- `TimerManager.progress: Double` — clamped 0–1 fraction that drives the ring and progress strip.

### Removed
- `Theme.secondary` (was a dead alias).
- `Theme.highlight` (replaced by `dataHighlight` and `timerActive`).
- `TimerState`'s height-publishing API (replaced by `safeAreaInset`).

---

## 🚧 Known Issues

- A small amount of text bleed-through is still visible near the home-indicator zone behind the rest timer when scrolling. Tracked for a follow-up patch.

---

## 📦 Migration Notes

This release is **safe to install over v1.5.0**:
- All schema changes are additive with default values.
- The cached-date migration is idempotent — only writes when stale, so subsequent launches are a no-op.
- No existing workout sets, exercises, muscle groups, cardio logs, or settings are altered or deleted.

If you previously had the developer's "Ji" hardcoded in the greeting, you'll see a neutral greeting until you set your name in Settings.

---

## 📋 System Requirements

- **iOS:** 18.5 or later
- **Device:** iPhone (all models)
- **Storage:** ~50 MB
- **Internet:** Not required (fully offline)

---

## 👨‍💻 Made With ❤️

Built with passion for fitness enthusiasts and strength athletes.

**Version:** 1.6.0
**Build Date:** May 20, 2026
**Status:** Production Ready ✅
