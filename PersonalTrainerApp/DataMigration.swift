import SwiftUI
import SwiftData

/// Handles data migrations to ensure backward compatibility when schema changes
struct DataMigration {
    /// Performs all necessary migrations on existing data
    static func performMigrations(modelContext: ModelContext) {
        migrateExerciseMuscleGroups(modelContext: modelContext)
        migrateExerciseMuscleGroups(modelContext: modelContext)
        migrateExerciseDates(modelContext: modelContext)
        migrateExerciseDates(modelContext: modelContext)
        migrateWorkoutSetRelationships(modelContext: modelContext)
        migrateWorkoutSetRelationships(modelContext: modelContext)
        ensureUniqueIDs(modelContext: modelContext)
        deduplicateSetReferences(modelContext: modelContext)
    }
    
    /// Migration: Remove duplicate references to the same set object in an exercise's list
    /// This fixes the issue where deleting one "copy" deletes the object, causing all copies to disappear
    private static func deduplicateSetReferences(modelContext: ModelContext) {
        do {
            let exercises = try modelContext.fetch(FetchDescriptor<Exercise>())
            var needsSave = false
            
            for exercise in exercises {
                var seenIDs = Set<UUID>()
                var uniqueSets: [WorkoutSet] = []
                
                // Filter out duplicates, keeping only the first occurrence of each ID
                for set in exercise.sets {
                    if !seenIDs.contains(set.id) {
                        seenIDs.insert(set.id)
                        uniqueSets.append(set)
                    } else {
                        print("Found duplicate reference for set ID: \(set.id) in exercise: \(exercise.name)")
                        needsSave = true
                    }
                }
                
                if uniqueSets.count != exercise.sets.count {
                    exercise.sets = uniqueSets
                }
            }
            
            if needsSave {
                try modelContext.save()
                print("Deduplication migration completed successfully")
            }
        } catch {
            print("Error during deduplication migration: \(error)")
        }
    }
    
    /// Migration: Ensure all workout sets have unique IDs
    /// This fixes potential issues where duplicate IDs cause multiple sets to be deleted at once
    private static func ensureUniqueIDs(modelContext: ModelContext) {
        do {
            let sets = try modelContext.fetch(FetchDescriptor<WorkoutSet>())
            var seenIDs = Set<UUID>()
            var needsSave = false
            
            for set in sets {
                if seenIDs.contains(set.id) {
                    // Duplicate found! Regenerate ID
                    let oldID = set.id
                    set.id = UUID()
                    needsSave = true
                    print("Fixed duplicate ID for set: \(oldID) -> \(set.id)")
                } else {
                    seenIDs.insert(set.id)
                }
            }
            
            if needsSave {
                try modelContext.save()
                print("Unique ID migration completed successfully")
            }
        } catch {
            print("Error during unique ID migration: \(error)")
        }
    }
    
    /// Migration: Ensure all workout sets have a valid back-reference to their exercise
    private static func migrateWorkoutSetRelationships(modelContext: ModelContext) {
        do {
            let exercises = try modelContext.fetch(FetchDescriptor<Exercise>())
            var needsSave = false
            
            for exercise in exercises {
                for set in exercise.sets {
                    if set.exercise == nil {
                        set.exercise = exercise
                        needsSave = true
                    }
                }
            }
            
            if needsSave {
                try modelContext.save()
                print("WorkoutSet relationship migration completed successfully")
            }
        } catch {
            print("Error during workout set migration: \(error)")
        }
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
