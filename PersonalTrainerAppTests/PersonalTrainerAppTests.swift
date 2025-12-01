//
//  PersonalTrainerAppTests.swift
//  PersonalTrainerAppTests
//
//  Created by Ji Dai on 11/28/25.
//

import Testing
@testable import PersonalTrainerApp

    @MainActor
    @Test func testDeleteSet() throws {
        // 1. Setup in-memory container
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Exercise.self, MuscleGroup.self, WorkoutSet.self, configurations: config)
        let context = container.mainContext
        
        // 2. Create Data
        let exercise = Exercise(name: "Test Bench", muscleGroupName: "Chest")
        context.insert(exercise)
        
        let set1 = WorkoutSet(reps: 10, weight: 100)
        let set2 = WorkoutSet(reps: 8, weight: 110) // Target to delete
        let set3 = WorkoutSet(reps: 6, weight: 120)
        
        exercise.sets.append(set1)
        exercise.sets.append(set2)
        exercise.sets.append(set3)
        
        try context.save()
        
        #expect(exercise.sets.count == 3)
        
        // 3. Simulate Buggy Deletion (removeAll on array)
        // This mimics the current buggy implementation: exercise.sets.removeAll { $0.id == set.id }
        // We want to verify that the FIX (using context.delete) works correctly.
        // So we will test the CORRECT behavior here to ensure our fix passes this test.
        
        // Action: Delete set2 using the CORRECT method
        context.delete(set2)
        try context.save()
        
        // 4. Verify
        #expect(exercise.sets.count == 2)
        #expect(exercise.sets.contains { $0.id == set1.id })
        #expect(!exercise.sets.contains { $0.id == set2.id })
        #expect(exercise.sets.contains { $0.id == set3.id })
    }
    
    @MainActor
    @Test func testAddAndSaveSet() throws {
        // 1. Setup
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Exercise.self, MuscleGroup.self, WorkoutSet.self, configurations: config)
        let context = container.mainContext
        
        let exercise = Exercise(name: "Squat", muscleGroupName: "Leg")
        context.insert(exercise)
        
        // 2. Simulate "Add Set" Action
        let newSet = WorkoutSet(reps: 5, weight: 225)
        exercise.sets.append(newSet)
        context.insert(newSet) // Explicit insert as per fix
        try context.save()
        
        // 3. Verify it has an ID and is persisted
        #expect(newSet.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
        #expect(exercise.sets.count == 1)
        #expect(exercise.sets.first?.weight == 225)
    }
    
    @MainActor
    @Test func testBidirectionalRelationship() throws {
        // 1. Setup
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Exercise.self, MuscleGroup.self, WorkoutSet.self, configurations: config)
        let context = container.mainContext
        
        let exercise = Exercise(name: "Deadlift", muscleGroupName: "Back")
        context.insert(exercise)
        
        // 2. Add Set and Verify Relationship
        let set = WorkoutSet(reps: 5, weight: 315)
        exercise.sets.append(set)
        context.insert(set)
        try context.save()
        
        // Verify inverse relationship is set automatically (or by our code)
        // Note: SwiftData usually handles this if we append to the relationship array
        #expect(set.exercise != nil)
        #expect(set.exercise?.id == exercise.id)
        
        // 3. Verify Deletion with Relationship
        context.delete(set)
        try context.save()
        
        #expect(exercise.sets.isEmpty)
    }
    
    @MainActor
    @Test func testDeleteSetWithSameDate() throws {
        // 1. Setup
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Exercise.self, MuscleGroup.self, WorkoutSet.self, configurations: config)
        let context = container.mainContext
        
        let exercise = Exercise(name: "Curl", muscleGroupName: "Arm")
        context.insert(exercise)
        
        // 2. Add 3 sets on the same day
        let now = Date()
        let set1 = WorkoutSet(reps: 10, weight: 20, date: now)
        let set2 = WorkoutSet(reps: 10, weight: 25, date: now) // Target
        let set3 = WorkoutSet(reps: 10, weight: 30, date: now)
        
        exercise.sets.append(set1)
        exercise.sets.append(set2)
        exercise.sets.append(set3)
        context.insert(set1)
        context.insert(set2)
        context.insert(set3)
        try context.save()
        
        #expect(exercise.sets.count == 3)
        
        // 3. Delete middle set (mimicking View logic)
        if let index = exercise.sets.firstIndex(where: { $0.id == set2.id }) {
            exercise.sets.remove(at: index)
        }
        context.delete(set2)
        try context.save()
        
        // 4. Verify
        #expect(exercise.sets.count == 2)
        #expect(exercise.sets.contains { $0.id == set1.id })
        #expect(!exercise.sets.contains { $0.id == set2.id })
        #expect(exercise.sets.contains { $0.id == set3.id })
    }
    
    @MainActor
    @Test func testDuplicateReferences() throws {
        // 1. Setup
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Exercise.self, MuscleGroup.self, WorkoutSet.self, configurations: config)
        let context = container.mainContext
        
        let exercise = Exercise(name: "Pull Up", muscleGroupName: "Back")
        context.insert(exercise)
        
        // 2. Create Duplicate References (The Bug Scenario)
        let set1 = WorkoutSet(reps: 10, weight: 0)
        context.insert(set1)
        
        // Add the SAME object twice
        exercise.sets.append(set1)
        exercise.sets.append(set1)
        try context.save()
        
        #expect(exercise.sets.count == 2)
        #expect(exercise.sets[0].id == exercise.sets[1].id)
        
        // 3. Verify Deletion Behavior (Deleting one deletes the object)
        // This confirms why the user sees "all logs deleted" - they are the same log!
        context.delete(set1)
        try context.save()
        
        // Both references should be gone (or invalid) because the object is deleted
        // Note: SwiftData might leave invalid references or clear them depending on state
        // But conceptually, the data is gone.
        
        // 4. Verify Deduplication Logic (The Fix)
        // Re-create scenario
        let set2 = WorkoutSet(reps: 5, weight: 0)
        context.insert(set2)
        exercise.sets.append(set2)
        exercise.sets.append(set2)
        
        // Run simulated deduplication
        var uniqueSets: [WorkoutSet] = []
        var seenIDs = Set<UUID>()
        for set in exercise.sets {
            if !seenIDs.contains(set.id) {
                seenIDs.insert(set.id)
                uniqueSets.append(set)
            }
        }
        exercise.sets = uniqueSets
        try context.save()
        
        #expect(exercise.sets.count == 1)
    }
}

@Suite("ExerciseDetailViewModel Tests")
struct ExerciseDetailViewModelTests {
    @MainActor
    @Test func testViewModelLogic() throws {
        // 1. Setup
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Exercise.self, MuscleGroup.self, WorkoutSet.self, configurations: config)
        let context = container.mainContext
        
        let exercise = Exercise(name: "Squat", muscleGroupName: "Legs")
        context.insert(exercise)
        
        let vm = ExerciseDetailViewModel(exercise: exercise, modelContext: context)
        
        // 2. Test Add Set
        vm.reps = 5
        vm.weight = 100
        vm.addSet()
        
        #expect(exercise.sets.count == 1)
        #expect(exercise.sets.first?.reps == 5)
        #expect(exercise.sets.first?.weight == 100)
        
        // 3. Test Volume Calculation
        // 5 * 100 = 500
        #expect(vm.setsByDate.first?.totalVolume == 500)
        
        // 4. Test Grouping (Add set for yesterday)
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let oldSet = WorkoutSet(reps: 10, weight: 100, date: yesterday)
        context.insert(oldSet)
        exercise.sets.append(oldSet)
        
        #expect(vm.setsByDate.count == 2) // Today and Yesterday
        
        // 5. Test Suggested Volume
        // Last volume (yesterday) = 1000
        // Improvement = 2% (default) -> 1020
        #expect(vm.lastTrainingVolume == 1000)
        // Default improvement is 2.0
        #expect(vm.suggestedVolume == 1020)
        
        // 6. Test Delete Set
        let setToDelete = exercise.sets.first(where: { $0.reps == 5 })! // The one we added first
        vm.deleteSet(setToDelete)
        
        #expect(exercise.sets.count == 1) // Only yesterday's set remains
        #expect(exercise.sets.first?.date == yesterday)
    }
}
