import SwiftUI
import SwiftData

struct ExerciseListView: View {
    let muscleGroup: MuscleGroup
    @Environment(\.modelContext) private var modelContext
    @Query private var allExercises: [Exercise]
    @State private var searchText = ""
    @State private var showingAddExerciseSheet = false
    @State private var newlyCreatedExercise: Exercise?
    @State private var isNavigatingToNew = false
    @State private var exerciseToRename: Exercise?
    @State private var newName = ""
    @State private var exerciseToDelete: Exercise?
    @State private var errorMessage: String?

    private var exercises: [Exercise] {
        allExercises
            .filter { $0.muscleGroupName == muscleGroup.name }
            .sorted {
                if $0.displayOrder != $1.displayOrder { return $0.displayOrder < $1.displayOrder }
                let comparison = $0.name.localizedStandardCompare($1.name)
                if comparison != .orderedSame { return comparison == .orderedAscending }
                return $0.id.uuidString < $1.id.uuidString
            }
    }

    private var visibleExercises: [Exercise] {
        guard !searchText.isEmpty else { return exercises }
        return exercises.filter { $0.name.localizedStandardContains(searchText) }
    }

    var body: some View {
        List {
            Section {
                Button { showingAddExerciseSheet = true } label: {
                    Label("Add Exercise", systemImage: "plus.circle.fill")
                }
                .accessibilityIdentifier("AddExerciseButton")
            }
            Section {
                if exercises.isEmpty {
                    EmptyStateView(systemImage: "dumbbell", title: "Your first exercise", subtitle: "Add an exercise to start recording sets and progress.")
                } else if visibleExercises.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    ForEach(visibleExercises) { exercise in
                        ExerciseRow(exercise: exercise, onRename: {
                            newName = exercise.name
                            exerciseToRename = exercise
                        }, onDelete: {
                            exerciseToDelete = exercise
                        })
                    }
                    .onMove(perform: moveExercises)
                    .onDelete { offsets in
                        if let index = offsets.first { exerciseToDelete = visibleExercises[index] }
                    }
                    .moveDisabled(!searchText.isEmpty)
                }
            } header: {
                Text("Exercises")
            } footer: {
                if !exercises.isEmpty { Text("Use Edit to arrange exercises in your training order.") }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(muscleGroup.name)
        .searchable(text: $searchText, prompt: "Find an exercise")
        .toolbar { EditButton().disabled(exercises.isEmpty || !searchText.isEmpty) }
        .navigationDestination(isPresented: $isNavigatingToNew) {
            if let exercise = newlyCreatedExercise { ExerciseDetailView(exercise: exercise) }
        }
        .sheet(isPresented: $showingAddExerciseSheet, onDismiss: {
            if newlyCreatedExercise != nil { isNavigatingToNew = true }
        }) {
            AddExerciseSheet(isPresented: $showingAddExerciseSheet, onAdd: addExercise)
        }
        .onChange(of: isNavigatingToNew) { _, value in
            if !value { newlyCreatedExercise = nil }
        }
        .alert("Rename Exercise", isPresented: Binding(
            get: { exerciseToRename != nil },
            set: { if !$0 { exerciseToRename = nil } }
        )) {
            TextField("Exercise name", text: $newName)
            Button("Cancel", role: .cancel) { exerciseToRename = nil }
            Button("Save") { renameExercise() }
                .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .alert("Delete Exercise?", isPresented: Binding(
            get: { exerciseToDelete != nil },
            set: { if !$0 { exerciseToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { exerciseToDelete = nil }
            Button("Delete", role: .destructive) { deleteExercise() }
        } message: {
            Text("Deleting this exercise also deletes all of its logged sets. This cannot be undone.")
        }
        .alert("Could Not Save", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
    }

    private func addExercise(name: String, weightMin: Double, weightMax: Double, weightStep: Double, volumeImprovementPercent: Double) -> String? {
        let configuration = WeightConfiguration(min: weightMin, max: weightMax, step: weightStep)
        if let message = configuration.validationMessage { return message }
        let exercise = Exercise(name: name, muscleGroupName: muscleGroup.name)
        exercise.weightMin = weightMin
        exercise.weightMax = weightMax
        exercise.weightStep = weightStep
        exercise.defaultWeight = configuration.nearest(to: exercise.defaultWeight)
        exercise.volumeImprovementPercent = volumeImprovementPercent
        exercise.displayOrder = (exercises.map(\.displayOrder).max() ?? -1) + 1
        modelContext.insert(exercise)
        do {
            try modelContext.save()
            newlyCreatedExercise = exercise
            return nil
        } catch {
            modelContext.delete(exercise)
            modelContext.rollback()
            var descriptor = FetchDescriptor<Exercise>()
            descriptor.includePendingChanges = false
            _ = try? modelContext.fetch(descriptor)
            modelContext.processPendingChanges()
            return "Your exercise could not be saved. Please try again."
        }
    }

    private func renameExercise() {
        guard let exerciseToRename else { return }
        let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        exerciseToRename.name = name
        exerciseToRename.lastModifiedDate = Date()
        saveChanges()
        self.exerciseToRename = nil
    }

    private func deleteExercise() {
        guard let exerciseToDelete else { return }
        modelContext.delete(exerciseToDelete)
        saveChanges()
        self.exerciseToDelete = nil
    }

    private func moveExercises(from source: IndexSet, to destination: Int) {
        guard searchText.isEmpty else { return }
        var reordered = exercises
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, exercise) in reordered.enumerated() { exercise.displayOrder = index }
        saveChanges()
    }

    private func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            modelContext.processPendingChanges()
            errorMessage = "Your changes could not be saved. Please try again."
        }
    }
}
