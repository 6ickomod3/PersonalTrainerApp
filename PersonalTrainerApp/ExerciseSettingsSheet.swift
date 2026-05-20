import SwiftUI
import SwiftData

struct ExerciseSettingsSheet: View {
    @Binding var isPresented: Bool
    @Bindable var exercise: Exercise
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Exercise Name")) {
                    TextField("Name", text: $exercise.name)
                }
                
                Section(header: Text("Weight Logging Settings")) {
                    HStack {
                        Text("Minimum Weight (lbs)")
                        Spacer()
                        TextField("Min", value: $exercise.weightMin, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                    }
                    
                    HStack {
                        Text("Maximum Weight (lbs)")
                        Spacer()
                        TextField("Max", value: $exercise.weightMax, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                    }
                    
                    HStack {
                        Text("Weight Step (lbs)")
                        Spacer()
                        TextField("Step", value: $exercise.weightStep, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                    }
                    
                    HStack {
                        Text("Weight Range Preview")
                        Spacer()
                        Text("\(Int(exercise.weightMin)) - \(Int(exercise.weightMax)) lbs")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
                
                Section(header: Text("Training Volume Goals")) {
                    HStack {
                        Text("Target Improvement (%)")
                        Spacer()
                        TextField("Improvement %", value: $exercise.volumeImprovementPercent, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                    }
                    
                    Text("Suggested volume is calculated as: last volume × (1 + improvement %)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Section(footer: Text("Customize weight settings and training volume goals for this exercise only.")) {
                    Button("Reset to Defaults") {
                        exercise.weightMin = 0.0
                        exercise.weightMax = 200.0
                        exercise.weightStep = 5.0
                        exercise.volumeImprovementPercent = 3.0
                    }
                    .foregroundStyle(Theme.accent)
                }
            }
            .navigationTitle("Exercise Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        // Clamp values to safe ranges before saving
                        exercise.weightMin = max(0, exercise.weightMin)
                        exercise.weightMax = max(exercise.weightMin + 1, exercise.weightMax)
                        exercise.weightStep = max(0.5, exercise.weightStep)
                        exercise.volumeImprovementPercent = max(0, min(100, exercise.volumeImprovementPercent))
                        
                        // Ensure changes are saved
                        modelContext.safeSave()
                        isPresented = false
                    }
                }
            }
        }
    }
}
