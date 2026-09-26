import Foundation
import SwiftData

/// Repairs only relationships that can be established without guessing.
/// Persistent model declarations remain compatible with the previous release.
enum DataMigration {
    /// Applies repairs in the caller's transaction. The caller saves or rolls back.
    static func performMigrations(modelContext: ModelContext) throws {
        let exercises = try modelContext.fetch(FetchDescriptor<Exercise>())
        let groups = try modelContext.fetch(FetchDescriptor<MuscleGroup>())
        let workoutSets = try modelContext.fetch(FetchDescriptor<WorkoutSet>())
        repairSetReferences(exercises: exercises, workoutSets: workoutSets)
        let exactNames = Set(groups.map(\.name))
        let groupsByName = Dictionary(grouping: groups) { normalizedName($0.name) }

        for exercise in exercises {
            if !exactNames.contains(exercise.muscleGroupName) {
                let key = normalizedName(exercise.muscleGroupName)
                if !key.isEmpty, let matches = groupsByName[key], matches.count == 1 {
                    exercise.muscleGroupName = matches[0].name
                }
            }

            let actualLastLogDate = exercise.sets.map(\.date).max()
            if exercise.cachedLastLogDate != actualLastLogDate {
                exercise.cachedLastLogDate = actualLastLogDate
            }
        }
        // Orphan sets, unmatched names, optional dates and hidden guides/cardio remain intact.
    }

    private static func repairSetReferences(exercises: [Exercise], workoutSets: [WorkoutSet]) {
        var explicitOwners: [PersistentIdentifier: [Exercise]] = [:]
        for exercise in exercises {
            var seenObjects = Set<PersistentIdentifier>()
            let uniqueSets = exercise.sets.filter { seenObjects.insert($0.persistentModelID).inserted }
            if uniqueSets.count != exercise.sets.count { exercise.sets = uniqueSets }
            for set in uniqueSets {
                explicitOwners[set.persistentModelID, default: []].append(exercise)
            }
        }
        // A missing inverse is repairable only when one explicit forward link identifies it.
        // Standalone orphan sets have no such evidence and are never assigned an exercise.
        for set in workoutSets where set.exercise == nil {
            if let owners = explicitOwners[set.persistentModelID], owners.count == 1 {
                set.exercise = owners[0]
            }
        }

        // Distinct rows with the same app ID break SwiftUI identity and targeted deletion.
        // Normal IDs remain unchanged; repeated references to one object were handled above.
        var usedIDs = Set<UUID>()
        for set in workoutSets {
            if !usedIDs.insert(set.id).inserted {
                var replacement = UUID()
                while usedIDs.contains(replacement) { replacement = UUID() }
                set.id = replacement
                usedIDs.insert(replacement)
            }
        }
    }

    private static func normalizedName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
    }
}
