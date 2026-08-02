import SwiftUI
import SwiftData

struct SettingsSheet: View {
    @Binding var isPresented: Bool
    @Bindable var settings: AppSettings
    @Environment(\.modelContext) private var modelContext

    @State private var showingResetAlert = false

    private var formattedDuration: String {
        let m = settings.defaultTimerDuration / 60
        let s = settings.defaultTimerDuration % 60
        return String(format: "%d:%02d", m, s)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Name")
                        Spacer()
                        TextField("Optional", text: $settings.userName)
                            .multilineTextAlignment(.trailing)
                            .textInputAutocapitalization(.words)
                            .submitLabel(.done)
                    }
                } header: {
                    Text("Profile")
                } footer: {
                    Text("Used in the dashboard greeting. Leave blank to skip.")
                }

                Section {
                    Stepper(
                        value: $settings.defaultTimerDuration,
                        in: 15...600,
                        step: 15
                    ) {
                        HStack {
                            Text("Default Duration")
                            Spacer()
                            Text(formattedDuration)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                } header: {
                    Text("Rest Timer")
                } footer: {
                    Text("Countdown shown when you tap Start. Adjusts in 15-second steps.")
                }

                Section {
                    Stepper(
                        value: $settings.maxStorageDays,
                        in: 1...30,
                        step: 1
                    ) {
                        HStack {
                            Text("Keep Last")
                            Spacer()
                            Text("\(settings.maxStorageDays) day\(settings.maxStorageDays == 1 ? "" : "s")")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                } header: {
                    Text("Data Storage")
                } footer: {
                    Text("Older workout logs are automatically deleted.")
                }

                Section {
                    Button("Reset Settings to Defaults") {
                        settings.userName = ""
                        settings.maxStorageDays = 4
                        settings.defaultTimerDuration = 90
                    }
                    .foregroundStyle(Theme.accent)

                    Button("Reset All App Data", role: .destructive) {
                        showingResetAlert = true
                    }
                } header: {
                    Text("Danger Zone")
                }
            }
            .navigationTitle("App Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        // Clamp values to safe ranges before saving (defensive — Stepper already enforces)
                        settings.defaultTimerDuration = max(15, min(600, settings.defaultTimerDuration))
                        settings.maxStorageDays = max(1, min(30, settings.maxStorageDays))
                        settings.userName = settings.userName.trimmingCharacters(in: .whitespacesAndNewlines)
                        modelContext.safeSave()
                        isPresented = false
                    }
                    .bold()
                }
            }
            .alert("Reset All Data?", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetData()
                    isPresented = false
                }
            } message: {
                Text("This will permanently delete all logs, exercises, and muscle groups. This action cannot be undone.")
            }
        }
    }

    private func resetData() {
        do {
            try modelContext.delete(model: Exercise.self)
            try modelContext.delete(model: MuscleGroup.self)
            try modelContext.delete(model: CardioLog.self)
            try modelContext.delete(model: WorkoutSet.self)

            SeedHelper.seedMuscleGroups(context: modelContext)
            SeedHelper.seedExercises(context: modelContext)
        } catch {
            print("Failed to reset data: \(error)")
        }
    }
}
