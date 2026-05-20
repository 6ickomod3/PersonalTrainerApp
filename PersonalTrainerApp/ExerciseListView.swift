import SwiftUI
import SwiftData

struct ExerciseListView: View {
    let muscleGroup: MuscleGroup
    @Environment(\.modelContext) private var modelContext
    @Query private var allExercises: [Exercise]
    
    // Sheets
    @State private var showingAddExerciseSheet = false
    @State private var showingPoolSheet = false
    @State private var poolCategory: GuideCategory = .warmup
    
    @Environment(TimerState.self) var timerState
    
    @State private var newlyCreatedExercise: Exercise?
    @State private var isNavigatingToNew = false
    
    @State private var exerciseToRename: Exercise?
    @State private var newName = ""
    
    // Confirmations
    @State private var exerciseToDelete: Exercise?
    @State private var guideToDelete: MuscleGroupGuide?
    
    // Collapsible guide sections (collapsed by default)
    @State private var isWarmupExpanded = false
    @State private var isCooldownExpanded = false
    
    // Feature: Limit visible exercises
    @State private var isExpanded = false
    let previewLimit = 5
    
    // Edit Mode
    
    var exercises: [Exercise] {
        allExercises
            .filter { $0.muscleGroupName == muscleGroup.name }
            .sorted { e1, e2 in
                // Dynamic Sort: Latest logged first
                if let d1 = e1.lastLogDate, let d2 = e2.lastLogDate {
                    return d1 > d2
                }
                if e1.lastLogDate != nil { return true }
                if e2.lastLogDate != nil { return false }
                
                return e1.displayOrder < e2.displayOrder
            }
    }
    
    var visibleExercises: [Exercise] {
        if isExpanded {
            return exercises
        } else {
            return Array(exercises.prefix(previewLimit))
        }
    }
    
    var warmups: [MuscleGroupGuide] {
        muscleGroup.guides
            .filter { $0.category == GuideCategory.warmup.rawValue }
            .sorted { $0.displayOrder < $1.displayOrder }
    }
    
    var stretches: [MuscleGroupGuide] {
        muscleGroup.guides
            .filter { $0.category == GuideCategory.stretch.rawValue }
            .sorted { $0.displayOrder < $1.displayOrder }
    }

    var body: some View {
        List {
            warmupSection
            exercisesSection
            coolDownSection
            
            // Spacer for Timer
            Color.clear.frame(height: 80).listRowBackground(Color.clear)
        }
        .listStyle(.insetGrouped)
        .navigationTitle(muscleGroup.name)
        .toolbar {
             // Toolbar items if any
        }
        .navigationDestination(isPresented: $isNavigatingToNew) {
            if let newExercise = newlyCreatedExercise {
                ExerciseDetailView(exercise: newExercise)
                    .environment(timerState)
            }
        }
        .alert("Rename Exercise", isPresented: Binding(
            get: { exerciseToRename != nil },
            set: { if !$0 { exerciseToRename = nil } }
        )) {
            TextField("New Name", text: $newName)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                if let exercise = exerciseToRename, !newName.trimmingCharacters(in: .whitespaces).isEmpty {
                    exercise.name = newName.capitalized
                    modelContext.safeSave()
                }
            }
        } message: {
            Text("Enter a new name for this exercise.")
        }
        // Delete Confirmation: Exercise
        .alert("Delete Exercise?", isPresented: Binding(
            get: { exerciseToDelete != nil },
            set: { if !$0 { exerciseToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let exercise = exerciseToDelete {
                    confirmDeleteExercise(exercise)
                }
            }
        } message: {
             if let exercise = exerciseToDelete {
                 Text("Are you sure you want to delete '\(exercise.name)'? This works cannot be undone.")
             }
        }
        // Delete Confirmation: Guide
        .alert("Delete Item?", isPresented: Binding(
            get: { guideToDelete != nil },
            set: { if !$0 { guideToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let guide = guideToDelete {
                    confirmDeleteGuide(guide)
                }
            }
        } message: {
             if let guide = guideToDelete, let item = guide.guideItem {
                 Text("Are you sure you want to remove '\(item.name)'?")
             }
        }
        .sheet(isPresented: $showingAddExerciseSheet) {
            AddExerciseSheet(isPresented: $showingAddExerciseSheet, muscleGroupName: muscleGroup.name) { name, min, max, step, percent in
                addExercise(name: name, weightMin: min, weightMax: max, weightStep: step, volumeImprovementPercent: percent)
            }
        }
        .sheet(isPresented: $showingPoolSheet) {
            GuidePoolSheet(muscleGroup: muscleGroup, category: poolCategory, isPresented: $showingPoolSheet)
        }
    }
    
    // MARK: - View Subdivisions
    
    @ViewBuilder
    private var warmupSection: some View {
        Section {
            DisclosureGroup(isExpanded: $isWarmupExpanded) {
                if warmups.isEmpty {
                    Text("No warm-ups added.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(warmups) { guide in
                        if let item = guide.guideItem {
                            GuideRow(item: item, color: Theme.warmup, muscleGroup: muscleGroup.name, section: GuideCategory.warmup.rawValue)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        guideToDelete = guide
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .onMove(perform: moveWarmups)
                    .onDelete(perform: promptDeleteWarmups)
                }
            } label: {
                HStack {
                    Label("Warm Up", systemImage: "flame.fill")
                        .foregroundStyle(Theme.warmup)
                        .font(.headline)
                    Spacer()
                    Button(action: {
                        poolCategory = .warmup
                        showingPoolSheet = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundStyle(Theme.warmup)
                    }
                    .buttonStyle(.plain)
                }
            }
            .tint(Theme.warmup)
        }
        .listRowSeparator(.hidden)
    }
    
    @ViewBuilder
    private var exercisesSection: some View {
        Section {
            if exercises.isEmpty {
                Text("No exercises added yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(visibleExercises) { exercise in
                    ExerciseRow(
                        exercise: exercise,
                        onRename: {
                            exerciseToRename = exercise
                            newName = exercise.name
                        },
                        onDelete: {
                            exerciseToDelete = exercise
                        }
                    )
                    .contextMenu {
                        Button {
                            exerciseToRename = exercise
                            newName = exercise.name
                        } label: {
                            Label("Rename", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive) {
                            exerciseToDelete = exercise
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .environment(timerState)
                }
                .onDelete(perform: promptDeleteExercises)
                
                if exercises.count > previewLimit {
                    Button(action: {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    }) {
                        HStack {
                            Text(isExpanded ? "Show Less" : "Show All (\(exercises.count - previewLimit) more)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        }
                        .foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            HStack {
                Label("Exercises", systemImage: "dumbbell.fill")
                    .foregroundStyle(Theme.accent)
                    .font(.headline)
                    .textCase(nil)
                Spacer()
                Button(action: { showingAddExerciseSheet = true }) {
                    Image(systemName: "plus")
                        .foregroundStyle(Theme.accent)
                }
            }
        }
        .listRowSeparator(.hidden)
    }
    
    @ViewBuilder
    private var coolDownSection: some View {
        Section {
            DisclosureGroup(isExpanded: $isCooldownExpanded) {
                if stretches.isEmpty {
                    Text("No cool-downs added.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(stretches) { guide in
                        if let item = guide.guideItem {
                            GuideRow(item: item, color: Theme.cooldown, muscleGroup: muscleGroup.name, section: GuideCategory.stretch.rawValue)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        guideToDelete = guide
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .onMove(perform: moveStretches)
                    .onDelete(perform: promptDeleteStretches)
                }
            } label: {
                HStack {
                    Label("Cool Down", systemImage: "snowflake")
                        .foregroundStyle(Theme.cooldown)
                        .font(.headline)
                    Spacer()
                    Button(action: {
                        poolCategory = .stretch
                        showingPoolSheet = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundStyle(Theme.cooldown)
                    }
                    .buttonStyle(.plain)
                }
            }
            .tint(Theme.cooldown)
        }
        .listRowSeparator(.hidden)
    }
    
    // CRUD Logic
    
    private func addExercise(name: String, weightMin: Double, weightMax: Double, weightStep: Double, volumeImprovementPercent: Double) {
        let newExercise = Exercise(name: name, muscleGroupName: muscleGroup.name)
        newExercise.weightMin = weightMin
        newExercise.weightMax = weightMax
        newExercise.weightStep = weightStep
        newExercise.volumeImprovementPercent = volumeImprovementPercent
        newExercise.displayOrder = exercises.count
        
        modelContext.insert(newExercise)
        modelContext.safeSave()
        
        newlyCreatedExercise = newExercise
        isNavigatingToNew = true
    }
    
    // Prompt helpers for Swipe Actions
    
    private func promptDeleteExercises(at offsets: IndexSet) {
        // Just take the first one for simplicity in this interaction
        if let firstIndex = offsets.first {
             exerciseToDelete = visibleExercises[firstIndex]
        }
    }
    
    private func confirmDeleteExercise(_ exercise: Exercise) {
        modelContext.delete(exercise)
        modelContext.safeSave()
        exerciseToDelete = nil
    }

    // Guide Management Helper
    
    // Helper to get raw array for moving
    func getGuides(category: GuideCategory) -> [MuscleGroupGuide] {
        muscleGroup.guides
            .filter { $0.category == category.rawValue }
            .sorted { $0.displayOrder < $1.displayOrder }
    }
    
    private func moveWarmups(from source: IndexSet, to destination: Int) {
        moveGuide(category: .warmup, from: source, to: destination)
    }
    
    private func promptDeleteWarmups(at offsets: IndexSet) {
        let guides = getGuides(category: .warmup)
        if let index = offsets.first {
            guideToDelete = guides[index]
        }
    }
    
    private func moveStretches(from source: IndexSet, to destination: Int) {
        moveGuide(category: .stretch, from: source, to: destination)
    }
    
    private func promptDeleteStretches(at offsets: IndexSet) {
        let guides = getGuides(category: .stretch)
        if let index = offsets.first {
            guideToDelete = guides[index]
        }
    }
    
    private func confirmDeleteGuide(_ guide: MuscleGroupGuide) {
        if let index = muscleGroup.guides.firstIndex(of: guide) {
            muscleGroup.guides.remove(at: index)
        }
        modelContext.delete(guide)
        modelContext.safeSave()
        guideToDelete = nil
    }
    
    private func moveGuide(category: GuideCategory, from source: IndexSet, to destination: Int) {
        var guides = getGuides(category: category)
        guides.move(fromOffsets: source, toOffset: destination)
        
        for (index, guide) in guides.enumerated() {
            guide.displayOrder = index
        }
        modelContext.safeSave()
    }
    
    // Deprecated direct delete helpers (replaced by confirmDeleteGuide)
    /*
    private func deleteGuide(category: String, at offsets: IndexSet) {
        let guides = getGuides(category: category)
        let toDelete = offsets.map { guides[$0] }
        
        for guide in toDelete {
            if let index = muscleGroup.guides.firstIndex(of: guide) {
                muscleGroup.guides.remove(at: index)
            }
            modelContext.delete(guide)
        }
        try? modelContext.save()
    }
    */
}
