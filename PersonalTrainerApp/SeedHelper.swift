import Foundation
import SwiftData

/// Inserts strength defaults; TrainingStore owns initialization and saving.
enum SeedHelper {
    static func seedMuscleGroups(context: ModelContext) {
        for (order, group) in MuscleGroup.defaultGroups.enumerated() {
            group.displayOrder = order
            context.insert(group)
        }
    }
    
    static func seedExercises(context: ModelContext) {
        for (order, exercise) in Exercise.sampleExercises.enumerated() {
            exercise.displayOrder = order
            context.insert(exercise)
        }
    }
}
