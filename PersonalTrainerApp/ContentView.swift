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
    @Query private var muscleGroups: [MuscleGroup]
    @Query private var exercises: [Exercise]
    @Query private var appSettings: [AppSettings]
    @State private var showingResetAlert = false
    @State private var showingAddGroupSheet = false
    @State private var showingSettingsSheet = false
    @State private var newGroupName = ""
    
    var settings: AppSettings {
        appSettings.first ?? AppSettings()
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(muscleGroups) { group in
                    NavigationLink(value: group) {
                        Text(group.name)
                    }
                }
                .onDelete { indexSet in
                    deleteGroups(at: indexSet)
                }
            }
            .navigationTitle("Workout")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Add Muscle Group") {
                            showingAddGroupSheet = true
                        }
                        Button("Settings", systemImage: "gear") {
                            showingSettingsSheet = true
                        }
                        Button("Reset Data", role: .destructive) {
                            resetData()
                        }
                    } label: {
                        Label("Menu", systemImage: "ellipsis.circle")
                    }
                }
            }
            .navigationDestination(for: MuscleGroup.self) { group in
                ExerciseListView(muscleGroup: group)
            }
        }
        .onAppear {
            DataMigration.performMigrations(modelContext: modelContext)
            
            // Seed settings if empty
            if appSettings.isEmpty {
                let newSettings = AppSettings()
                modelContext.insert(newSettings)
                try? modelContext.save()
            }
            
            // Seed muscle groups if empty
            if muscleGroups.isEmpty {
                seedMuscleGroups()
                try? modelContext.save()
            }
            
            // Seed exercises if empty
            if exercises.isEmpty {
                seedExercises()
                try? modelContext.save()
            }
        }
        .sheet(isPresented: $showingAddGroupSheet) {
            AddMuscleGroupSheet(isPresented: $showingAddGroupSheet) { name in
                addMuscleGroup(name: name)
            }
        }
        .sheet(isPresented: $showingSettingsSheet) {
            SettingsSheet(isPresented: $showingSettingsSheet, settings: settings)
        }
        .alert("Data Reset", isPresented: $showingResetAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("All data has been reset to defaults.")
        }
    }
    
    private func seedMuscleGroups() {
        let defaultGroups = MuscleGroup.defaultGroups
        for group in defaultGroups {
            modelContext.insert(group)
        }
        try? modelContext.save()
    }
    
    private func seedExercises() {
        let sampleExercises = Exercise.sampleExercises
        for exercise in sampleExercises {
            modelContext.insert(exercise)
        }
        try? modelContext.save()
    }
    
    private func addMuscleGroup(name: String) {
        let newGroup = MuscleGroup(name: name)
        modelContext.insert(newGroup)
        try? modelContext.save()
        // Force a small delay to let SwiftData update
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // This will trigger a refresh of the @Query
        }
    }
    
    private func deleteGroups(at indexSet: IndexSet) {
        for index in indexSet {
            let group = muscleGroups[index]
            // Delete all exercises in this group
            let exercisesToDelete = exercises.filter { $0.muscleGroupName == group.name }
            for exercise in exercisesToDelete {
                modelContext.delete(exercise)
            }
            modelContext.delete(group)
        }
        try? modelContext.save()
    }
    
    private func resetData() {
        do {
            try modelContext.delete(model: Exercise.self)
            try modelContext.delete(model: MuscleGroup.self)
            try modelContext.save()
            seedMuscleGroups()
            seedExercises()
            showingResetAlert = true
        } catch {
            print("Failed to reset data: \(error)")
        }
    }
}

#Preview {
    ContentView()
}

