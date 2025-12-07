import SwiftUI
import SwiftData

struct ExerciseListView: View {
    let muscleGroup: MuscleGroup
    @Environment(\.modelContext) private var modelContext
    @Query private var allExercises: [Exercise]
    @State private var showingAddExerciseSheet = false
    @State private var isEditingOrder = false
    @Environment(TimerState.self) var timerState
    
    @State private var newlyCreatedExercise: Exercise?
    @State private var isNavigatingToNew = false
    
    @State private var exerciseToRename: Exercise?
    @State private var newName = ""
    
    var exercises: [Exercise] {
        allExercises
            .filter { $0.muscleGroupName == muscleGroup.name }
            .sorted { $0.displayOrder < $1.displayOrder }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - Warm Up Section
                VStack(alignment: .leading, spacing: 12) {
                    Label("Warm Up", systemImage: "flame.fill")
                        .font(.headline)
                        .foregroundStyle(.orange)
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        ForEach(MuscleGroupContent.warmups(for: muscleGroup.name)) { item in
                            GuideRow(item: item, color: .orange, muscleGroup: muscleGroup.name, section: "warmup")
                        }
                    }
                    .padding(.horizontal)
                }
                
                // MARK: - Main Exercises Section
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Label("Exercises", systemImage: "dumbbell.fill")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        if isEditingOrder {
                            Button(action: { showingAddExerciseSheet = true }) {
                                Image(systemName: "plus")
                            }
                        }
                        
                        Button(isEditingOrder ? "Done" : "Edit") {
                            withAnimation {
                                isEditingOrder.toggle()
                            }
                        }
                        .font(.subheadline)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    
                    if exercises.isEmpty {
                        Text("No exercises added yet.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 20)
                    } else {
                        // Custom List-like layout since we are inside a ScrollView
                        LazyVStack(spacing: 12) {
                            ForEach(exercises) { exercise in
                                ExerciseRow(
                                    exercise: exercise,
                                    isEditing: isEditingOrder,
                                    onRename: {
                                        exerciseToRename = exercise
                                        newName = exercise.name
                                    },
                                    onDelete: {
                                        modelContext.delete(exercise)
                                        try? modelContext.save()
                                    }
                                )
                                .environment(timerState)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // MARK: - Cool Down Section
                VStack(alignment: .leading, spacing: 12) {
                    Label("Cool Down", systemImage: "snowflake")
                        .font(.headline)
                        .foregroundStyle(.blue)
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        ForEach(MuscleGroupContent.stretches(for: muscleGroup.name)) { item in
                            GuideRow(item: item, color: .blue, muscleGroup: muscleGroup.name, section: "stretch")
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Spacer for Timer
                Color.clear.frame(height: 100)
            }
            .padding(.top)
        }
        .environment(\.editMode, .constant(isEditingOrder ? .active : .inactive))
        .navigationTitle(muscleGroup.name)
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
                    exercise.name = newName
                    try? modelContext.save()
                }
            }
        } message: {
            Text("Enter a new name for this exercise.")
        }
        .sheet(isPresented: $showingAddExerciseSheet) {
            AddExerciseSheet(isPresented: $showingAddExerciseSheet, muscleGroupName: muscleGroup.name) { name, min, max, step, percent in
                addExercise(name: name, weightMin: min, weightMax: max, weightStep: step, volumeImprovementPercent: percent)
            }
        }
    }
    
    // Existing helper methods remain...
    private func addExercise(name: String, weightMin: Double, weightMax: Double, weightStep: Double, volumeImprovementPercent: Double) {
        let newExercise = Exercise(name: name, muscleGroupName: muscleGroup.name)
        newExercise.weightMin = weightMin
        newExercise.weightMax = weightMax
        newExercise.weightStep = weightStep
        newExercise.volumeImprovementPercent = volumeImprovementPercent
        newExercise.displayOrder = exercises.count
        
        modelContext.insert(newExercise)
        try? modelContext.save()
        
        newlyCreatedExercise = newExercise
        isNavigatingToNew = true
    }
    
    // Note: onDelete is handled inline now, moves handled by custom logic or future updates
    
    private func moveExercises(from source: IndexSet, to destination: Int) {
        var updatedExercises = exercises
        updatedExercises.move(fromOffsets: source, toOffset: destination)
        for (index, exercise) in updatedExercises.enumerated() {
            exercise.displayOrder = index
        }
        try? modelContext.save()
    }
}

// Subcomponents

struct GuideRow: View {
    let item: GuideItem
    let color: Color
    let muscleGroup: String
    let section: String
    @Environment(TimerState.self) var timerState
    
    @State private var isChecked = false
    
    private var storageKey: String {
        "guide_\(muscleGroup)_\(section)_\(item.name)"
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Main Content - Navigates to Detail
            NavigationLink(destination: GuideDetailView(item: item, color: color).environment(timerState)) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.body.weight(.medium))
                        .foregroundStyle(color)
                    
                    Text(item.duration)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Toggle Button
            Button(action: toggleState) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isChecked ? .green : .gray.opacity(0.3))
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear(perform: loadState)
    }
    
    private func loadState() {
        if let lastDate = UserDefaults.standard.object(forKey: storageKey) as? Date {
            isChecked = Calendar.current.isDateInToday(lastDate)
        } else {
            isChecked = false
        }
    }
    
    private func toggleState() {
        let newState = !isChecked
        isChecked = newState
        
        if newState {
            UserDefaults.standard.set(Date(), forKey: storageKey)
        } else {
            UserDefaults.standard.removeObject(forKey: storageKey)
        }
    }
}

struct GuideDetailView: View {
    let item: GuideItem
    let color: Color
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Label(item.name, systemImage: item.icon)
                        .font(.title.bold())
                        .foregroundStyle(color)
                    Spacer()
                }
                .padding(.bottom, 10)
                
                // Duration Tag
                Text("Duration: \(item.duration)")
                    .font(.subheadline.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(color.opacity(0.1))
                    .foregroundStyle(color)
                    .clipShape(Capsule())
                
                Divider()
                
                // Instructions
                Text("Instructions")
                    .font(.headline)
                
                Text(item.instruction)
                    .font(.body)
                    .lineSpacing(4)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Guide")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ExerciseRow: View {
    let exercise: Exercise
    let isEditing: Bool
    let onRename: () -> Void
    let onDelete: () -> Void
    @Environment(TimerState.self) var timerState
    
    var body: some View {
        HStack {
            if isEditing {
                Button(action: onDelete) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.red)
                }
                .padding(.leading, 8)
                
                Button(action: onRename) {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundStyle(.orange)
                }
            }
            
            NavigationLink(destination: ExerciseDetailView(exercise: exercise).environment(timerState)) {
                HStack {
                    Text(exercise.name)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack {
        ExerciseListView(muscleGroup: MuscleGroup(name: "Chest"))
    }
}

