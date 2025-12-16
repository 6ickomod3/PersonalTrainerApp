import Foundation
import SwiftData

@Model
class MuscleGroup {
    var id: UUID
    var name: String
    var createdDate: Date
    var displayOrder: Int = 0
    
    @Relationship(deleteRule: .cascade, inverse: \MuscleGroupGuide.muscleGroup) var guides: [MuscleGroupGuide] = []
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdDate = Date()
        self.displayOrder = 0
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
class GuideItem {
    var id: UUID
    var name: String
    var type: String // "warmup" or "cooldown" (or "stretch")
    var duration: String
    var instruction: String
    var icon: String
    var isCustom: Bool
    
    init(name: String, type: String, duration: String, instruction: String, icon: String, isCustom: Bool = false) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.duration = duration
        self.instruction = instruction
        self.icon = icon
        self.isCustom = isCustom
    }
}

@Model
class MuscleGroupGuide {
    var displayOrder: Int
    var category: String // "warmup" or "stretch" - helps filtering
    
    var guideItem: GuideItem?
    var muscleGroup: MuscleGroup?
    
    init(displayOrder: Int, category: String, guideItem: GuideItem) {
        self.displayOrder = displayOrder
        self.category = category
        self.guideItem = guideItem
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
    var displayOrder: Int = 0
    
    // Weight customization per exercise
    var weightMin: Double = 0.0
    var weightMax: Double = 200.0
    var weightStep: Double = 5.0
    
    // Volume improvement percentage for suggested volume calculation
    var volumeImprovementPercent: Double = 3.0
    
    // Video URL for instructions
    var videoUrl: String?
    
    // List of instruction pointers
    var instructions: [String] = []
    
    @Relationship(deleteRule: .cascade, inverse: \WorkoutSet.exercise) var sets: [WorkoutSet] = []
    
    init(name: String, muscleGroupName: String, defaultReps: Int = 10, defaultWeight: Double = 20.0, videoUrl: String? = nil, instructions: [String] = []) {
        self.id = UUID()
        self.name = name
        self.muscleGroupName = muscleGroupName
        self.defaultReps = defaultReps
        self.defaultWeight = defaultWeight
        self.createdDate = Date()
        self.lastModifiedDate = Date()
        self.displayOrder = 0
        self.weightMin = 0.0
        self.weightMax = 200.0
        self.weightStep = 5.0
        self.volumeImprovementPercent = 3.0
        self.videoUrl = videoUrl
        self.instructions = instructions
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
        
        // Remove directly from array instead of using modelContext.delete()
        for set in setsToDelete {
            sets.removeAll { $0.id == set.id }
        }
        
        if !setsToDelete.isEmpty {
            try? modelContext.save()
        }
    }
    /// Helper to get the most recent set date for sorting
    var lastLogDate: Date? {
        sets.max(by: { $0.date < $1.date })?.date
    }
    
    // MARK: - Volume Helpers
    
    var todaysVolume: Double {
        let today = Calendar.current.startOfDay(for: Date())
        let todaySets = sets.filter { Calendar.current.startOfDay(for: $0.date) == today }
        return todaySets.reduce(0) { $0 + $1.volume }
    }
    
    var lastTrainingVolume: Double? {
        let today = Calendar.current.startOfDay(for: Date())
        
        // Group by day distinctive from today
        let pastSets = sets.filter { Calendar.current.startOfDay(for: $0.date) < today }
        
        guard !pastSets.isEmpty else { return nil }
        
        // Find most recent past date
        let mostRecentDate = pastSets.map { Calendar.current.startOfDay(for: $0.date) }.max()
        
        guard let targetDate = mostRecentDate else { return nil }
        
        // Sum volume for that day
        let targetSets = pastSets.filter { Calendar.current.startOfDay(for: $0.date) == targetDate }
        return targetSets.reduce(0) { $0 + $1.volume }
    }
    
    var suggestedVolume: Double? {
        guard let last = lastTrainingVolume else { return nil }
        let improvementFactor = 1.0 + (volumeImprovementPercent / 100.0)
        return last * improvementFactor
    }
}

@Model
class WorkoutSet {
    var id: UUID = UUID()
    var reps: Int = 0
    var weight: Double = 0.0
    var date: Date = Date()
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

@Model
class CardioLog {
    var id: UUID = UUID()
    var type: String // "Run", "Cycle", "Walk", etc.
    var duration: TimeInterval // milliseconds or seconds? Let's assume seconds.
    var date: Date = Date()
    var distance: Double? // meters or miles, purely optional metadata for now
    var calories: Double?
    
    init(type: String, duration: TimeInterval, date: Date = Date(), distance: Double? = nil, calories: Double? = nil) {
        self.id = UUID()
        self.type = type
        self.duration = duration
        self.date = date
        self.distance = distance
        self.calories = calories
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
