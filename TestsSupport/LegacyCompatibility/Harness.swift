import Foundation
import SwiftData

@main
struct CompatibilityHarness {
    @MainActor static func main() throws {
        guard CommandLine.arguments.count == 2 else { fatalError("Pass the temporary fixture directory") }
        let folder = URL(fileURLWithPath: CommandLine.arguments[1])
        let schema = Schema([Exercise.self, MuscleGroup.self, WorkoutSet.self, AppSettings.self,
                             CardioLog.self, GuideItem.self, MuscleGroupGuide.self])
        let config = ModelConfiguration(schema: schema, url: folder.appendingPathComponent("legacy.store"))
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext
        context.autosaveEnabled = false
        #if LEGACY
        let exerciseCount = try context.fetchCount(FetchDescriptor<Exercise>())
        precondition(exerciseCount == 0)
        let date = Date(timeIntervalSince1970: 1700000000)
        let group = MuscleGroup(name: "Custom Upper BODY")
        group.displayOrder = 7
        context.insert(group)
        for (index,type) in [GuideType.warmup, .cooldown].enumerated() {
            let guide = GuideItem(name: "Custom \(type.rawValue)", type: type, duration: "45 sec", instruction: "Keep original instructions", icon: "figure.flexibility", isCustom: true)
            context.insert(guide)
            let link = MuscleGroupGuide(displayOrder: index + 3, category: index == 0 ? .warmup : .stretch, guideItem: guide)
            context.insert(link)
            link.muscleGroup = group
        }
        let exercise = Exercise(name: "DB press", muscleGroupName: group.name, defaultReps: 11, defaultWeight: 12.5, videoUrl: "https://example.com/custom", instructions: ["Keep", "these"])
        exercise.weightMin = 10
        exercise.weightMax = 150
        exercise.weightStep = 0
        exercise.displayOrder = 8
        exercise.volumeImprovementPercent = 4.5
        exercise.createdDate = date
        exercise.lastModifiedDate = date
        exercise.cachedLastLogDate = date
        context.insert(exercise)
        for index in 0..<10 {
            let set = WorkoutSet(reps: index + 1, weight: Double(index) + 0.5, date: date.addingTimeInterval(Double(-index) * 86400))
            context.insert(set)
            set.exercise = exercise
        }
        context.insert(WorkoutSet(reps: 13, weight: 42.5, date: date))
        context.insert(CardioLog(type: "Cycle", duration: 1234, date: date, distance: 2345.6, calories: 345.6))
        let settings = AppSettings()
        settings.defaultTimerDuration = 135
        settings.userName = "Jordan"
        settings.maxStorageDays = 2
        context.insert(settings)
        try context.save()
        let data = try JSONSerialization.data(withJSONObject: snapshot(context), options: [.sortedKeys, .prettyPrinted])
        try data.write(to: folder.appendingPathComponent("expected.json"))
        print("PASS: old HEAD models wrote complete legacy store")
        #else
        try TrainingStore.prepare(context: context)
        let expected = try Data(contentsOf: folder.appendingPathComponent("expected.json"))
        let actual = try JSONSerialization.data(withJSONObject: snapshot(context), options: [.sortedKeys, .prettyPrinted])
        guard actual == expected else {
            try actual.write(to: folder.appendingPathComponent("actual.json"))
            fatalError("Legacy store changed unexpectedly")
        }
        print("PASS: new code opened, prepared, saved and preserved all legacy IDs, fields and relationships")
        #endif
    }

    @MainActor static func snapshot(_ context: ModelContext) throws -> [String: [[String: String]]] {
        func sorted(_ items: [[String:String]]) -> [[String:String]] { items.sorted { ($0["id"] ?? $0["guide"] ?? "") < ($1["id"] ?? $1["guide"] ?? "") } }
        return [
            "groups": sorted(try context.fetch(FetchDescriptor<MuscleGroup>()).map { ["id": $0.id.uuidString, "name": $0.name, "date": String($0.createdDate.timeIntervalSince1970), "order": String($0.displayOrder), "guides": $0.guides.compactMap { $0.guideItem?.id.uuidString }.sorted().joined(separator: ",")] }),
            "exercises": sorted(try context.fetch(FetchDescriptor<Exercise>()).map { e in
                ["id": e.id.uuidString, "name": e.name, "group": e.muscleGroupName, "reps": String(e.defaultReps), "weight": String(e.defaultWeight), "created": String(e.createdDate!.timeIntervalSince1970), "modified": String(e.lastModifiedDate!.timeIntervalSince1970), "order": String(e.displayOrder), "min": String(e.weightMin), "max": String(e.weightMax), "step": String(e.weightStep), "improvement": String(e.volumeImprovementPercent), "video": e.videoUrl ?? "nil", "instructions": e.instructions.joined(separator: ","), "cached": String(e.cachedLastLogDate!.timeIntervalSince1970), "sets": e.sets.map { $0.id.uuidString }.sorted().joined(separator: ",")]
            }),
            "sets": sorted(try context.fetch(FetchDescriptor<WorkoutSet>()).map { ["id": $0.id.uuidString, "reps": String($0.reps), "weight": String($0.weight), "date": String($0.date.timeIntervalSince1970), "exercise": $0.exercise?.id.uuidString ?? "nil"] }),
            "guides": sorted(try context.fetch(FetchDescriptor<GuideItem>()).map { ["id": $0.id.uuidString, "name": $0.name, "type": $0.type, "duration": $0.duration, "instruction": $0.instruction, "icon": $0.icon, "custom": String($0.isCustom)] }),
            "links": sorted(try context.fetch(FetchDescriptor<MuscleGroupGuide>()).map { ["order": String($0.displayOrder), "category": $0.category, "guide": $0.guideItem?.id.uuidString ?? "nil", "group": $0.muscleGroup?.id.uuidString ?? "nil"] }),
            "cardio": sorted(try context.fetch(FetchDescriptor<CardioLog>()).map { ["id": $0.id.uuidString, "type": $0.type, "duration": String($0.duration), "date": String($0.date.timeIntervalSince1970), "distance": String($0.distance ?? -1), "calories": String($0.calories ?? -1)] }),
            "settings": sorted(try context.fetch(FetchDescriptor<AppSettings>()).map { ["id": $0.id.uuidString, "days": String($0.maxStorageDays), "timer": String($0.defaultTimerDuration), "name": $0.userName] })
        ]
    }
}
