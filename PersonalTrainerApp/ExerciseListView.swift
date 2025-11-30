import SwiftUI
import SwiftData

struct ExerciseListView: View {
    let muscleGroup: MuscleGroup
    @Environment(\.modelContext) private var modelContext
    @Query private var allExercises: [Exercise]
    @State private var showingAddExerciseSheet = false
    @State private var isEditingOrder = false
    @Environment(TimerState.self) var timerState
    
    var exercises: [Exercise] {
        allExercises
            .filter { $0.muscleGroupName == muscleGroup.name }
            .sorted { $0.displayOrder < $1.displayOrder }
    }
    
    var body: some View {
        List {
            ForEach(exercises) { exercise in
                HStack(spacing: 12) {
                    // Drag Handle
                    if isEditingOrder {
                        Image(systemName: "line.3.horizontal")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 14))
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
        .navigationTitle(muscleGroup.name)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(isEditingOrder ? "Done" : "Edit") {
                    withAnimation {
                        isEditingOrder.toggle()
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showingAddExerciseSheet = true }) {
                    Label("Add", systemImage: "plus.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddExerciseSheet) {
            AddExerciseSheet(isPresented: $showingAddExerciseSheet, muscleGroupName: muscleGroup.name) { name, reps, weight in
                addExercise(name: name, defaultReps: reps, defaultWeight: weight)
            }
        }
    }
    
    private func addExercise(name: String, defaultReps: Int, defaultWeight: Double) {
        let newExercise = Exercise(name: name, muscleGroupName: muscleGroup.name, defaultReps: defaultReps, defaultWeight: defaultWeight)
        newExercise.displayOrder = exercises.count
        modelContext.insert(newExercise)
        try? modelContext.save()
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

