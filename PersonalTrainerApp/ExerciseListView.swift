import SwiftUI
import SwiftData

struct ExerciseListView: View {
    let muscleGroup: MuscleGroup
    @Environment(\.modelContext) private var modelContext
    @Query private var allExercises: [Exercise]
    @State private var showingAddExerciseSheet = false
    
    var exercises: [Exercise] {
        allExercises.filter { $0.muscleGroupName == muscleGroup.name }
    }
    
    var body: some View {
        List {
            ForEach(exercises) { exercise in
                NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                    Text(exercise.name)
                }
            }
            .onDelete { indexSet in
                deleteExercises(at: indexSet)
            }
        }
        .navigationTitle(muscleGroup.name)
        .toolbar {
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
}

#Preview {
    NavigationStack {
        ExerciseListView(muscleGroup: MuscleGroup(name: "Chest"))
    }
}

