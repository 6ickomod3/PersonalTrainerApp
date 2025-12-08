import SwiftUI
import SwiftData

struct StrengthTrainingView: View {
    @Query(sort: \MuscleGroup.displayOrder) private var muscleGroups: [MuscleGroup]
    
    @Query private var allExercises: [Exercise]
    @Environment(TimerState.self) var timerState
    
    // Computed property to find the last logged exercise
    var lastLoggedExercise: Exercise? {
        // Filter exercises that have sets
        let activeExercises = allExercises.filter { !$0.sets.isEmpty }
        
        // Find the one with the most recent set date
        return activeExercises.sorted { ex1, ex2 in
            let date1 = ex1.sets.max(by: { $0.date < $1.date })?.date ?? Date.distantPast
            let date2 = ex2.sets.max(by: { $0.date < $1.date })?.date ?? Date.distantPast
            return date1 > date2
        }.first
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
                    .foregroundStyle(
                        LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                Spacer()
                // Could add a "Manage" button here later for reordering
            }
            .padding(.horizontal)
            
            // "Jump Back In" Shortcut
            if let lastExercise = lastLoggedExercise {
                NavigationLink(destination: ExerciseDetailView(exercise: lastExercise).environment(timerState)) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(Circle().fill(.orange.gradient))
                        
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
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .buttonStyle(.plain)
            }
 
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(muscleGroups) { group in
                    NavigationLink(value: group) {
                        MuscleGroupCard(group: group)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct MuscleGroupCard: View {
    let group: MuscleGroup
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .frame(height: 100)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(LinearGradient(colors: [.white.opacity(0.1), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                )
            
            // Content
            VStack(alignment: .leading) {
                Spacer()
                HStack {
                    Text(group.name)
                        .font(.headline)
                        .foregroundStyle(.red)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            
            // Decorative Icon (Subtle background)
            GeometryReader { geo in
                Image(systemName: iconForMuscle(group.name))
                    .font(.system(size: 60))
                    .foregroundStyle(LinearGradient(colors: [.orange.opacity(0.1), .red.opacity(0.05)], startPoint: .top, endPoint: .bottom))
                    .offset(x: geo.size.width - 40, y: -10)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    func iconForMuscle(_ name: String) -> String {
        switch name.lowercased() {
        case "chest": return "square.grid.2x2" // Placeholder, SF symbols limited for muscles
        case "back": return "figure.strengthtraining.traditional"
        case "leg": return "figure.run"
        case "shoulder": return "figure.arms.open"
        case "arm": return "arm" // Not real, fallback
        default: return "dumbbell"
        }
    }
}
