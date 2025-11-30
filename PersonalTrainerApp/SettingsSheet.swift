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
                    Button("Reset to Defaults") {
                        settings.maxStorageDays = 4
                        settings.defaultTimerDuration = 90
                    }
                    .foregroundStyle(.orange)
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
        }
    }
}
