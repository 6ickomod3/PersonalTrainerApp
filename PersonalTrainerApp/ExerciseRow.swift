import SwiftUI

struct ExerciseRow: View {
    let exercise: Exercise
    let onRename: () -> Void
    let onDelete: () -> Void

    private var todaysSets: Int { exercise.sets.filter { Calendar.current.isDateInToday($0.date) }.count }

    var body: some View {
        HStack(spacing: 12) {
            NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                    if todaysSets > 0 {
                        Label("\(todaysSets) set\(todaysSets == 1 ? "" : "s") today", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(Theme.success)
                            .font(.caption)
                    } else if let date = exercise.lastLogDate {
                        Text("Last trained \(date.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Ready for your first set")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            .accessibilityIdentifier("ExerciseRow_\(exercise.name)")
            Menu {
                Button("Rename", systemImage: "pencil", action: onRename)
                Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
            } label: {
                Image(systemName: "ellipsis")
                    .frame(minWidth: 44, minHeight: 44)
            }
            .accessibilityLabel("Manage \(exercise.name)")
        }
    }
}
