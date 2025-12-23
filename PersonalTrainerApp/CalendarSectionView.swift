import SwiftUI
import SwiftData

struct CalendarSectionView: View {
    @Query private var sets: [WorkoutSet]
    @Query private var cardioLogs: [CardioLog]
    
    @State private var currentMonth = Date()
    @State private var selectedDate: Date?
    
    // Compute days with workouts
    var daysWithWorkouts: [Date: Set<String>] {
        var map: [Date: Set<String>] = [:]
        
        for set in sets {
            let date = Calendar.current.startOfDay(for: set.date)
            if map[date] == nil { map[date] = [] }
            map[date]?.insert("strength")
        }
        
        for log in cardioLogs {
            let date = Calendar.current.startOfDay(for: log.date)
            if map[date] == nil { map[date] = [] }
            map[date]?.insert("cardio")
        }
        
        return map
    }
    
    var monthlyStats: (strength: Int, cardio: Int) {
        let calendar = Calendar.current
        var strengthCount = 0
        var cardioCount = 0
        
        for (date, types) in daysWithWorkouts {
            if calendar.isDate(date, equalTo: currentMonth, toGranularity: .month) {
                if types.contains("strength") { strengthCount += 1 }
                if types.contains("cardio") { cardioCount += 1 }
            }
        }
        
        return (strengthCount, cardioCount)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .bottom) {
                Label("Activity", systemImage: "calendar")
                    .font(.title3.bold())
                
                Spacer()
                
                // Monthly Stats
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "dumbbell.fill")
                            .font(.caption2)
                        Text("\(monthlyStats.strength) days")
                            .font(.caption.bold())
                    }
                    .foregroundStyle(.red)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "figure.run")
                            .font(.caption2)
                        Text("\(monthlyStats.cardio) days")
                            .font(.caption.bold())
                    }
                    .foregroundStyle(.cyan)
                }
                .padding(.bottom, 2)
            }
            .padding(.horizontal)

            VStack(spacing: 0) {
                CalendarGrid(currentMonth: $currentMonth, selectedDate: $selectedDate, activityMap: daysWithWorkouts)
                    .padding()
                
                if let date = selectedDate {
                    Divider()
                        .padding(.horizontal)
                    
                    DailyLogView(date: date, sets: sets, cardioLogs: cardioLogs)
                        // Simple appear without "falling" animation
                        .transition(.opacity)
                }
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
        }
        // Keep the layout animation for smooth resizing, but it won't be "falling"
        .animation(.spring(response: 0.3, dampingFraction: 1), value: selectedDate)
    }
}

struct CalendarGrid: View {
    @Binding var currentMonth: Date
    @Binding var selectedDate: Date?
    let activityMap: [Date: Set<String>]
    
    let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        VStack {
            // Month Header
            HStack {
                Text(currentMonth.formatted(.dateTime.month().year()))
                    .font(.headline)
                Spacer()
                HStack(spacing: 20) {
                    Button(action: { changeMonth(by: -1) }) {
                        Image(systemName: "chevron.left")
                    }
                    Button(action: { changeMonth(by: 1) }) {
                        Image(systemName: "chevron.right")
                    }
                }
                .foregroundStyle(.secondary)
            }
            .padding(.bottom)
            
            // Days Header
            LazyVGrid(columns: columns) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Days Grid
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(daysInMonth(), id: \.self) { date in
                    if let date = date {
                        DayCell(date: date, activities: activityMap[date], isSelected: isSelected(date))
                            .onTapGesture {
                                if isSelected(date) {
                                    selectedDate = nil
                                } else {
                                    selectedDate = date
                                }
                            }
                    } else {
                        Text("")
                    }
                }
            }
        }
    }
    
    func isSelected(_ date: Date) -> Bool {
        guard let selected = selectedDate else { return false }
        return Calendar.current.isDate(date, inSameDayAs: selected)
    }
    
    func changeMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newDate
        }
    }
    
    func daysInMonth() -> [Date?] {
        guard let monthInterval = Calendar.current.dateInterval(of: .month, for: currentMonth),
              let monthFirstWeek = Calendar.current.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }
        
        let daysInMonth = Calendar.current.range(of: .day, in: .month, for: currentMonth)!.count
        let firstDayWeekday = Calendar.current.component(.weekday, from: monthInterval.start)
        
        // Calendar is 1-indexed (Sunday = 1)
        let offset = firstDayWeekday - 1
        
        var days: [Date?] = Array(repeating: nil, count: offset)
        
        for day in 1...daysInMonth {
            if let date = Calendar.current.date(byAdding: .day, value: day - 1, to: monthInterval.start) {
                days.append(date)
            }
        }
        
        return days
    }
}

struct DayCell: View {
    let date: Date
    let activities: Set<String>?
    let isSelected: Bool
    
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var body: some View {
        VStack {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.caption)
                .foregroundStyle(isToday ? .white : (isSelected ? .white : .primary))
                .frame(width: 30, height: 30)
                .background(
                    Group {
                        if isToday {
                            Circle().fill(Color.blue)
                        } else if isSelected {
                            Circle().fill(Color.primary.opacity(0.8))
                        }
                    }
                )
                .overlay(
                    HStack(spacing: 2) {
                        if !isSelected, let acts = activities {
                            if acts.contains("strength") {
                                Circle().fill(Color.red).frame(width: 4, height: 4)
                            }
                            if acts.contains("cardio") {
                                Circle().fill(Color.cyan).frame(width: 4, height: 4)
                            }
                        }
                    }
                    .offset(y: 12)
                )
        }
    }
}

struct DailyLogView: View {
    let date: Date
    let sets: [WorkoutSet]
    let cardioLogs: [CardioLog]
    
    var filteredSets: [WorkoutSet] {
        sets.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.date < $1.date }
    }
    
    var filteredCardio: [CardioLog] {
        cardioLogs.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.date < $1.date }
    }
    
    var setsByExercise: [String: [WorkoutSet]] {
        Dictionary(grouping: filteredSets) { $0.exercise?.name ?? "Unknown" }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(date.formatted(date: .complete, time: .omitted))
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            
            if filteredSets.isEmpty && filteredCardio.isEmpty {
                Text("No workouts recorded.")
                    .foregroundStyle(.secondary)
                    .italic()
                    .padding(.vertical)
            } else {
                if !filteredSets.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Strength", systemImage: "dumbbell.fill")
                            .font(.subheadline)
                            .foregroundStyle(.red)
                        
                        ForEach(setsByExercise.keys.sorted(), id: \.self) { exerciseName in
                            if let exerciseSets = setsByExercise[exerciseName] {
                                VStack(alignment: .leading, spacing: 4) {
                                    if let firstSet = exerciseSets.first, let exercise = firstSet.exercise {
                                        Text("\(exercise.muscleGroupName) - \(exerciseName)")
                                            .font(.system(.body, design: .rounded).weight(.medium))
                                    } else {
                                        Text(exerciseName)
                                            .font(.system(.body, design: .rounded).weight(.medium))
                                    }
                                    
                                    Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 4) {
                                        ForEach(exerciseSets) { set in
                                            GridRow {
                                                Text("\(set.reps) reps")
                                                    .gridColumnAlignment(.trailing)
                                                Text("×")
                                                    .foregroundStyle(.secondary)
                                                    .gridColumnAlignment(.center)
                                                Text("\(set.weight.formatted()) lbs")
                                                    .gridColumnAlignment(.leading)
                                            }
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(8)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
                
                if !filteredCardio.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Cardio", systemImage: "figure.run")
                            .font(.subheadline)
                            .foregroundStyle(.cyan)
                        
                        ForEach(filteredCardio) { log in
                            HStack {
                                Text(log.type)
                                    .font(.system(.body, design: .rounded).weight(.medium))
                                Spacer()
                                Text(formatDuration(log.duration))
                                    .font(.caption)
                                    .networkstyle()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
        }
        .padding()
        // Background moved to parent container for coherence
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? ""
    }
}

extension View {
    func networkstyle() -> some View {
        self.foregroundStyle(.secondary)
    }
}
