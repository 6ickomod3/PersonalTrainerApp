//
//  ContentView.swift
//  PersonalTrainerApp
//
//  Created by Ji Dai on 11/28/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MuscleGroup.displayOrder) private var muscleGroups: [MuscleGroup]
    @Query private var exercises: [Exercise]
    @Query private var appSettings: [AppSettings]
    @State private var showingSettingsSheet = false
    @State private var newGroupName = ""
    @State private var isEditingOrder = false

    // Navigation
    @State private var path = NavigationPath()

    // Rename State
    @State private var muscleGroupToRename: MuscleGroup?
    @State private var newName = ""

    var settings: AppSettings {
        appSettings.first ?? AppSettings()
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(Date().formatted(date: .complete, time: .omitted).uppercased())
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)

                            Text(Greeter.greeting(name: settings.userName))
                                .font(.title2.bold())
                                .foregroundStyle(.primary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top)

                    // 1. Strength Section
                    StrengthTrainingView(path: $path)

                    // 2. Cardio Section
                    CardioSectionView()

                    // 3. Calendar Section
                    CalendarSectionView()
                }
            }
            .navigationTitle("Sigma Training")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button("Settings", systemImage: "gear") {
                            showingSettingsSheet = true
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.title3)
                            .foregroundStyle(.primary)
                    }
                }
            }
            .navigationDestination(for: MuscleGroup.self) { group in
                ExerciseListView(muscleGroup: group)
            }
            .navigationDestination(for: Exercise.self) { exercise in
                ExerciseDetailView(exercise: exercise)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            TimerView(defaultTimerDuration: settings.defaultTimerDuration)
        }
        .onAppear {
            DataMigration.performMigrations(modelContext: modelContext)
            if appSettings.isEmpty {
                modelContext.insert(AppSettings())
            }
            if muscleGroups.isEmpty {
                SeedHelper.seedMuscleGroups(context: modelContext)
            }
            if exercises.isEmpty {
                SeedHelper.seedExercises(context: modelContext)
            }
            seedGuides()
        }
        .sheet(isPresented: $showingSettingsSheet) {
            SettingsSheet(isPresented: $showingSettingsSheet, settings: settings)
        }
    }

    private func seedGuides() {
        // Check if we already have guides (simple check)
        let descriptor = FetchDescriptor<GuideItem>()
        let existingCount = (try? modelContext.fetchCount(descriptor)) ?? 0

        if existingCount > 0 { return }

        print("Seeding Guides...")

        // Fetch existing muscle groups
        let groupDescriptor = FetchDescriptor<MuscleGroup>()
        guard let groups = try? modelContext.fetch(groupDescriptor) else { return }

        // Cache created items to reuse them (Global Pool concept)
        var itemCache: [String: GuideItem] = [:]

        for group in groups {
            // Warmups
            let staticWarmups = MuscleGroupContent.warmups(for: group.name)
            for (index, staticItem) in staticWarmups.enumerated() {
                let guideItem = getOrCreateGuideItem(from: staticItem, type: .warmup, cache: &itemCache)
                let relation = MuscleGroupGuide(displayOrder: index, category: .warmup, guideItem: guideItem)
                group.guides.append(relation)
            }

            // Stretches (Cooldowns)
            let staticStretches = MuscleGroupContent.stretches(for: group.name)
            for (index, staticItem) in staticStretches.enumerated() {
                let guideItem = getOrCreateGuideItem(from: staticItem, type: .cooldown, cache: &itemCache)
                let relation = MuscleGroupGuide(displayOrder: index, category: .stretch, guideItem: guideItem)
                group.guides.append(relation)
            }
        }

        modelContext.safeSave()
    }

    private func getOrCreateGuideItem(from staticItem: StaticGuideItem, type: GuideType, cache: inout [String: GuideItem]) -> GuideItem {
        if let existing = cache[staticItem.name] {
            return existing
        }

        let newItem = GuideItem(
            name: staticItem.name,
            type: type,
            duration: staticItem.duration,
            instruction: staticItem.instruction,
            icon: staticItem.icon
        )
        modelContext.insert(newItem)
        cache[staticItem.name] = newItem
        return newItem
    }

}

#Preview {
    ContentView()
}

// MARK: - Greeter

enum Greeter {
    private enum Bucket {
        case morning, afternoon, evening, lateNight

        static func from(hour: Int) -> Bucket {
            switch hour {
            case 5..<12:  return .morning
            case 12..<17: return .afternoon
            case 17..<22: return .evening
            default:      return .lateNight
            }
        }

        var phrases: [String] {
            switch self {
            case .morning:
                return [
                    "Good morning{name}! Time to move 💪",
                    "Rise and grind{name} ☀️",
                    "Morning{name} — let's go!",
                    "Up early{name}? Strong start.",
                    "New day{name}, new PRs 🚀",
                    "Let's wake those muscles up{name}!"
                ]
            case .afternoon:
                return [
                    "Crushing it{name}? 💪",
                    "Midday push{name}!",
                    "Afternoon energy{name} ⚡️",
                    "Stay strong{name}!",
                    "Halfway there{name} — keep going.",
                    "Lunch break gains{name}?"
                ]
            case .evening:
                return [
                    "Evening warrior{name} 🔥",
                    "End the day strong{name}!",
                    "Powering through{name}!",
                    "One more set{name}, you got this.",
                    "Sunset reps{name}? Let's go.",
                    "Finish strong{name} 💪"
                ]
            case .lateNight:
                return [
                    "Late-night grind{name} 🌙",
                    "Burning the midnight oil{name}?",
                    "Night owl mode{name} 🦉",
                    "Quiet gym, loud gains{name}.",
                    "Still at it{name}? Respect.",
                    "After-hours hustle{name}!"
                ]
            }
        }
    }

    /// Returns a greeting that varies by time-of-day and rotates daily.
    static func greeting(for date: Date = Date(), name: String = "", calendar: Calendar = .current) -> String {
        let hour = calendar.component(.hour, from: date)
        let bucket = Bucket.from(hour: hour)
        let phrases = bucket.phrases

        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 0
        let index = dayOfYear % phrases.count
        let template = phrases[index]

        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let nameSuffix = trimmedName.isEmpty ? "" : ", \(trimmedName)"
        return template.replacingOccurrences(of: "{name}", with: nameSuffix)
    }
}

