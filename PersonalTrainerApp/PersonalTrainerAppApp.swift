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
    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(Theme.accent)
        }
        .modelContainer(for: [Exercise.self, MuscleGroup.self, WorkoutSet.self, AppSettings.self, CardioLog.self, GuideItem.self, MuscleGroupGuide.self])
    }
}
