//
//  PersonalTrainerAppRestTimerWidgetLiveActivity.swift
//  PersonalTrainerAppRestTimerWidget
//
//  Created for PersonalTrainerApp
//

import ActivityKit
import WidgetKit
import SwiftUI

struct PersonalTrainerAppRestTimerWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerAttributes.self) { context in
            // Lock Screen / Banner UI
            VStack {
                HStack {
                    Image(systemName: "timer")
                        .foregroundStyle(.blue)
                    Text("Rest Timer")
                        .font(.headline)
                    Spacer()
                    // Countdown timer
                    if context.state.endTime > Date() {
                        Text(timerInterval: Date()...context.state.endTime, countsDown: true)
                            .monospacedDigit()
                            .font(.title2)
                            .foregroundStyle(.blue)
                    } else {
                        Text("0:00")
                            .monospacedDigit()
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                }
                .padding()
            }
            .activityBackgroundTint(Color.black.opacity(0.8))
            .activitySystemActionForegroundColor(Color.white)
            
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "timer")
                        .foregroundStyle(.blue)
                        .padding(.leading)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.endTime > Date() {
                        Text(timerInterval: Date()...context.state.endTime, countsDown: true)
                            .monospacedDigit()
                            .foregroundStyle(.blue)
                            .padding(.trailing)
                    } else {
                        Text("0:00")
                            .monospacedDigit()
                            .foregroundStyle(.blue)
                            .padding(.trailing)
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    Text("Resting")
                        .font(.caption)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    // Optional: Add controls or progress bar here
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .foregroundStyle(.blue)
            } compactTrailing: {
                if context.state.endTime > Date() {
                    Text(timerInterval: Date()...context.state.endTime, countsDown: true)
                        .monospacedDigit()
                        .frame(width: 40)
                        .foregroundStyle(.blue)
                } else {
                    Text("0:00")
                        .monospacedDigit()
                        .frame(width: 40)
                        .foregroundStyle(.blue)
                }
            } minimal: {
                Image(systemName: "timer")
                    .foregroundStyle(.blue)
            }
        }
    }
}

// Preview helper
#Preview("Notification", as: .content, using: TimerAttributes(timerName: "Test")) {
   PersonalTrainerAppRestTimerWidgetLiveActivity()
} contentStates: {
    TimerAttributes.ContentState(endTime: Date().addingTimeInterval(60), duration: 60)
}
