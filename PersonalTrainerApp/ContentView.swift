import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var appSettings: [AppSettings]
    @Query private var exercises: [Exercise]
    @State private var path = NavigationPath()
    @State private var historyPath = NavigationPath()
    @State private var selectedTab = 0
    @State private var showingSettings = false
    @State private var prepared = false
    @State private var startupError: String?
    @State private var timerManager: TimerManager = {
        #if DEBUG
        TimerManager(enablesExternalEffects: !ProcessInfo.processInfo.arguments.contains("--ui-testing"))
        #else
        TimerManager()
        #endif
    }()

    var body: some View {
        TabView(selection: $selectedTab) {
            VStack(spacing: 0) {
                NavigationStack(path: $path) {
                    ScrollView {
                        StrengthTrainingView(path: $path)
                            .padding(.vertical)
                    }
                    .background(Color(.systemGroupedBackground))
                    .navigationTitle("Train")
                    .toolbar { settingsButton }
                    .navigationDestination(for: MuscleGroup.self) { group in
                        ExerciseListView(muscleGroup: group)
                    }
                    .navigationDestination(for: Exercise.self) { exercise in
                        ExerciseDetailView(exercise: exercise)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                restTimer
            }
            .tabItem { Label("Train", systemImage: "dumbbell.fill") }
            .tag(0)

            VStack(spacing: 0) {
                NavigationStack(path: $historyPath) {
                    ScrollView {
                        CalendarSectionView()
                            .padding(.vertical)
                    }
                    .background(Color(.systemGroupedBackground))
                    .navigationTitle("History")
                    .toolbar { settingsButton }
                    .navigationDestination(for: Exercise.self) { exercise in
                        ExerciseDetailView(exercise: exercise)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                restTimer
            }
            .tabItem { Label("History", systemImage: "calendar") }
            .tag(1)
        }
        .task { prepareStore() }
        .onChange(of: Set(exercises.map(\.persistentModelID))) { previous, current in
            // Train can delete an exercise that is still open in the other tab.
            if !previous.subtracting(current).isEmpty {
                historyPath = NavigationPath()
            }
        }
        .sheet(isPresented: $showingSettings) {
            if let settings = appSettings.first {
                SettingsSheet(isPresented: $showingSettings, settings: settings) {
                    path = NavigationPath()
                    historyPath = NavigationPath()
                    selectedTab = 0
                    timerManager.resetToDefaultDuration(90)
                }
            }
        }
        .alert("Couldn't open your training data", isPresented: Binding(
            get: { startupError != nil },
            set: { if !$0 { startupError = nil } }
        )) {
            Button("Try Again") { prepareStore() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(startupError ?? "Your saved data has not been erased. Please try again.")
        }
    }

    private var settingsButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("Settings", systemImage: "gearshape") { showingSettings = true }
                .accessibilityIdentifier("AppSettingsButton")
                .disabled(!prepared)
        }
    }

    private var restTimer: some View {
        TimerView(timerManager: timerManager, defaultTimerDuration: appSettings.first?.defaultTimerDuration ?? 90)
    }

    private func prepareStore() {
        guard !prepared else { return }
        do {
            try TrainingStore.prepare(context: modelContext)
            prepared = true
            startupError = nil
        } catch {
            startupError = "Your saved data has not been erased. \(error.localizedDescription)"
        }
    }
}
