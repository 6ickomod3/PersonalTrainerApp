import SwiftUI
import SwiftData

struct ExerciseDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var appSettings: [AppSettings]

    // We keep exercise here to initialize the VM
    let exercise: Exercise

    // ViewModel is optional because it depends on modelContext which is only available in body/onAppear
    @State private var viewModel: ExerciseDetailViewModel?
    @State private var showingSettingsSheet = false
    @State private var setToDelete: WorkoutSet?
    @State private var addSetCount = 0

    var settings: AppSettings {
        appSettings.first ?? AppSettings()
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
                                                .foregroundStyle(Theme.dataHighlight)
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

                            Button(action: {
                                vm.addSet()
                                addSetCount += 1
                            }) {
                                Text("Add Set")
                                    .frame(maxWidth: .infinity)
                                    .bold()
                            }
                            .buttonStyle(.borderedProminent)
                            .listRowInsets(EdgeInsets())
                            .padding()
                        }
                        
                        if vm.setsByDate.isEmpty {
                            Section(header: Text("History")) {
                                Text("No sets logged yet.")
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            ForEach(vm.setsByDate, id: \.date) { dayData in
                                Section {
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
                                        }
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            withAnimation {
                                                vm.prefillFromSet(set)
                                            }
                                        }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                setToDelete = set
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                    }
                                } header: {
                                    HStack(alignment: .firstTextBaseline) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(dayData.date, style: .date)
                                                .font(.subheadline.bold())
                                                .foregroundStyle(.primary)
                                            Text("\(dayData.sets.count) set\(dayData.sets.count == 1 ? "" : "s")")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text("Total Volume")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                            Text("\(dayData.totalVolume, specifier: "%.0f") lbs")
                                                .font(.subheadline.bold())
                                                .foregroundStyle(Theme.dataHighlight)
                                        }
                                    }
                                    .textCase(nil)
                                }
                            }
                        }
                        
                    }
                }
                .navigationTitle(exercise.name)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack {
                            NavigationLink(destination: ExerciseInstructionView(exercise: exercise)) {
                                Image(systemName: "info.circle")
                            }
                            .accessibilityLabel("Exercise instructions")

                            Button(action: { showingSettingsSheet = true }) {
                                Label("Settings", systemImage: "gear")
                            }
                            .accessibilityLabel("Exercise settings")
                        }
                    }
                }
                .onAppear {
                    vm.cleanupOldSets(maxDays: settings.maxStorageDays)
                }
                .sensoryFeedback(.success, trigger: addSetCount)
                .sheet(isPresented: $showingSettingsSheet) {
                    ExerciseSettingsSheet(isPresented: $showingSettingsSheet, exercise: exercise)
                }
                .alert("Delete Set?", isPresented: Binding(
                    get: { setToDelete != nil },
                    set: { if !$0 { setToDelete = nil } }
                )) {
                    Button("Cancel", role: .cancel) { }
                    Button("Delete", role: .destructive) {
                        if let set = setToDelete {
                            vm.deleteSet(set)
                            setToDelete = nil
                        }
                    }
                } message: {
                    Text("Are you sure you want to delete this log?")
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

