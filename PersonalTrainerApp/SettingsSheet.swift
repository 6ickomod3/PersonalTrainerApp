import SwiftUI
import SwiftData

struct SettingsSheet: View {
    @Binding var isPresented: Bool
    let settings: AppSettings
    var onReset: () -> Void = { }
    @Environment(\.modelContext) private var modelContext
    @State private var name: String
    @State private var duration: Int
    @State private var showingResetAlert = false
    @State private var errorMessage: String?

    init(isPresented: Binding<Bool>, settings: AppSettings, onReset: @escaping () -> Void = { }) {
        _isPresented = isPresented
        self.settings = settings
        self.onReset = onReset
        _name = State(initialValue: settings.userName)
        _duration = State(initialValue: min(max(settings.defaultTimerDuration, 15), 600))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    TextField("Name (optional)", text: $name)
                        .textInputAutocapitalization(.words)
                }
                Section {
                    Stepper(value: $duration, in: 15...600, step: 15) {
                        LabeledContent("Default rest", value: String(format: "%d:%02d", duration / 60, duration % 60))
                    }
                    .accessibilityIdentifier("DefaultRestStepper")
                } header: {
                    Text("Rest timer")
                } footer: {
                    Text("Applies immediately when idle, or to the next rest when a countdown is in progress.")
                }
                Section {
                    Label("Keep all training history", systemImage: "checkmark.circle")
                    Text("Workout records stay on this device until you delete them.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Your data")
                } footer: {
                    Text("Previous cardio and warm-up/cool-down data remains saved while those features are being redesigned.")
                }
                Section {
                    Button("Reset settings") {
                        name = ""
                        duration = 90
                    }
                    Button("Erase all app data", role: .destructive) { showingResetAlert = true }
                }
                if let errorMessage {
                    Section { Text(errorMessage).foregroundStyle(.red) }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .accessibilityIdentifier("SaveAppSettingsButton")
                }
            }
            .confirmationDialog("Erase all app data?", isPresented: $showingResetAlert, titleVisibility: .visible) {
                Button("Erase All Data", role: .destructive) { resetData() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This permanently deletes all exercises, workout history, settings, and saved cardio and guide data. Default strength exercises will be restored. This cannot be undone.")
            }
        }
    }

    private func save() {
        settings.userName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        settings.defaultTimerDuration = duration
        do {
            try modelContext.save()
            isPresented = false
        } catch {
            modelContext.rollback()
            modelContext.processPendingChanges()
            errorMessage = "Couldn't save your settings. Please try again."
        }
    }

    private func resetData() {
        do {
            try TrainingStore.resetAll(context: modelContext)
            onReset()
            isPresented = false
        } catch {
            errorMessage = "Couldn't erase your data. Please try again."
        }
    }
}
