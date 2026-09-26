//
//  PersonalTrainerAppApp.swift
//  PersonalTrainerApp
//
//  Created by Ji Dai on 11/28/25.
//

import SwiftUI
import SwiftData

@main
struct PersonalTrainerAppApp: App {
    private var usesEphemeralStore: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("--ui-testing")
        #else
        false
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(Theme.accent)
        }
        // Keep the original schema, including retired features, for existing stores.
        .modelContainer(for: [Exercise.self, MuscleGroup.self, WorkoutSet.self, AppSettings.self, CardioLog.self, GuideItem.self, MuscleGroupGuide.self], inMemory: usesEphemeralStore)
    }
}
