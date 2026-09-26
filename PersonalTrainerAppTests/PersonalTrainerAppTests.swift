import Foundation
import SwiftData
import Testing
@testable import PersonalTrainerApp

@Suite("Weight configuration")
struct WeightConfigurationTests {
    @Test func rejectsUnsafeConfigurationsAndBoundsFallback() {
        let invalid = [
            WeightConfiguration(min: 0, max: 200, step: 0),
            WeightConfiguration(min: 0, max: 200, step: -5),
            WeightConfiguration(min: 20, max: 10, step: 5),
            WeightConfiguration(min: -1, max: 200, step: 5),
            WeightConfiguration(min: 0, max: .infinity, step: 5),
            WeightConfiguration(min: .nan, max: 200, step: 5),
            WeightConfiguration(min: 0, max: 200, step: .nan),
            WeightConfiguration(min: 0, max: 200, step: 0.000_001)
        ]
        for configuration in invalid {
            #expect(configuration.validationMessage != nil)
            #expect(configuration.values.count == 41)
            #expect(configuration.values.allSatisfy { $0.isFinite && $0 >= 0 })
            #expect(configuration.nearest(to: .nan).isFinite)
        }
    }

    @Test func exerciseDraftRequiresWholeValidNumbers() {
        #expect(ExerciseConfigurationDraft.number("1abc") == nil)
        #expect(ExerciseConfigurationDraft.number("") == nil)
        #expect(ExerciseConfigurationDraft.number("NaN") == nil)
        #expect(ExerciseConfigurationDraft.number(" 12.5 ") == 12.5)
        #expect(ExerciseConfigurationDraft.number("1e2") == 100)
        let decimalSeparator = Locale.current.decimalSeparator ?? "."
        #expect(ExerciseConfigurationDraft.number("1\(decimalSeparator)25") == 1.25)
        var draft = ExerciseConfigurationDraft()
        draft.name = "Squat"
        #expect(draft.validationMessage == nil)
        draft.increment = "0"
        #expect(draft.validationMessage != nil)
        draft.increment = "5"
        draft.minimum = "-1"
        #expect(draft.validationMessage != nil)
        draft.minimum = "0"
        draft.improvement = "1e999"
        #expect(draft.validationMessage != nil)
    }

    @Test func supportsDecimalsSingleValueAndNearestWeight() {
        let decimals = WeightConfiguration(min: 0, max: 0.3, step: 0.1)
        #expect(decimals.validationMessage == nil)
        #expect(decimals.values.count == 4)
        #expect(decimals.values.last == 0.3)
        #expect(decimals.nearest(to: 0.18) == 0.2)
        #expect(decimals.nearest(to: -100) == 0)
        #expect(decimals.nearest(to: 100) == 0.3)
        #expect(WeightConfiguration(min: 20, max: 20, step: 5).values == [20])
        #expect(WeightConfiguration(min: 0, max: 1000, step: 1).values.count == 1001)
    }
}

@MainActor
@Suite("Store lifecycle and compatibility")
struct TrainingStoreTests {
    @Test func seedsOnlyNewStoreAndNeverSeedsGuides() throws {
        let container = try makeContainer()
        let context = container.mainContext
        try TrainingStore.prepare(context: context)
        let originalIDs = try context.fetch(FetchDescriptor<Exercise>()).map(\.id).sorted { $0.uuidString < $1.uuidString }
        try TrainingStore.prepare(context: context)
        #expect(try context.fetchCount(FetchDescriptor<MuscleGroup>()) == 5)
        #expect(try context.fetchCount(FetchDescriptor<Exercise>()) == 10)
        #expect(try context.fetchCount(FetchDescriptor<AppSettings>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<GuideItem>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<MuscleGroupGuide>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<CardioLog>()) == 0)
        #expect(try context.fetch(FetchDescriptor<Exercise>()).map(\.id).sorted { $0.uuidString < $1.uuidString } == originalIDs)
        #expect(try context.fetch(FetchDescriptor<MuscleGroup>()).map(\.displayOrder).sorted() == [0, 1, 2, 3, 4])
    }

    @Test func preservesIntentionalEmptyStoreAndPreferences() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let settings = AppSettings()
        settings.userName = "Alex"
        settings.defaultTimerDuration = 45
        settings.maxStorageDays = 2
        context.insert(settings)
        try context.save()
        try TrainingStore.prepare(context: context)
        #expect(try context.fetchCount(FetchDescriptor<Exercise>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<MuscleGroup>()) == 0)
        #expect(settings.userName == "Alex")
        #expect(settings.defaultTimerDuration == 45)
        #expect(settings.maxStorageDays == 2)
    }

    @Test func legacyOnlyStoreIsNotTreatedAsNew() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let cardio = CardioLog(type: "Run", duration: 1200)
        context.insert(cardio)
        try context.save()
        try TrainingStore.prepare(context: context)
        #expect(try context.fetchCount(FetchDescriptor<Exercise>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<MuscleGroup>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<CardioLog>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<AppSettings>()) == 1)
    }

    @Test func repairsOnlyUnambiguousGroupLinksWithoutRenaming() throws {
        let container = try makeContainer()
        let context = container.mainContext
        for name in ["Upper Body", "Arms", "ARMS"] { context.insert(MuscleGroup(name: name)) }
        let repairable = Exercise(name: "DB press", muscleGroupName: "upper body")
        let ambiguous = Exercise(name: "EZ curl", muscleGroupName: "arms")
        let unknown = Exercise(name: "My movement", muscleGroupName: "custom")
        let empty = Exercise(name: "Bench Press", muscleGroupName: "")
        for exercise in [repairable, ambiguous, unknown, empty] { context.insert(exercise) }
        try context.save()
        try TrainingStore.prepare(context: context)
        #expect(repairable.muscleGroupName == "Upper Body")
        #expect(repairable.name == "DB press")
        #expect(ambiguous.muscleGroupName == "arms")
        #expect(unknown.muscleGroupName == "custom")
        #expect(empty.muscleGroupName == "")
        #expect(try context.fetch(FetchDescriptor<MuscleGroup>()).map(\.name).sorted() == ["ARMS", "Arms", "Upper Body"])
    }

    @Test func repairsDuplicateSetIdentityWithoutLosingRowsOrGuessingOrphans() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let exercise = Exercise(name: "DB press", muscleGroupName: "Chest")
        exercise.createdDate = nil
        exercise.lastModifiedDate = nil
        context.insert(exercise)
        let first = WorkoutSet(reps: 10, weight: 20)
        let second = WorkoutSet(reps: 8, weight: 25)
        let sharedID = first.id
        second.id = sharedID
        let orphan = WorkoutSet(reps: 6, weight: 30)
        let orphanID = orphan.id
        for set in [first, second, orphan] { context.insert(set) }
        exercise.sets = [first, first, second]
        try context.save()
        try TrainingStore.prepare(context: context)
        let allSets = try context.fetch(FetchDescriptor<WorkoutSet>())
        #expect(allSets.count == 3)
        #expect(Set(allSets.map(\.id)).count == 3)
        #expect(allSets.contains { $0.id == sharedID })
        #expect(allSets.map(\.weight).sorted() == [20, 25, 30])
        #expect(exercise.sets.count == 2)
        #expect(Set(exercise.sets.map(\.persistentModelID)).count == 2)
        #expect(exercise.sets.allSatisfy { $0.exercise?.id == exercise.id })
        #expect(orphan.id == orphanID && orphan.exercise == nil)
        #expect(exercise.createdDate == nil && exercise.lastModifiedDate == nil)
        let repairedIDs = Set(allSets.map(\.id))
        try TrainingStore.prepare(context: context)
        #expect(Set(allSets.map(\.id)) == repairedIDs)
    }

    @Test func retainedDataSurvivesPrepareSaveAndDiskReopen() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("compatibility.store")
        let ids = try createFixtureOnDisk(url: url)
        try prepareAndVerifyFixture(url: url, ids: ids)
        // A second container verifies the repair and all retained fields were actually saved.
        try prepareAndVerifyFixture(url: url, ids: ids)
    }

    @Test func failedResetRollsBackAndKeepsGuidePreferences() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("readonly.store")
        let ids = try createFixtureOnDisk(url: url)
        let container = try makeContainer(url: url, allowsSave: false)
        let context = container.mainContext
        let suiteName = "TrainingStoreFailureTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let completionKey = "guide_Upper Body_warmup_my warm-up"
        defaults.set(fixtureDate, forKey: completionKey)
        var reportedFailure = false
        do { try TrainingStore.resetAll(context: context, defaults: defaults) }
        catch { reportedFailure = true }
        #expect(reportedFailure)
        #expect(!context.hasChanges)
        #expect(defaults.object(forKey: completionKey) as? Date == fixtureDate)
        let retainedSets = try context.fetch(FetchDescriptor<WorkoutSet>())
        #expect(Set(retainedSets.map(\.id)) == Set(ids.sets + [ids.orphan]))
        let diskContext = ModelContext(container)
        #expect(try diskContext.fetchCount(FetchDescriptor<WorkoutSet>()) == 11)
        #expect(try context.fetchCount(FetchDescriptor<CardioLog>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<MuscleGroupGuide>()) == 1)
        #expect(try context.fetch(FetchDescriptor<Exercise>()).first?.id == ids.exercise)
        #expect(try context.fetch(FetchDescriptor<AppSettings>()).first?.id == ids.settings)
    }

    @Test func explicitResetClearsHiddenDataOrphansAndPreferences() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let ids = try insertFixture(context: context)
        let suiteName = "TrainingStoreTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(fixtureDate, forKey: "guide_Upper Body_warmup_my warm-up")
        defaults.set("keep", forKey: "unrelated_preference")
        try TrainingStore.resetAll(context: context, defaults: defaults)
        #expect(defaults.object(forKey: "guide_Upper Body_warmup_my warm-up") == nil)
        #expect(defaults.string(forKey: "unrelated_preference") == "keep")
        #expect(try context.fetchCount(FetchDescriptor<WorkoutSet>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<CardioLog>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<GuideItem>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<MuscleGroupGuide>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<MuscleGroup>()) == 5)
        #expect(try context.fetchCount(FetchDescriptor<Exercise>()) == 10)
        let settings = try #require(context.fetch(FetchDescriptor<AppSettings>()).first)
        #expect(settings.id != ids.settings)
        #expect(settings.userName.isEmpty)
        #expect(settings.defaultTimerDuration == 90)
        try TrainingStore.prepare(context: context)
        #expect(try context.fetchCount(FetchDescriptor<Exercise>()) == 10)
    }
}

@MainActor
@Suite("Exercise logging")
struct ExerciseDetailViewModelTests {
    @Test func addsEditsDeletesAndUndoesUsingProductionActions() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let exercise = Exercise(name: "Squat", muscleGroupName: "Leg")
        context.insert(exercise)
        try context.save()
        let vm = ExerciseDetailViewModel(exercise: exercise, modelContext: context)
        vm.reps = 5
        vm.weight = 73
        #expect(vm.addSet())
        let first = try #require(exercise.sets.first)
        #expect(first.reps == 5)
        #expect(first.weight == 75)
        #expect(first.exercise?.id == exercise.id)
        let yesterday = try #require(Calendar.current.date(byAdding: .day, value: -1, to: Date()))
        // Historical corrections retain weights outside today's picker range.
        #expect(vm.updateSet(first, reps: 6, weight: 225, date: yesterday))
        #expect(first.weight == 225)
        #expect(first.date == yesterday)
        #expect(vm.lastTrainingVolume == 1350)
        #expect(exercise.cachedLastLogDate == yesterday)
        #expect(vm.addSet())
        #expect(exercise.sets.count == 2)
        #expect(vm.undoLastAddedSet())
        #expect(exercise.sets.count == 1)
        #expect(exercise.sets.first?.id == first.id)
        #expect(vm.deleteSet(first))
        #expect(exercise.sets.isEmpty)
        #expect(exercise.cachedLastLogDate == nil)
        #expect(try context.fetchCount(FetchDescriptor<WorkoutSet>()) == 0)
    }

    @Test func deletingOneSetDoesNotDeleteSameDateSiblings() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let exercise = Exercise(name: "Curl", muscleGroupName: "Arm")
        context.insert(exercise)
        let now = Date()
        let sets = [20.0, 25.0, 30.0].map { WorkoutSet(reps: 10, weight: $0, date: now) }
        for set in sets { context.insert(set); set.exercise = exercise }
        try context.save()
        let vm = ExerciseDetailViewModel(exercise: exercise, modelContext: context)
        #expect(vm.deleteSet(sets[1]))
        #expect(Set(exercise.sets.map(\.id)) == Set([sets[0].id, sets[2].id]))
        #expect(try context.fetchCount(FetchDescriptor<WorkoutSet>()) == 2)
    }

    @Test func rejectsInvalidHistoricalValuesWithoutChangingRecord() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let exercise = Exercise(name: "Bench", muscleGroupName: "Chest")
        context.insert(exercise)
        let set = WorkoutSet(reps: 10, weight: 50)
        context.insert(set)
        set.exercise = exercise
        try context.save()
        let vm = ExerciseDetailViewModel(exercise: exercise, modelContext: context)
        #expect(!vm.updateSet(set, reps: 0, weight: 50, date: set.date))
        #expect(!vm.updateSet(set, reps: 10, weight: .nan, date: set.date))
        #expect(!vm.updateSet(set, reps: 10, weight: -1, date: set.date))
        #expect(set.reps == 10)
        #expect(set.weight == 50)
        #expect(vm.errorMessage != nil)
    }

    @Test func failedLogSaveRollsBackAndReportsAnError() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("readonly.store")
        let ids = try createFixtureOnDisk(url: url)
        let container = try makeContainer(url: url, allowsSave: false)
        let context = container.mainContext
        let exercise = try #require(context.fetch(FetchDescriptor<Exercise>()).first)
        let vm = ExerciseDetailViewModel(exercise: exercise, modelContext: context)
        #expect(!vm.addSet())
        #expect(vm.errorMessage != nil)
        #expect(vm.lastAddedSetID == nil)
        #expect(!context.hasChanges)
        #expect(Set(exercise.sets.map(\.id)) == Set(ids.sets))
        let retainedSets = try context.fetch(FetchDescriptor<WorkoutSet>())
        #expect(Set(retainedSets.map(\.id)) == Set(ids.sets + [ids.orphan]))
        let diskContext = ModelContext(container)
        #expect(Set(try diskContext.fetch(FetchDescriptor<WorkoutSet>()).map(\.id)) == Set(ids.sets + [ids.orphan]))
        let set = try #require(exercise.sets.first)
        let original = (reps: set.reps, weight: set.weight, date: set.date)
        #expect(!vm.updateSet(set, reps: 25, weight: 250, date: Date()))
        #expect(set.reps == original.reps && set.weight == original.weight && set.date == original.date)
        #expect(!vm.deleteSet(set))
        #expect(Set(exercise.sets.map(\.id)) == Set(ids.sets))
        #expect(!context.hasChanges)
    }

    @Test func openingExerciseKeepsAllHistoryAndHandlesInvalidLegacyStep() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let ids = try insertFixture(context: context)
        try TrainingStore.prepare(context: context)
        let exercise = try #require(context.fetch(FetchDescriptor<Exercise>()).first)
        let vm = ExerciseDetailViewModel(exercise: exercise, modelContext: context)
        #expect(vm.weight.isFinite)
        #expect(exercise.weightStep == 0)
        #expect(Set(exercise.sets.map(\.id)) == Set(ids.sets))
        #expect(try context.fetchCount(FetchDescriptor<WorkoutSet>()) == 11)
        #expect(vm.setsByDate.count == 10)
    }
}

@MainActor
private func makeContainer(url: URL? = nil, allowsSave: Bool = true) throws -> ModelContainer {
    let schema = Schema([Exercise.self, MuscleGroup.self, WorkoutSet.self, AppSettings.self,
                         CardioLog.self, GuideItem.self, MuscleGroupGuide.self])
    let configuration: ModelConfiguration
    if let url { configuration = ModelConfiguration(schema: schema, url: url, allowsSave: allowsSave) }
    else { configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true) }
    let container = try ModelContainer(for: schema, configurations: [configuration])
    container.mainContext.autosaveEnabled = false
    return container
}

private struct FixtureIDs {
    let exercise: UUID
    let group: UUID
    let guide: UUID
    let cardio: UUID
    let settings: UUID
    let orphan: UUID
    let sets: [UUID]
}

private let fixtureDate = Date(timeIntervalSince1970: 1_700_000_000)

@MainActor
private func insertFixture(context: ModelContext) throws -> FixtureIDs {
    let group = MuscleGroup(name: "Upper Body")
    group.createdDate = fixtureDate
    group.displayOrder = 7
    context.insert(group)
    let guide = GuideItem(name: "my warm-up", type: .warmup, duration: "45 sec",
                          instruction: "Keep this custom instruction", icon: "figure.flexibility", isCustom: true)
    context.insert(guide)
    let link = MuscleGroupGuide(displayOrder: 9, category: .warmup, guideItem: guide)
    context.insert(link)
    link.muscleGroup = group
    let cardio = CardioLog(type: "Cycle", duration: 1234, date: fixtureDate, distance: 2345.6, calories: 345.6)
    context.insert(cardio)
    let settings = AppSettings()
    settings.userName = "Jordan"
    settings.defaultTimerDuration = 135
    settings.maxStorageDays = 2
    context.insert(settings)
    let exercise = Exercise(name: "DB press", muscleGroupName: "upper body", defaultReps: 11,
                            defaultWeight: 12.5, videoUrl: "https://example.com/video", instructions: ["Custom instruction"])
    exercise.createdDate = fixtureDate
    exercise.lastModifiedDate = fixtureDate
    exercise.displayOrder = 8
    exercise.weightMin = 10
    exercise.weightMax = 150
    exercise.weightStep = 0 // An invalid legacy value must not crash or be silently rewritten.
    exercise.volumeImprovementPercent = 4.5
    context.insert(exercise)
    var sets: [WorkoutSet] = []
    for index in 0..<10 {
        let set = WorkoutSet(reps: index + 1, weight: Double(index) + 0.5,
                             date: fixtureDate.addingTimeInterval(Double(index) * -86_400))
        context.insert(set)
        set.exercise = exercise
        sets.append(set)
    }
    let orphan = WorkoutSet(reps: 13, weight: 42.5, date: fixtureDate)
    context.insert(orphan)
    try context.save()
    return FixtureIDs(exercise: exercise.id, group: group.id, guide: guide.id, cardio: cardio.id,
                      settings: settings.id, orphan: orphan.id, sets: sets.map(\.id))
}

@MainActor
private func createFixtureOnDisk(url: URL) throws -> FixtureIDs {
    try autoreleasepool {
        let container = try makeContainer(url: url)
        return try insertFixture(context: container.mainContext)
    }
}

@MainActor
private func prepareAndVerifyFixture(url: URL, ids: FixtureIDs) throws {
    try autoreleasepool {
        let container = try makeContainer(url: url)
        let context = container.mainContext
        try TrainingStore.prepare(context: context)
        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        #expect(exercises.count == 1)
        let exercise = try #require(exercises.first)
        #expect(exercise.id == ids.exercise)
        #expect(exercise.name == "DB press")
        #expect(exercise.muscleGroupName == "Upper Body")
        #expect(exercise.defaultReps == 11)
        #expect(exercise.defaultWeight == 12.5)
        #expect(exercise.createdDate == fixtureDate)
        #expect(exercise.lastModifiedDate == fixtureDate)
        #expect(exercise.displayOrder == 8)
        #expect(exercise.weightMin == 10 && exercise.weightMax == 150 && exercise.weightStep == 0)
        #expect(exercise.volumeImprovementPercent == 4.5)
        #expect(exercise.videoUrl == "https://example.com/video")
        #expect(exercise.instructions == ["Custom instruction"])
        #expect(exercise.cachedLastLogDate == fixtureDate)
        #expect(Set(exercise.sets.map(\.id)) == Set(ids.sets))
        for set in exercise.sets {
            let index = try #require(ids.sets.firstIndex(of: set.id))
            #expect(set.reps == index + 1)
            #expect(set.weight == Double(index) + 0.5)
            #expect(set.date == fixtureDate.addingTimeInterval(Double(index) * -86_400))
            #expect(set.exercise?.id == ids.exercise)
        }
        let allSets = try context.fetch(FetchDescriptor<WorkoutSet>())
        #expect(allSets.count == 11)
        let orphan = try #require(allSets.first { $0.id == ids.orphan })
        #expect(orphan.exercise == nil)
        #expect(orphan.reps == 13 && orphan.weight == 42.5 && orphan.date == fixtureDate)
        let group = try #require(context.fetch(FetchDescriptor<MuscleGroup>()).first)
        #expect(group.id == ids.group)
        #expect(group.name == "Upper Body")
        #expect(group.createdDate == fixtureDate)
        #expect(group.displayOrder == 7)
        #expect(group.guides.count == 1)
        let link = try #require(group.guides.first)
        #expect(link.displayOrder == 9 && link.category == "warmup")
        #expect(link.muscleGroup?.id == ids.group && link.guideItem?.id == ids.guide)
        let guide = try #require(context.fetch(FetchDescriptor<GuideItem>()).first)
        #expect(guide.id == ids.guide && guide.name == "my warm-up" && guide.type == "warmup")
        #expect(guide.duration == "45 sec" && guide.instruction == "Keep this custom instruction")
        #expect(guide.icon == "figure.flexibility" && guide.isCustom)
        let cardio = try #require(context.fetch(FetchDescriptor<CardioLog>()).first)
        #expect(cardio.id == ids.cardio && cardio.type == "Cycle" && cardio.duration == 1234)
        #expect(cardio.date == fixtureDate && cardio.distance == 2345.6 && cardio.calories == 345.6)
        let settings = try #require(context.fetch(FetchDescriptor<AppSettings>()).first)
        #expect(settings.id == ids.settings && settings.userName == "Jordan")
        #expect(settings.defaultTimerDuration == 135 && settings.maxStorageDays == 2)
    }
}
