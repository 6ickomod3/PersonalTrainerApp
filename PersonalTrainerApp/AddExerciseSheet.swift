import SwiftUI

struct AddExerciseSheet: View {
    @Binding var isPresented: Bool
    let muscleGroupName: String
    var onAdd: (String, Int, Double) -> Void
    
    @State private var exerciseName = ""
    @State private var defaultReps = 10
    @State private var defaultWeight = 20.0
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Exercise Details")) {
                    TextField("Exercise Name", text: $exerciseName)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Default Reps: \(defaultReps)")
                            .font(.headline)
                        Picker("Default Reps", selection: $defaultReps) {
                            ForEach(1...50, id: \.self) { rep in
                                Text("\(rep)").tag(rep)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 100)
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Default Weight (lbs): \(defaultWeight, specifier: "%.0f")")
                            .font(.headline)
                        Picker("Default Weight", selection: $defaultWeight) {
                            ForEach(Array(stride(from: 0.0, through: 200.0, by: 5.0)), id: \.self) { w in
                                Text("\(Int(w))").tag(w)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 100)
                    }
                }
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        if !exerciseName.trimmingCharacters(in: .whitespaces).isEmpty {
                            onAdd(exerciseName, defaultReps, defaultWeight)
                            isPresented = false
                        }
                    }
                    .disabled(exerciseName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
