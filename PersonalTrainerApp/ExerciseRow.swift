import SwiftUI

/// Row view for exercises in the exercise list with daily completion status
struct ExerciseRow: View {
    let exercise: Exercise
    let onRename: () -> Void
    let onDelete: () -> Void
    @Environment(TimerState.self) var timerState
    
    var body: some View {
        NavigationLink(destination: ExerciseDetailView(exercise: exercise).environment(timerState)) {
            HStack {
                // Leading Status Icon (Read-only)
                Image(systemName: isLoggedToday ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isLoggedToday ? Theme.success : Theme.inactive)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.body.weight(.medium))
                        .foregroundStyle(Theme.accent)
                    
                    // Subtitle: Suggested Volume to match height
                    Group {
                         if let suggested = exercise.suggestedVolume {
                             Text("Target Volume: \(Int(suggested)) lbs")
                         } else {
                             Text("Start logging to see targets")
                         }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
        }
    }
    
    private var isLoggedToday: Bool {
        guard let lastDate = exercise.lastLogDate else { return false }
        return Calendar.current.isDateInToday(lastDate)
    }
}
