import SwiftUI

struct ExerciseConfigurationFields: View {
    @Binding var draft: ExerciseConfigurationDraft

    var body: some View {
        Section("Exercise") {
            TextField("Exercise name", text: $draft.name)
                .accessibilityIdentifier("ExerciseNameField")
        }
        Section {
            numberField("Minimum (lbs)", text: $draft.minimum, identifier: "MinimumWeightField")
            numberField("Maximum (lbs)", text: $draft.maximum, identifier: "MaximumWeightField")
            numberField("Increment (lbs)", text: $draft.increment, identifier: "WeightIncrementField")
        } header: {
            Text("Weight choices")
        } footer: {
            Text("These settings control the logging picker. Existing sets keep their original weights.")
        }
        Section {
            numberField("Volume increase (%)", text: $draft.improvement, identifier: "VolumeIncreaseField")
        } header: {
            Text("Progression goal")
        } footer: {
            Text("A suggested target based on the previous training day's total reps × weight.")
        }
    }

    private func numberField(_ title: String, text: Binding<String>, identifier: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField(title, text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(minWidth: 60, maxWidth: 120)
                .accessibilityIdentifier(identifier)
        }
    }
}

struct AddExerciseSheet: View {
    @Binding var isPresented: Bool
    /// Returns an error message on failure, or nil after the exercise has saved.
    var onAdd: (String, Double, Double, Double, Double) -> String?
    @State private var draft = ExerciseConfigurationDraft()
    @State private var saveError: String?

    var body: some View {
        NavigationStack {
            Form {
                ExerciseConfigurationFields(draft: $draft)
                if let message = saveError ?? (draft.name.isEmpty ? nil : draft.validationMessage) {
                    Section { Text(message).foregroundStyle(.red) }
                }
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .disabled(draft.validationMessage != nil)
                        .accessibilityIdentifier("SaveExerciseButton")
                }
            }
        }
    }

    private func save() {
        guard draft.validationMessage == nil,
              let min = ExerciseConfigurationDraft.number(draft.minimum),
              let max = ExerciseConfigurationDraft.number(draft.maximum),
              let step = ExerciseConfigurationDraft.number(draft.increment),
              let improvement = draft.improvementValue else { return }
        saveError = onAdd(draft.trimmedName, min, max, step, improvement)
        if saveError == nil { isPresented = false }
    }
}
