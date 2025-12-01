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
        List {
            ForEach(exercises) { exercise in
                HStack(spacing: 12) {
                    // Rename Button (Visible only in Edit Mode)
                    if isEditingOrder {
                        Button {
                            exerciseToRename = exercise
                            newName = exercise.name
                        } label: {
                            Image(systemName: "pencil.circle.fill")
                                .foregroundStyle(.orange)
                                .font(.title2)
                        }
                        .buttonStyle(.borderless)
                    }
                    
                    NavigationLink(destination: ExerciseDetailView(exercise: exercise).environment(timerState)) {
                        Text(exercise.name)
                    }
                }
            }
            .onMove(perform: moveExercises)
            .onDelete { indexSet in
                deleteExercises(at: indexSet)
            }
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
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
                }
            }
        }
        .sheet(isPresented: $showingAddExerciseSheet) {
            AddExerciseSheet(isPresented: $showingAddExerciseSheet, muscleGroupName: muscleGroup.name) { name, min, max, step, percent in
                addExercise(name: name, weightMin: min, weightMax: max, weightStep: step, volumeImprovementPercent: percent)
            }
        }
    }
    
    private func addExercise(name: String, weightMin: Double, weightMax: Double, weightStep: Double, volumeImprovementPercent: Double) {
        let newExercise = Exercise(name: name, muscleGroupName: muscleGroup.name)
        newExercise.weightMin = weightMin
        newExercise.weightMax = weightMax
        newExercise.weightStep = weightStep
        newExercise.volumeImprovementPercent = volumeImprovementPercent
        newExercise.displayOrder = exercises.count
        
        modelContext.insert(newExercise)
        try? modelContext.save()
        
        // Trigger navigation
        newlyCreatedExercise = newExercise
        isNavigatingToNew = true
    }
    
    private func deleteExercises(at indexSet: IndexSet) {
        for index in indexSet {
            let exercise = exercises[index]
            modelContext.delete(exercise)
        }
        try? modelContext.save()
    }
    
    private func moveExercises(from source: IndexSet, to destination: Int) {
        var updatedExercises = exercises
        updatedExercises.move(fromOffsets: source, toOffset: destination)
        
        // Update displayOrder for all exercises in this muscle group
        for (index, exercise) in updatedExercises.enumerated() {
            exercise.displayOrder = index
        }
        
        try? modelContext.save()
    }
}

#Preview {
    NavigationStack {
        ExerciseListView(muscleGroup: MuscleGroup(name: "Chest"))
    }
}

