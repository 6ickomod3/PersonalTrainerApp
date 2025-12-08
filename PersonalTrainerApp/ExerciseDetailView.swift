import SwiftUI
import SwiftData

struct ExerciseDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(TimerState.self) var timerState
    @Query private var appSettings: [AppSettings]
    
    // We keep exercise here to initialize the VM
    let exercise: Exercise
    
    // ViewModel is optional because it depends on modelContext which is only available in body/onAppear
    @State private var viewModel: ExerciseDetailViewModel?
    @State private var showingSettingsSheet = false
    
    var settings: AppSettings {
        appSettings.first ?? AppSettings()
    }
    
    // Dynamic spacer height based on timer state
    var spacerHeight: CGFloat {
        let timerHeight = timerState.isExpanded ? timerState.expandedHeight : timerState.collapsedHeight
        return timerHeight > 0 ? timerHeight : (timerState.isExpanded ? 250 : 60)
    }
    
    init(exercise: Exercise) {
        self.exercise = exercise
    }
    
    var body: some View {
        Group {
            if let vm = viewModel {
                VStack(spacing: 20) {
                    Form {
                        // Suggested Volume Section
                        if let lastVolume = vm.lastTrainingVolume, let suggested = vm.suggestedVolume {
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
                                    
                                    Divider()
                                    
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Volume Today")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            Text(String(format: "%.0f", vm.todaysVolume) + " lbs")
                                                .font(.headline)
                                                .foregroundStyle(.primary)
                                        }
                                        Spacer()
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        
                        Section(header: Text("Log a set")) {
                            // Add Set Button at the top
                            Button(action: {
                                vm.addSet()
                            }) {
                                Text("Add Set")
                                    .frame(maxWidth: .infinity)
                                    .bold()
                            }
                            .buttonStyle(.borderedProminent)
                            .listRowInsets(EdgeInsets()) // Make button full width
                            .padding()
                            
                            HStack(spacing: 0) {
                                // Left Column: Reps
                                VStack(spacing: 5) {
                                    Text("Reps: \(vm.reps)")
                                        .font(.headline)
                                    Picker("Reps", selection: Bindable(vm).reps) {
                                        ForEach(0...50, id: \.self) { rep in
                                            Text("\(rep)").tag(rep)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(height: 120)
                                }
                                .frame(maxWidth: .infinity)
                                
                                Divider()
                                
                                // Right Column: Weight
                                VStack(spacing: 5) {
                                    Text("lbs: \(vm.weight, specifier: "%.1f")")
                                        .font(.headline)
                                    Picker("Weight", selection: Bindable(vm).weight) {
                                        ForEach(Array(stride(from: exercise.weightMin, through: exercise.weightMax, by: exercise.weightStep)), id: \.self) { w in
                                            Text(String(format: "%.1f", w)).tag(w)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(height: 120)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        
                        Section(header: Text("History")) {
                            if exercise.sets.isEmpty {
                                Text("No sets logged yet.")
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(vm.setsByDate, id: \.date) { dayData in
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
                                                        vm.deleteSet(set)
                                                    }) {
                                                        Image(systemName: "trash.fill")
                                                            .font(.caption)
                                                            .foregroundStyle(.red)
                                                    }
                                                    .buttonStyle(.borderless)
                                                }
                                                .padding(.vertical, 6)
                                                .contentShape(Rectangle()) // Make entire row tappable
                                                .onTapGesture {
                                                    withAnimation {
                                                        vm.prefillFromSet(set)
                                                    }
                                                }
                                                
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
                    vm.cleanupOldSets(maxDays: settings.maxStorageDays)
                }
                .sheet(isPresented: $showingSettingsSheet) {
                    ExerciseSettingsSheet(isPresented: $showingSettingsSheet, exercise: exercise)
                }
            } else {
                ProgressView()
                    .onAppear {
                        // Initialize ViewModel when view appears and context is available
                        viewModel = ExerciseDetailViewModel(exercise: exercise, modelContext: modelContext)
                    }
            }
        }
    }
}


#Preview {
    NavigationStack {
        ExerciseDetailView(exercise: Exercise.sampleExercises[0])
    }
}

