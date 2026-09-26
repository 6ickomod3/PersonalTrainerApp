import SwiftUI
import SwiftData

struct ExerciseDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let exercise: Exercise
    @State private var viewModel: ExerciseDetailViewModel?
    @State private var showingSettingsSheet = false
    @State private var setToDelete: WorkoutSet?
    @State private var setToEdit: WorkoutSet?
    @State private var showingOlderSets = false
    @State private var repeatMessage: String?
    @State private var addSetCount = 0

    var body: some View {
        if exercise.isDeleted || exercise.modelContext == nil {
            ContentUnavailableView("Exercise Removed", systemImage: "dumbbell", description: Text("Return to Train to choose another exercise."))
                .navigationTitle("Exercise")
        } else {
            exerciseContent
        }
    }

    private var exerciseContent: some View {
        Group {
            if let vm = viewModel {
                exerciseForm(vm)
            } else {
                ProgressView()
                    .onAppear { viewModel = ExerciseDetailViewModel(exercise: exercise, modelContext: modelContext) }
            }
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingSettingsSheet = true } label: {
                    Label("Exercise settings", systemImage: "gearshape")
                }
                .accessibilityIdentifier("ExerciseSettingsButton")
            }
        }
        .sheet(isPresented: $showingSettingsSheet, onDismiss: {
            viewModel?.normalizeSelection()
        }) {
            ExerciseSettingsSheet(isPresented: $showingSettingsSheet, exercise: exercise)
        }
        .sensoryFeedback(.success, trigger: addSetCount)
    }

    private func exerciseForm(_ vm: ExerciseDetailViewModel) -> some View {
        ScrollViewReader { proxy in
            Form {
                Section {
                    Stepper("Reps: \(vm.reps)", value: Bindable(vm).reps, in: 1...50)
                        .accessibilityIdentifier("RepsStepper")
                    Picker("Weight (lbs)", selection: Bindable(vm).weight) {
                        ForEach(exercise.weightConfiguration.values, id: \.self) { weight in
                            Text(weight.formatted(.number.precision(.fractionLength(0...3)))).tag(weight)
                        }
                    }
                    .accessibilityIdentifier("WeightPicker")
                    if let message = exercise.weightConfiguration.validationMessage {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Using default weight choices. \(message)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Button("Review Weight Settings") { showingSettingsSheet = true }
                        }
                    }
                    Button {
                        if vm.addSet() {
                            repeatMessage = nil
                            addSetCount += 1
                        }
                    } label: {
                        Text("Log Set")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, minHeight: 32)
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("LogSetButton")
                    if vm.canUndoLastAddedSet {
                        HStack {
                            Label("Set saved", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(Theme.success)
                            Spacer()
                            Button("Undo") { vm.undoLastAddedSet() }
                                .accessibilityIdentifier("UndoLastSetButton")
                        }
                        .font(.subheadline)
                    }
                    if let repeatMessage {
                        Text(repeatMessage).font(.caption).foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Log a set")
                } footer: {
                    if let previous = vm.lastTrainingVolume {
                        Text("Previous training: \(previous.formatted(.number.precision(.fractionLength(0...1)))) lbs volume. Today: \(vm.todaysVolume.formatted(.number.precision(.fractionLength(0...1)))) lbs.")
                    }
                }
                .id("composer")

                Section {
                    let todaysSets = exercise.sets.filter { Calendar.current.isDateInToday($0.date) }.sorted { $0.date > $1.date }
                    if todaysSets.isEmpty {
                        Text("Your sets will appear here after you log them.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(todaysSets) { set in
                            setRow(set, vm: vm, proxy: proxy)
                        }
                    }
                } header: {
                    Text("Today")
                } footer: {
                    if vm.todaysVolume > 0 { Text("Total volume: \(vm.todaysVolume.formatted(.number.precision(.fractionLength(0...1)))) lbs (reps × weight)") }
                }

                Section {
                    NavigationLink {
                        ExerciseAnalyticsView(exercise: exercise)
                    } label: {
                        Label("Progress", systemImage: "chart.xyaxis.line")
                    }
                    .accessibilityIdentifier("ExerciseProgressLink")
                    NavigationLink {
                        ExerciseInstructionView(exercise: exercise)
                    } label: {
                        Label("Instructions", systemImage: "info.circle")
                    }
                    .accessibilityIdentifier("ExerciseInstructionsLink")
                }

                let previousDays = vm.setsByDate.filter { !Calendar.current.isDateInToday($0.date) }
                if !previousDays.isEmpty {
                    Section {
                        DisclosureGroup("Previous sets", isExpanded: $showingOlderSets) {
                            ForEach(previousDays, id: \.date) { day in
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(day.date, format: .dateTime.month(.abbreviated).day().year())
                                        .font(.subheadline.weight(.semibold))
                                    ForEach(day.sets) { set in
                                        setRow(set, vm: vm, proxy: proxy)
                                        if set.id != day.sets.last?.id { Divider() }
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                }
            }
            .sheet(item: $setToEdit) { set in
                WorkoutSetEditor(set: set) { reps, weight, date in
                    let success = vm.updateSet(set, reps: reps, weight: weight, date: date)
                    if !success { vm.errorMessage = nil } // The editor displays the save error while open.
                    return success
                }
            }
            .alert("Delete Set?", isPresented: Binding(
                get: { setToDelete != nil },
                set: { if !$0 { setToDelete = nil } }
            )) {
                Button("Cancel", role: .cancel) { setToDelete = nil }
                Button("Delete", role: .destructive) {
                    if let set = setToDelete { vm.deleteSet(set) }
                    setToDelete = nil
                }
            } message: {
                Text("This removes the selected set from your history.")
            }
            .alert("Could Not Save", isPresented: Binding(
                get: { vm.errorMessage != nil },
                set: { if !$0 { vm.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { vm.errorMessage = nil }
            } message: {
                Text(vm.errorMessage ?? "Please try again.")
            }
        }
    }

    private func setRow(_ set: WorkoutSet, vm: ExerciseDetailViewModel, proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ViewThatFits(in: .horizontal) {
                HStack {
                    setValue(set)
                    Spacer()
                    Text(set.date, style: .time).font(.caption).foregroundStyle(.secondary)
                }
                VStack(alignment: .leading) {
                    setValue(set)
                    Text(set.date, style: .time).font(.caption).foregroundStyle(.secondary)
                }
            }
            let actionLayout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 0))
                : AnyLayout(HStackLayout(spacing: 20))
            actionLayout {
                Button("Repeat", systemImage: "arrow.counterclockwise") {
                    vm.prefillFromSet(set)
                    repeatMessage = vm.weight == set.weight && vm.reps == set.reps
                        ? "Ready to repeat. Tap Log Set to save it."
                        : "Ready to repeat using your current rep and weight choices. Tap Log Set to save it."
                    withAnimation { proxy.scrollTo("composer", anchor: .top) }
                }
                .accessibilityIdentifier("RepeatSetButton")
                .frame(minHeight: 44)
                Button("Edit", systemImage: "pencil") { setToEdit = set }
                    .accessibilityIdentifier("EditSetButton")
                    .frame(minHeight: 44)
                Button("Delete", systemImage: "trash", role: .destructive) { setToDelete = set }
                    .accessibilityIdentifier("DeleteSetButton")
                    .frame(minHeight: 44)
            }
            .font(.caption)
            .buttonStyle(.borderless)
            .frame(minHeight: 44)
        }
        .accessibilityElement(children: .contain)
    }

    private func setValue(_ set: WorkoutSet) -> some View {
        Text("\(set.reps) reps × \(set.weight.formatted(.number.precision(.fractionLength(0...3)))) lbs")
            .font(.body.weight(.medium))
    }
}

#Preview {
    NavigationStack {
        ExerciseDetailView(exercise: Exercise.sampleExercises[0])
    }
}
