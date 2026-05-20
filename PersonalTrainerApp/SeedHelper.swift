import Foundation
import SwiftData

/// Centralized seeding logic shared across ContentView and SettingsSheet
enum SeedHelper {
    static func seedMuscleGroups(context: ModelContext) {
        for group in MuscleGroup.defaultGroups {
            context.insert(group)
        }
    }
    
    static func seedExercises(context: ModelContext) {
        for exercise in Exercise.sampleExercises {
            context.insert(exercise)
        }
    }
}

/// Safe save wrapper with error logging
extension ModelContext {
    func safeSave(file: String = #file, line: Int = #line) {
        do {
            try save()
        } catch {
            let filename = (file as NSString).lastPathComponent
            print("[\(filename):\(line)] Failed to save: \(error.localizedDescription)")
        }
    }
}
