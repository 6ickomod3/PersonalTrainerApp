import SwiftUI
import SwiftData

struct ExerciseDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var exercise: Exercise
    
    @State private var reps: Int
    @State private var weight: Double
    
    init(exercise: Exercise) {
        self.exercise = exercise
        _reps = State(initialValue: exercise.defaultReps)
        _weight = State(initialValue: exercise.defaultWeight)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Form {
                Section(header: Text("New Set")) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Reps: \(reps)")
                            .font(.headline)
                        Picker("Reps", selection: $reps) {
                            ForEach(0...50, id: \.self) { rep in
                                Text("\(rep)").tag(rep)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 150)
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Weight (lbs): \(weight, specifier: "%.0f")")
                            .font(.headline)
                        Picker("Weight", selection: $weight) {
                            ForEach(Array(stride(from: 0.0, through: 200.0, by: 5.0)), id: \.self) { w in
                                Text("\(Int(w))").tag(w)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 150)
                    }
                    
                    Button("Add Set") {
                        let newSet = WorkoutSet(reps: reps, weight: weight)
                        exercise.sets.append(newSet)
                        // SwiftData autosaves, but we can be explicit if needed
                    }
                }
                
                Section(header: Text("History")) {
                    if exercise.sets.isEmpty {
                        Text("No sets logged yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(exercise.sets.sorted(by: { $0.date > $1.date })) { set in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("\(set.reps) reps @ \(set.weight, specifier: "%.1f") lbs")
                                    Text(set.date, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(set.date, style: .time)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .onDelete { indexSet in
                            // Sort sets to match the view's order before deleting
                            let sortedSets = exercise.sets.sorted(by: { $0.date > $1.date })
                            for index in indexSet {
                                let setToDelete = sortedSets[index]
                                modelContext.delete(setToDelete)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(exercise.name)
    }
}

#Preview {
    NavigationStack {
        ExerciseDetailView(exercise: Exercise.sampleExercises[0])
    }
}
