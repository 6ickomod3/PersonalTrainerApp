import SwiftUI

struct AddExerciseSheet: View {
    @Binding var isPresented: Bool
    let muscleGroupName: String
    // Callback: name, weightMin, weightMax, weightStep, volumeImprovementPercent
    var onAdd: (String, Double, Double, Double, Double) -> Void
    
    @State private var exerciseName = ""
    @State private var weightMin = 0.0
    @State private var weightMax = 200.0
    @State private var weightStep = 5.0
    @State private var volumeImprovementPercent = 3.0
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Exercise Details")) {
                    TextField("Exercise Name", text: $exerciseName)
                }
                
                Section(header: Text("Weight Configuration")) {
                    HStack {
                        Text("Min Weight")
                        Spacer()
                        TextField("0", value: $weightMin, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("lbs")
                    }
                    
                    HStack {
                        Text("Max Weight")
                        Spacer()
                        TextField("200", value: $weightMax, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("lbs")
                    }
                    
                    HStack {
                        Text("Step Increment")
                        Spacer()
                        TextField("5", value: $weightStep, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("lbs")
                    }
                }
                
                Section(header: Text("Progression Goal")) {
                    HStack {
                        Text("Volume Increase")
                        Spacer()
                        TextField("3", value: $volumeImprovementPercent, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("%")
                    }
                    Text("Suggested volume will increase by this percentage each session.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
                            onAdd(exerciseName.capitalized, weightMin, weightMax, weightStep, volumeImprovementPercent)
                            isPresented = false
                        }
                    }
                    .disabled(exerciseName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
