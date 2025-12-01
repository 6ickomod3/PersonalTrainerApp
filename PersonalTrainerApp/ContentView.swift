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
    @State private var showingResetAlert = false
    @State private var showingAddGroupSheet = false
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
                List {
                    ForEach(muscleGroups) { group in
                        HStack(spacing: 12) {
                            // Rename Button (Visible only in Edit Mode)
                            if isEditingOrder {
                                Button {
                                    muscleGroupToRename = group
                                    newName = group.name
                                } label: {
                                    Image(systemName: "pencil.circle.fill")
                                        .foregroundStyle(.orange)
                                        .font(.title2)
                                }
                                .buttonStyle(.borderless)
                            }
                            
                            NavigationLink(value: group) {
                                Text(group.name)
                            }
                        }
                    }
                    .onMove(perform: moveGroups)
                    .onDelete { indexSet in
                        deleteGroups(at: indexSet)
                    }
                    
                    // Dynamic spacer to push scroll endpoint to timer
                    Color.clear
                        .frame(height: spacerHeight)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
                .environment(\.editMode, .constant(isEditingOrder ? .active : .inactive))
                .navigationTitle("Target Muscle Group")
                .alert("Rename Muscle Group", isPresented: Binding(
                    get: { muscleGroupToRename != nil },
                    set: { if !$0 { muscleGroupToRename = nil } }
                )) {
                    TextField("New Name", text: $newName)
                    Button("Cancel", role: .cancel) { }
                    Button("Save") {
                        saveMuscleGroupRename()
                    }
                } message: {
                    Text("Enter a new name for this muscle group.")
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Menu {
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
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack {
                            if isEditingOrder {
                                Button(action: { showingAddGroupSheet = true }) {
                                    Image(systemName: "plus")
                                }
                            }
                            
                            Button(isEditingOrder ? "Done" : "Edit") {
                                withAnimation {
                                    isEditingOrder.toggle()
                                }
                            }
                        }
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
    
    private func saveMuscleGroupRename() {
        guard let group = muscleGroupToRename, !newName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let oldName = group.name
        group.name = newName
        
        // Update all exercises that belong to this group
        // We need to do this because the relationship is currently based on the string name
        do {
            let descriptor = FetchDescriptor<Exercise>(predicate: #Predicate { $0.muscleGroupName == oldName })
            let exercises = try modelContext.fetch(descriptor)
            for exercise in exercises {
                exercise.muscleGroupName = newName
            }
            try modelContext.save()
        } catch {
            print("Error updating exercises: \(error)")
        }
        
        muscleGroupToRename = nil
    }
    
    private func moveGroups(from source: IndexSet, to destination: Int) {
        var updatedGroups = muscleGroups
        updatedGroups.move(fromOffsets: source, toOffset: destination)
        
        // Update displayOrder for all groups
        for (index, group) in updatedGroups.enumerated() {
            group.displayOrder = index
        }
        
        try? modelContext.save()
    }
}

#Preview {
    ContentView()
}

