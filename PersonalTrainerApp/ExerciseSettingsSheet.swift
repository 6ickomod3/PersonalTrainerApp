import SwiftUI
import SwiftData

struct ExerciseSettingsSheet: View {
    @Binding var isPresented: Bool
    let exercise: Exercise
    @Environment(\.modelContext) private var modelContext
    @State private var draft: ExerciseConfigurationDraft
    @State private var saveError: String?

    init(isPresented: Binding<Bool>, exercise: Exercise) {
        _isPresented = isPresented
        self.exercise = exercise
        _draft = State(initialValue: ExerciseConfigurationDraft(exercise: exercise))
    }

    var body: some View {
        NavigationStack {
            Form {
                ExerciseConfigurationFields(draft: $draft)
                Section {
                    Button("Use Default Weight Settings") {
                        let name = draft.name
                        draft = ExerciseConfigurationDraft()
                        draft.name = name
                    }
                }
                if let message = saveError ?? draft.validationMessage {
                    Section { Text(message).foregroundStyle(.red) }
                }
            }
            .navigationTitle("Exercise Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(draft.validationMessage != nil)
                        .accessibilityIdentifier("SaveExerciseSettingsButton")
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
        exercise.name = draft.trimmedName
        exercise.weightMin = min
        exercise.weightMax = max
        exercise.weightStep = step
        exercise.volumeImprovementPercent = improvement
        exercise.lastModifiedDate = Date()
        do {
            try modelContext.save()
            isPresented = false
        } catch {
            modelContext.rollback()
            modelContext.processPendingChanges()
            saveError = "Your settings could not be saved. Please try again."
        }
    }
}
