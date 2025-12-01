import SwiftUI
import SwiftData

struct ExerciseDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var exercise: Exercise
    @Query private var appSettings: [AppSettings]
    @Environment(TimerState.self) var timerState
    
    @State private var reps: Int
    @State private var weight: Double
    @State private var showingSettingsSheet = false
    
    var settings: AppSettings {
        appSettings.first ?? AppSettings()
    }
    
    // Dynamic spacer height based on timer state and actual measurements
    var spacerHeight: CGFloat {
        let timerHeight = timerState.isExpanded ? timerState.expandedHeight : timerState.collapsedHeight
        return timerHeight > 0 ? timerHeight : (timerState.isExpanded ? 250 : 60)
    }
    
    init(exercise: Exercise) {
        self.exercise = exercise
        _reps = State(initialValue: exercise.defaultReps)
        _weight = State(initialValue: exercise.defaultWeight)
    }
    
    // Group sets by date
    var setsByDate: [(date: Date, sets: [WorkoutSet], totalVolume: Double)] {
        let grouped = Dictionary(grouping: exercise.sets) { set in
            Calendar.current.startOfDay(for: set.date)
        }
        
        return grouped.map { date, sets in
            let sortedSets = sets.sorted(by: { $0.date > $1.date })
            let totalVolume = sortedSets.reduce(0) { $0 + $1.volume }
            return (date: date, sets: sortedSets, totalVolume: totalVolume)
        }.sorted(by: { $0.date > $1.date })
    }
    
    // Get the last training volume (from most recent date BEFORE today)
    var lastTrainingVolume: Double? {
        let today = Calendar.current.startOfDay(for: Date())
        let previousDays = setsByDate.filter { $0.date < today }
        guard let mostRecentPreviousDay = previousDays.first else { return nil }
        return mostRecentPreviousDay.totalVolume
    }
    
    // Calculate suggested volume using exercise's custom improvement percentage
    var suggestedVolume: Double? {
        guard let last = lastTrainingVolume else { return nil }
        let improvementFactor = 1.0 + (exercise.volumeImprovementPercent / 100.0)
        return last * improvementFactor
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Form {
                // Suggested Volume Section
                if let lastVolume = lastTrainingVolume, let suggested = suggestedVolume {
                    Section(header: Text("Training Progress")) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Last Training Volume")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(String(format: "%.0f", lastVolume) + " lbs")
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                }
                                Spacer()
                            }
                            
                            Divider()
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Suggested Volume (\(String(format: "%.0f", exercise.volumeImprovementPercent))% increase)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(String(format: "%.0f", suggested) + " lbs")
                                        .font(.headline)
                                        .foregroundStyle(.blue)
                                }
                                Spacer()
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Section(header: Text("New Set")) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Reps: \(reps)")
                            .font(.headline)
                        Picker("Reps", selection: $reps) {
                            ForEach(0...50, id: \.self) { rep in
                                Text("\(rep)").tag(rep)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 150)
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Weight (lbs): \(weight, specifier: "%.1f")")
                            .font(.headline)
                        Picker("Weight", selection: $weight) {
                            ForEach(Array(stride(from: exercise.weightMin, through: exercise.weightMax, by: exercise.weightStep)), id: \.self) { w in
                                Text(String(format: "%.1f", w)).tag(w)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 150)
                    }
                    
                    Button("Add Set") {
                        let newSet = WorkoutSet(reps: reps, weight: weight)
                        exercise.sets.append(newSet)
                        // Fix: Explicitly insert and save to prevent "nil" validation errors later
                        modelContext.insert(newSet)
                        try? modelContext.save()
                    }
                }
                
                Section(header: Text("History")) {
                    if exercise.sets.isEmpty {
                        Text("No sets logged yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(setsByDate, id: \.date) { dayData in
                            VStack(alignment: .leading, spacing: 12) {
                                // Daily header with total volume
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(dayData.date, style: .date)
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        Text("\(dayData.sets.count) set\(dayData.sets.count == 1 ? "" : "s")")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("Total Volume")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text("\(dayData.totalVolume, specifier: "%.0f") lbs")
                                            .font(.headline)
                                            .foregroundStyle(.blue)
                                    }
                                }
                                .padding(.bottom, 4)
                                
                                Divider()
                                
                                // Individual sets for this day
                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(dayData.sets, id: \.id) { set in
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                HStack(spacing: 8) {
                                                    Text("\(set.reps) × \(set.weight, specifier: "%.1f")")
                                                        .font(.body)
                                                        .fontWeight(.medium)
                                                    Text("= \(set.volume, specifier: "%.0f") lbs")
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)
                                                }
                                                Text(set.date, style: .time)
                                                    .font(.caption2)
                                                    .foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                            Button(action: {
                                                print("Deleting set with ID: \(set.id)")
                                                // Fix: Manually remove from relationship first to ensure UI updates correctly
                                                if let index = exercise.sets.firstIndex(where: { $0.id == set.id }) {
                                                    exercise.sets.remove(at: index)
                                                }
                                                modelContext.delete(set)
                                                try? modelContext.save()
                                            }) {
                                                Image(systemName: "trash.fill")
                                                    .font(.caption)
                                                    .foregroundStyle(.red)
                                            }
                                            .buttonStyle(.borderless) // Fix: Prevent list row from hijacking taps
                                        }
                                        .padding(.vertical, 6)
                                        
                                        if set.id != dayData.sets.last?.id {
                                            Divider()
                                                .padding(.vertical, 2)
                                        }
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                }
                
                // Dynamic spacer to push scroll endpoint to timer
                Color.clear
                    .frame(height: spacerHeight)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
        }
        .navigationTitle(exercise.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showingSettingsSheet = true }) {
                    Label("Settings", systemImage: "gear")
                }
            }
        }
        .onAppear {
            // Cleanup old sets based on app settings
            exercise.cleanupOldSets(modelContext: modelContext, maxDays: settings.maxStorageDays)
        }
        .sheet(isPresented: $showingSettingsSheet) {
            ExerciseSettingsSheet(isPresented: $showingSettingsSheet, exercise: exercise)
        }
    }
}

#Preview {
    NavigationStack {
        ExerciseDetailView(exercise: Exercise.sampleExercises[0])
    }
}

