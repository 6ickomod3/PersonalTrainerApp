import Foundation
import SwiftData

/// Store lifecycle operations shared by startup, reset and compatibility tests.
@MainActor
enum TrainingStore {
    static func prepare(context: ModelContext) throws {
        do {
            let settings = try context.fetch(FetchDescriptor<AppSettings>())
            let hasExistingContent = try context.fetchCount(FetchDescriptor<MuscleGroup>()) > 0
                || context.fetchCount(FetchDescriptor<Exercise>()) > 0
                || context.fetchCount(FetchDescriptor<WorkoutSet>()) > 0
                || context.fetchCount(FetchDescriptor<CardioLog>()) > 0
                || context.fetchCount(FetchDescriptor<GuideItem>()) > 0
                || context.fetchCount(FetchDescriptor<MuscleGroupGuide>()) > 0

            // Settings also mark an initialized store whose user deleted every exercise/group.
            if settings.isEmpty && !hasExistingContent {
                SeedHelper.seedMuscleGroups(context: context)
                SeedHelper.seedExercises(context: context)
            }
            if settings.isEmpty {
                context.insert(AppSettings())
            }
            try DataMigration.performMigrations(modelContext: context)
            if context.hasChanges { try context.save() }
        } catch {
            rollBackAndRefresh(context: context)
            throw error
        }
    }

    /// Explicit user reset clears visible and retained legacy records, plus preferences.
    static func resetAll(context: ModelContext, defaults: UserDefaults = .standard) throws {
        do {
            // Use object deletion so the operation can be rolled back if saving fails.
            for set in try context.fetch(FetchDescriptor<WorkoutSet>()) { context.delete(set) }
            for link in try context.fetch(FetchDescriptor<MuscleGroupGuide>()) { context.delete(link) }
            for exercise in try context.fetch(FetchDescriptor<Exercise>()) { context.delete(exercise) }
            for group in try context.fetch(FetchDescriptor<MuscleGroup>()) { context.delete(group) }
            for guide in try context.fetch(FetchDescriptor<GuideItem>()) { context.delete(guide) }
            for cardio in try context.fetch(FetchDescriptor<CardioLog>()) { context.delete(cardio) }
            for settings in try context.fetch(FetchDescriptor<AppSettings>()) { context.delete(settings) }
            SeedHelper.seedMuscleGroups(context: context)
            SeedHelper.seedExercises(context: context)
            context.insert(AppSettings())
            try context.save()
            // Clear completion preferences only once erasing the database has succeeded.
            for key in defaults.dictionaryRepresentation().keys where key.hasPrefix("guide_") {
                defaults.removeObject(forKey: key)
            }
        } catch {
            rollBackAndRefresh(context: context)
            throw error
        }
    }

    private static func rollBackAndRefresh(context: ModelContext) {
        context.rollback()
        context.processPendingChanges()
        // SwiftData can keep the failed transaction's fetch snapshot after rollback.
        // Refresh persisted rows before the UI next queries them; preserve the original error.
        refresh(WorkoutSet.self, context: context)
        refresh(Exercise.self, context: context)
        refresh(MuscleGroupGuide.self, context: context)
        refresh(MuscleGroup.self, context: context)
        refresh(GuideItem.self, context: context)
        refresh(CardioLog.self, context: context)
        refresh(AppSettings.self, context: context)
        context.processPendingChanges()
    }

    private static func refresh<T: PersistentModel>(_ type: T.Type, context: ModelContext) {
        var descriptor = FetchDescriptor<T>()
        descriptor.includePendingChanges = false
        _ = try? context.fetch(descriptor)
    }
}
