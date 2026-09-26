import Foundation
import SwiftData
import SwiftUI

@Observable
class ExerciseDetailViewModel {
    let exercise: Exercise
    let modelContext: ModelContext

    var reps: Int
    var weight: Double
    var errorMessage: String?
    private(set) var lastAddedSetID: UUID?

    init(exercise: Exercise, modelContext: ModelContext) {
        self.exercise = exercise
        self.modelContext = modelContext
        reps = min(max(exercise.defaultReps, 1), 50)
        weight = exercise.weightConfiguration.nearest(to: exercise.defaultWeight)
        if let lastSet = exercise.sets.max(by: { $0.date < $1.date }) {
            prefillFromSet(lastSet)
        }
    }

    /// Repeating prepares the next set; the historical record stays unchanged.
    func prefillFromSet(_ set: WorkoutSet) {
        reps = min(max(set.reps, 1), 50)
        weight = exercise.weightConfiguration.nearest(to: set.weight)
    }

    func normalizeSelection() {
        reps = min(max(reps, 1), 50)
        weight = exercise.weightConfiguration.nearest(to: weight)
    }

    var setsByDate: [(date: Date, sets: [WorkoutSet], totalVolume: Double)] {
        let grouped = Dictionary(grouping: exercise.sets) { Calendar.current.startOfDay(for: $0.date) }
        return grouped.map { date, sets in
            (date: date, sets: sets.sorted { $0.date > $1.date }, totalVolume: sets.reduce(0) { $0 + $1.volume })
        }.sorted { $0.date > $1.date }
    }

    var lastTrainingVolume: Double? { exercise.lastTrainingVolume }
    var todaysVolume: Double { exercise.todaysVolume }
    var suggestedVolume: Double? { exercise.suggestedVolume }
    var canUndoLastAddedSet: Bool {
        guard let lastAddedSetID else { return false }
        return exercise.sets.contains { $0.id == lastAddedSetID }
    }

    @discardableResult
    func addSet() -> Bool {
        normalizeSelection()
        let previousSets = exercise.sets
        let previousCache = exercise.cachedLastLogDate
        let newSet = WorkoutSet(reps: reps, weight: weight)
        modelContext.insert(newSet)
        newSet.exercise = exercise
        exercise.refreshCachedLastLogDate()
        do {
            try modelContext.save()
            lastAddedSetID = newSet.id
            errorMessage = nil
            return true
        } catch {
            // Restore the inverse relationship before discarding the unsaved model.
            exercise.sets = previousSets
            exercise.cachedLastLogDate = previousCache
            modelContext.delete(newSet)
            modelContext.rollback()
            refreshAfterRollback()
            errorMessage = "Your set could not be saved. Please try again."
            return false
        }
    }

    @discardableResult
    func deleteSet(_ set: WorkoutSet) -> Bool {
        guard exercise.sets.contains(where: { $0.id == set.id }) else { return false }
        let deletedID = set.id
        let previousSets = exercise.sets
        let previousCache = exercise.cachedLastLogDate
        exercise.sets.removeAll { $0.id == deletedID }
        modelContext.delete(set)
        exercise.refreshCachedLastLogDate()
        guard saveChanges(message: "Your set could not be deleted. Please try again.", restore: {
            self.exercise.sets = previousSets
            self.exercise.cachedLastLogDate = previousCache
        }) else { return false }
        if lastAddedSetID == deletedID { lastAddedSetID = nil }
        return true
    }

    @discardableResult
    func updateSet(_ set: WorkoutSet, reps: Int, weight: Double, date: Date) -> Bool {
        guard exercise.sets.contains(where: { $0.id == set.id }), reps > 0, weight.isFinite, weight >= 0 else {
            errorMessage = "Enter a positive number of reps and a weight of zero or more."
            return false
        }
        let previous = (reps: set.reps, weight: set.weight, date: set.date, cache: exercise.cachedLastLogDate)
        // Historical values need not fit the exercise's current picker configuration.
        set.reps = reps
        set.weight = weight
        set.date = date
        exercise.refreshCachedLastLogDate()
        return saveChanges(message: "Your changes could not be saved. Please try again.", restore: {
            set.reps = previous.reps
            set.weight = previous.weight
            set.date = previous.date
            self.exercise.cachedLastLogDate = previous.cache
        })
    }

    @discardableResult
    func undoLastAddedSet() -> Bool {
        guard let lastAddedSetID, let set = exercise.sets.first(where: { $0.id == lastAddedSetID }) else { return false }
        return deleteSet(set)
    }

    private func saveChanges(message: String, restore: () -> Void) -> Bool {
        do {
            try modelContext.save()
            errorMessage = nil
            return true
        } catch {
            restore()
            modelContext.rollback()
            modelContext.processPendingChanges()
            errorMessage = message
            return false
        }
    }

    private func refreshAfterRollback() {
        // Failed saves can leave SwiftData's fetch snapshot one change behind even
        // after rollback. Refresh from persisted records before history queries run.
        var descriptor = FetchDescriptor<WorkoutSet>()
        descriptor.includePendingChanges = false
        _ = try? modelContext.fetch(descriptor)
        modelContext.processPendingChanges()
    }

}
