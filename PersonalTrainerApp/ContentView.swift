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
    @State private var timerState = TimerState()
    
    // Rename State
    @State private var muscleGroupToRename: MuscleGroup?
    @State private var newName = ""
    
    var settings: AppSettings {
        appSettings.first ?? AppSettings()
    }
    
    // Dynamic spacer height based on timer state and actual measurements
    var spacerHeight: CGFloat {
        let timerHeight = timerState.isExpanded ? timerState.expandedHeight : timerState.collapsedHeight
        return timerHeight > 0 ? timerHeight : (timerState.isExpanded ? 250 : 60)
    }
    
    var body: some View {
        ZStack {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(Date().formatted(date: .complete, time: .omitted).uppercased())
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                
                                Text("Let's crush it, Ji! 💪")
                                    .font(.title2.bold())
                                    .foregroundStyle(.primary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        
                        // 1. Strength Section
                        StrengthTrainingView()
                            .environment(timerState)
                        
                        // 2. Cardio Section
                        CardioSectionView()
                        
                        // 3. Calendar Section
                        CalendarSectionView()
                        
                        // Spacer for Timer
                        Color.clear.frame(height: spacerHeight)
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
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        // Placeholders or future actions
                    }
                }
                .navigationDestination(for: MuscleGroup.self) { group in
                    ExerciseListView(muscleGroup: group)
                        .environment(timerState)
                }
            }
            
            // Fixed Timer at Bottom
            VStack {
                Spacer()
                TimerView(timerState: timerState, defaultTimerDuration: settings.defaultTimerDuration)
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .onAppear {
            DataMigration.performMigrations(modelContext: modelContext)
            if appSettings.isEmpty {
                modelContext.insert(AppSettings())
            }
            if muscleGroups.isEmpty {
                seedMuscleGroups()
            }
            if exercises.isEmpty {
                seedExercises()
            }
            seedGuides()
        }
        .sheet(isPresented: $showingSettingsSheet) {
            SettingsSheet(isPresented: $showingSettingsSheet, settings: settings)
        }
    }
    
    // CRUD Operations (Preserved)
    private func seedMuscleGroups() {
        let defaultGroups = MuscleGroup.defaultGroups
        for group in defaultGroups {
            modelContext.insert(group)
        }
    }
    
    private func seedExercises() {
        let sampleExercises = Exercise.sampleExercises
        for exercise in sampleExercises {
            modelContext.insert(exercise)
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
                let guideItem = getOrCreateGuideItem(from: staticItem, type: "warmup", cache: &itemCache)
                let relation = MuscleGroupGuide(displayOrder: index, category: "warmup", guideItem: guideItem)
                group.guides.append(relation)
            }
            
            // Stretches (Cooldowns)
            let staticStretches = MuscleGroupContent.stretches(for: group.name)
            for (index, staticItem) in staticStretches.enumerated() {
                let guideItem = getOrCreateGuideItem(from: staticItem, type: "cooldown", cache: &itemCache)
                let relation = MuscleGroupGuide(displayOrder: index, category: "stretch", guideItem: guideItem)
                group.guides.append(relation)
            }
        }
        
        try? modelContext.save()
    }
    
    private func getOrCreateGuideItem(from staticItem: StaticGuideItem, type: String, cache: inout [String: GuideItem]) -> GuideItem {
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

