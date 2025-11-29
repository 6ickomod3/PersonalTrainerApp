import Foundation
import SwiftData

@Model
class MuscleGroup {
    var id: UUID
    var name: String
    var createdDate: Date
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdDate = Date()
    }
    
    static var defaultGroups: [MuscleGroup] {
        [
            MuscleGroup(name: "Chest"),
            MuscleGroup(name: "Back"),
            MuscleGroup(name: "Leg"),
            MuscleGroup(name: "Shoulder"),
            MuscleGroup(name: "Arm")
        ]
    }
}

@Model
class Exercise {
    var id: UUID
    var name: String
    var muscleGroupName: String = "Chest"
    var defaultReps: Int
    var defaultWeight: Double
    var createdDate: Date?
    var lastModifiedDate: Date?
    
    // Weight customization per exercise
    var weightMin: Double = 0.0
    var weightMax: Double = 200.0
    var weightStep: Double = 5.0
    
    @Relationship(deleteRule: .cascade) var sets: [WorkoutSet] = []
    
    init(name: String, muscleGroupName: String, defaultReps: Int = 10, defaultWeight: Double = 20.0) {
        self.id = UUID()
        self.name = name
        self.muscleGroupName = muscleGroupName
        self.defaultReps = defaultReps
        self.defaultWeight = defaultWeight
        self.createdDate = Date()
        self.lastModifiedDate = Date()
        self.weightMin = 0.0
        self.weightMax = 200.0
        self.weightStep = 5.0
    }
    
    /// Cleanup old sets, keeping only the specified number of most recent dates
    func cleanupOldSets(modelContext: ModelContext, maxDays: Int = 4) {
        // Group sets by date
        let grouped = Dictionary(grouping: sets) { set in
            Calendar.current.startOfDay(for: set.date)
        }
        
        // Get unique dates sorted (most recent first)
        let uniqueDates = grouped.keys.sorted(by: >)
        
        // Keep only the specified number of most recent dates
        let datesToKeep = Set(uniqueDates.prefix(maxDays))
        
        // Delete sets from older dates
        let setsToDelete = sets.filter { set in
            let setDate = Calendar.current.startOfDay(for: set.date)
            return !datesToKeep.contains(setDate)
        }
        
        for set in setsToDelete {
            modelContext.delete(set)
        }
        
        if !setsToDelete.isEmpty {
            try? modelContext.save()
        }
    }
}

@Model
class WorkoutSet {
    var id: UUID
    var reps: Int
    var weight: Double
    var date: Date
    
    var exercise: Exercise?
    
    // Computed volume (reps × weight)
    var volume: Double {
        Double(reps) * weight
    }
    
    init(reps: Int, weight: Double, date: Date = Date()) {
        self.id = UUID()
        self.reps = reps
        self.weight = weight
        self.date = date
    }
}

extension Exercise {
    static var sampleExercises: [Exercise] {
        [
            Exercise(name: "Bench Press", muscleGroupName: "Chest", defaultReps: 8, defaultWeight: 135.0),
            Exercise(name: "Push Up", muscleGroupName: "Chest", defaultReps: 15, defaultWeight: 0.0),
            Exercise(name: "Pull Up", muscleGroupName: "Back", defaultReps: 8, defaultWeight: 0.0),
            Exercise(name: "Deadlift", muscleGroupName: "Back", defaultReps: 5, defaultWeight: 185.0),
            Exercise(name: "Squat", muscleGroupName: "Leg", defaultReps: 8, defaultWeight: 155.0),
            Exercise(name: "Lunge", muscleGroupName: "Leg", defaultReps: 12, defaultWeight: 30.0),
            Exercise(name: "Overhead Press", muscleGroupName: "Shoulder", defaultReps: 10, defaultWeight: 65.0),
            Exercise(name: "Lateral Raise", muscleGroupName: "Shoulder", defaultReps: 12, defaultWeight: 15.0),
            Exercise(name: "Bicep Curl", muscleGroupName: "Arm", defaultReps: 10, defaultWeight: 25.0),
            Exercise(name: "Tricep Extension", muscleGroupName: "Arm", defaultReps: 12, defaultWeight: 35.0)
        ]
    }
}
