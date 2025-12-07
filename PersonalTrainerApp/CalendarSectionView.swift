import SwiftUI
import SwiftData

struct CalendarSectionView: View {
    @Query private var sets: [WorkoutSet]
    @Query private var cardioLogs: [CardioLog]
    
    @State private var currentMonth = Date()
    
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
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Label("Activity", systemImage: "calendar")
                    .font(.title3.bold())
                Spacer()
            }
            .padding(.horizontal)

            CalendarGrid(currentMonth: $currentMonth, activityMap: daysWithWorkouts)
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
        }
    }
}

struct CalendarGrid: View {
    @Binding var currentMonth: Date
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
                        DayCell(date: date, activities: activityMap[date])
                    } else {
                        Text("")
                    }
                }
            }
        }
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
    
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var body: some View {
        VStack {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.caption)
                .foregroundStyle(isToday ? .white : .primary)
                .frame(width: 30, height: 30)
                .background(isToday ? Circle().fill(Color.blue) : nil)
                .overlay(
                    HStack(spacing: 2) {
                        if let acts = activities {
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
