import Foundation
import SwiftData
import SwiftUI

@Observable
class ExerciseDetailViewModel {
    var exercise: Exercise
    var modelContext: ModelContext
    
    // Form State
    var reps: Int
    var weight: Double
    
    init(exercise: Exercise, modelContext: ModelContext) {
        self.exercise = exercise
        self.modelContext = modelContext
        
        // Default initialization
        self.reps = exercise.defaultReps
        self.weight = exercise.defaultWeight
        
        // Smart Pre-fill: Try to find the most recent set
        if let lastSet = exercise.sets.sorted(by: { $0.date > $1.date }).first {
            prefillFromSet(lastSet)
        }
    }
    
    func prefillFromSet(_ set: WorkoutSet) {
        // 1. Match Reps (Clamp to 0-50 range supported by picker)
        self.reps = min(max(set.reps, 0), 50)
        
        // 2. Match Weight (Find nearest valid step)
        let validWeights = Array(stride(from: exercise.weightMin, through: exercise.weightMax, by: exercise.weightStep))
        
        if let nearest = validWeights.min(by: { abs($0 - set.weight) < abs($1 - set.weight) }) {
            self.weight = nearest
        } else {
            // Fallback if stride fails (shouldn't happen)
            self.weight = set.weight
        }
    }
    
    // MARK: - Computed Properties
    
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
    
    // Get total volume for today
    var todaysVolume: Double {
        let today = Calendar.current.startOfDay(for: Date())
        if let todayData = setsByDate.first(where: { $0.date == today }) {
            return todayData.totalVolume
        }
        return 0
    }
    
    // Calculate suggested volume using exercise's custom improvement percentage
    var suggestedVolume: Double? {
        guard let last = lastTrainingVolume else { return nil }
        let improvementFactor = 1.0 + (exercise.volumeImprovementPercent / 100.0)
        return last * improvementFactor
    }
    
    // MARK: - Actions
    
    func addSet() {
        let newSet = WorkoutSet(reps: reps, weight: weight)
        
        // 1. Add to relationship
        exercise.sets.append(newSet)
        
        // 2. Explicit insert and save (Fix for validation error)
        modelContext.insert(newSet)
        try? modelContext.save()
    }
    
    func deleteSet(_ set: WorkoutSet) {
        print("Deleting set with ID: \(set.id)")
        
        // 1. Manually remove from relationship first (Fix for "Delete All" bug / UI sync)
        if let index = exercise.sets.firstIndex(where: { $0.id == set.id }) {
            exercise.sets.remove(at: index)
        }
        
        // 2. Delete from context
        modelContext.delete(set)
        try? modelContext.save()
    }
    
    func cleanupOldSets(maxDays: Int) {
        exercise.cleanupOldSets(modelContext: modelContext, maxDays: maxDays)
    }
}
