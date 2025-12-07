import SwiftUI
import SwiftData

struct SettingsSheet: View {
    @Binding var isPresented: Bool
    @Bindable var settings: AppSettings
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Rest Timer")) {
                    HStack {
                        Text("Default Duration (seconds)")
                        Spacer()
                        TextField("Seconds", value: $settings.defaultTimerDuration, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    
                    Text("Set the default countdown duration. Common values: 60 (1:00), 90 (1:30), 120 (2:00)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Section(header: Text("Data Storage")) {
                    HStack {
                        Text("Keep Last N Days of Data")
                        Spacer()
                        TextField("Days", value: $settings.maxStorageDays, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                    }
                    
                    Text("Older workout logs will be automatically deleted.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Section(footer: Text("These settings apply globally to the app.")) {
                    Button("Reset Settings to Defaults") {
                        settings.maxStorageDays = 4
                        settings.defaultTimerDuration = 90
                    }
                    .foregroundStyle(.orange)
                }
                
                Section(header: Text("Danger Zone")) {
                    Button("Reset All App Data", role: .destructive) {
                        showingResetAlert = true
                    }
                }
            }
            .navigationTitle("App Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        // Ensure changes are saved
                        try? modelContext.save()
                        isPresented = false
                    }
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
    
    @State private var showingResetAlert = false
    
    private func resetData() {
        do {
            try modelContext.delete(model: Exercise.self)
            try modelContext.delete(model: MuscleGroup.self)
            try modelContext.delete(model: CardioLog.self)
            try modelContext.delete(model: WorkoutSet.self)
            
            // Seed defaults
            seedMuscleGroups()
            seedExercises()
        } catch {
            print("Failed to reset data: \(error)")
        }
    }
    
    private func seedMuscleGroups() {
        let defaultGroups = MuscleGroup.defaultGroups
        for group in defaultGroups {
            modelContext.insert(group)
        }
    }
    
    private func seedExercises() {
        let sampleExercises = Exercise.sampleExercises
        for exercise in sampleExercises {
            modelContext.insert(exercise)
        }
    }
}
