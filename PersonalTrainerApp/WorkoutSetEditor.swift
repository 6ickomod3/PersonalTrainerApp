import SwiftUI

/// Edits a draft, including historical weights outside today's picker range.
struct WorkoutSetEditor: View {
    let set: WorkoutSet
    let onSave: (Int, Double, Date) -> Bool
    @Environment(\.dismiss) private var dismiss
    @State private var repsText: String
    @State private var weightText: String
    @State private var date: Date
    @State private var saveError: String?

    init(set: WorkoutSet, onSave: @escaping (Int, Double, Date) -> Bool) {
        self.set = set
        self.onSave = onSave
        _repsText = State(initialValue: String(set.reps))
        _weightText = State(initialValue: set.weight.formatted(.number.grouping(.never).precision(.significantDigits(1...17))))
        _date = State(initialValue: set.date)
    }

    private var validationMessage: String? {
        guard let reps = Int(repsText), reps > 0 else { return "Enter a positive whole number of reps." }
        guard let weight = ExerciseConfigurationDraft.number(weightText), weight.isFinite, weight >= 0 else {
            return "Enter a weight of zero or more."
        }
        return nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(set.exercise?.name ?? "Workout set") {
                    HStack {
                        Text("Reps")
                        TextField("Reps", text: $repsText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .accessibilityIdentifier("EditSetRepsField")
                    }
                    HStack {
                        Text("Weight (lbs)")
                        TextField("Weight", text: $weightText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .accessibilityIdentifier("EditSetWeightField")
                    }
                    DatePicker("Date and time", selection: $date)
                }
                if let message = saveError ?? validationMessage {
                    Section { Text(message).foregroundStyle(.red) }
                }
            }
            .navigationTitle("Edit Set")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard validationMessage == nil,
                              let reps = Int(repsText), let weight = ExerciseConfigurationDraft.number(weightText) else { return }
                        if onSave(reps, weight, date) { dismiss() }
                        else { saveError = "Your changes could not be saved. Please try again." }
                    }
                    .disabled(validationMessage != nil)
                    .accessibilityIdentifier("SaveSetChangesButton")
                }
            }
        }
    }
}
