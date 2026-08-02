import SwiftUI
import SwiftData

struct StrengthTrainingView: View {
    @Query(sort: \MuscleGroup.displayOrder) private var muscleGroups: [MuscleGroup]
    
    @Query private var allExercises: [Exercise]

    @Environment(\.modelContext) private var modelContext
    @State private var muscleGroupToDelete: MuscleGroup?
    @State private var jumpBackCount = 0
    @Binding var path: NavigationPath // Receive Path
    
    // Computed property to find the last logged exercise (O(n) via cached date)
    var lastLoggedExercise: Exercise? {
        allExercises
            .compactMap { ex -> (Exercise, Date)? in
                guard let date = ex.lastLogDate else { return nil }
                return (ex, date)
            }
            .max(by: { $0.1 < $1.1 })?
            .0
    }

    /// Exercises grouped by muscle group name, for the card metadata lookup.
    private var exercisesByGroup: [String: [Exercise]] {
        Dictionary(grouping: allExercises, by: \.muscleGroupName)
    }
    
    // Grid layout
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            HStack {
                Label("Strength", systemImage: "dumbbell.fill")
                    .font(.title3.bold())
                    .foregroundStyle(Theme.accentGradient)
                Spacer()
            }
            .padding(.horizontal)
            
            // "Jump Back In" Shortcut
            if let lastExercise = lastLoggedExercise {
                Button(action: {
                    jumpBackIn(for: lastExercise)
                    jumpBackCount += 1
                }) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(Circle().fill(Theme.accent.gradient))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Jump Back In")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        
                            Text(lastExercise.name)
                                .font(.headline)
                                .foregroundStyle(.primary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .themeCard(radius: Theme.innerRadius)
                    .padding(.horizontal)
                }
                .buttonStyle(.plain)
            }
 
            if muscleGroups.isEmpty {
                EmptyStateView(
                    systemImage: "dumbbell",
                    title: "No muscle groups yet",
                    subtitle: "Add a group to start tracking strength workouts."
                )
                .padding(.horizontal)
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(muscleGroups) { group in
                        NavigationLink(value: group) {
                            MuscleGroupCard(
                                group: group,
                                exercises: exercisesByGroup[group.name] ?? []
                            )
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                muscleGroupToDelete = group
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .sensoryFeedback(.selection, trigger: jumpBackCount)
        .alert("Delete Muscle Group?", isPresented: Binding(
            get: { muscleGroupToDelete != nil },
            set: { if !$0 { muscleGroupToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let group = muscleGroupToDelete {
                    deleteMuscleGroup(group)
                }
            }
        } message: {
             if let group = muscleGroupToDelete {
                 Text("Are you sure you want to delete '\(group.name)'? This will delete all associated exercises and logs.")
             }
        }
    }
    
    private func jumpBackIn(for exercise: Exercise) {
        // Find the Muscle Group for this exercise
        if let group = muscleGroups.first(where: { $0.name == exercise.muscleGroupName }) {
            // Push Muscle Group First
            path.append(group)
            // Push Exercise Second
            path.append(exercise)
        } else {
            // Fallback if group not found (shouldn't happen usually)
            path.append(exercise)
        }
    }
    
    private func deleteMuscleGroup(_ group: MuscleGroup) {
        // Delete all exercises associated with this group
        // Note: Cascaade delete might be handled by SwiftData if configured, but manual safety is good
        // Finding exercises for this group
        let groupExercises = allExercises.filter { $0.muscleGroupName == group.name }
        for exercise in groupExercises {
            modelContext.delete(exercise)
        }
        
        modelContext.delete(group)
        modelContext.safeSave()
        muscleGroupToDelete = nil
    }
}

struct MuscleGroupCard: View {
    let group: MuscleGroup
    let exercises: [Exercise]

    private var iconName: String {
        switch group.name.lowercased() {
        case "chest":                   return "figure.arms.open"
        case "back":                    return "figure.cooldown"
        case "leg", "legs":             return "figure.walk"
        case "shoulder", "shoulders":   return "figure.boxing"
        case "arm", "arms":             return "dumbbell.fill"
        case "core", "abs":             return "figure.core.training"
        default:                        return "dumbbell.fill"
        }
    }

    private var groupLastLogDate: Date? {
        exercises.compactMap(\.lastLogDate).max()
    }

    private var lastTrainedLabel: String? {
        guard let date = groupLastLogDate else { return nil }
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Trained today" }
        if calendar.isDateInYesterday(date) { return "Trained yesterday" }
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: calendar.startOfDay(for: Date())).day ?? 0
        if days < 7 { return "Trained \(days)d ago" }
        let weeks = days / 7
        if weeks < 5 { return "Trained \(weeks)w ago" }
        return "Trained 1mo+ ago"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Image(systemName: iconName)
                    .font(.title3)
                    .foregroundStyle(Theme.accent)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(Theme.muted)
            }

            Spacer(minLength: 0)

            Text(group.name)
                .font(.headline)
                .foregroundStyle(Theme.accent)

            HStack(spacing: 6) {
                Text("\(exercises.count) exercise\(exercises.count == 1 ? "" : "s")")
                    .font(.caption2.weight(.medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Theme.accent.opacity(0.15)))
                    .foregroundStyle(Theme.accent)

                if let label = lastTrainedLabel {
                    Text(label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
        }
        .padding(Theme.cardPadding)
        .frame(height: 110, alignment: .topLeading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .themeCard()
    }
}
