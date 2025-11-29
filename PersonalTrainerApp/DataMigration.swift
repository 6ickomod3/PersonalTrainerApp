import SwiftUI
import SwiftData

/// Handles data migrations to ensure backward compatibility when schema changes
struct DataMigration {
    /// Performs all necessary migrations on existing data
    static func performMigrations(modelContext: ModelContext) {
        migrateExerciseMuscleGroups(modelContext: modelContext)
        migrateExerciseDates(modelContext: modelContext)
    }
    
    /// Migration: Ensure all exercises have valid muscle group assignments
    /// This handles cases where old data might have missing or invalid muscle groups
    private static func migrateExerciseMuscleGroups(modelContext: ModelContext) {
        do {
            // Fetch all exercises
            let exercises = try modelContext.fetch(FetchDescriptor<Exercise>())
            
            var needsSave = false
            
            for exercise in exercises {
                // Migration from old muscleGroupID to muscleGroupName
                if exercise.muscleGroupName.isEmpty {
                    // Try to infer from exercise name
                    let inferredGroup = inferMuscleGroup(from: exercise.name)
                    exercise.muscleGroupName = inferredGroup
                    exercise.lastModifiedDate = Date()
                    needsSave = true
                    print("Migrated exercise '\(exercise.name)' to muscle group: \(inferredGroup)")
                }
            }
            
            if needsSave {
                try modelContext.save()
                print("Exercise muscle group migration completed successfully")
            }
        } catch {
            print("Error during exercise migration: \(error)")
        }
    }
    
    /// Migration: Populate date fields for exercises that don't have them
    private static func migrateExerciseDates(modelContext: ModelContext) {
        do {
            let exercises = try modelContext.fetch(FetchDescriptor<Exercise>())
            
            var needsSave = false
            let now = Date()
            
            for exercise in exercises {
                if exercise.createdDate == nil {
                    exercise.createdDate = now
                    needsSave = true
                }
                if exercise.lastModifiedDate == nil {
                    exercise.lastModifiedDate = now
                    needsSave = true
                }
            }
            
            if needsSave {
                try modelContext.save()
                print("Date migration completed successfully")
            }
        } catch {
            print("Error during date migration: \(error)")
        }
    }
    
    /// Infers the muscle group based on exercise name
    /// This helps recover data when muscle group assignment is missing
    private static func inferMuscleGroup(from exerciseName: String) -> String {
        let name = exerciseName.lowercased()
        
        // Chest exercises
        if name.contains("bench") || name.contains("press") && name.contains("chest") ||
           name.contains("fly") || name.contains("push up") {
            return "Chest"
        }
        
        // Back exercises
        if name.contains("pull") || name.contains("row") || name.contains("deadlift") ||
           name.contains("lat") {
            return "Back"
        }
        
        // Leg exercises
        if name.contains("squat") || name.contains("lunge") || name.contains("leg") ||
           name.contains("calf") {
            return "Leg"
        }
        
        // Shoulder exercises
        if name.contains("shoulder") || name.contains("overhead") || name.contains("raise") {
            return "Shoulder"
        }
        
        // Arm exercises
        if name.contains("curl") || name.contains("tricep") || name.contains("bicep") ||
           name.contains("extension") {
            return "Arm"
        }
        
        // Default to Chest if no match found
        return "Chest"
    }
}
