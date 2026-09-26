import SwiftUI
import SwiftData

/// Calendar arithmetic shared by the grid and locale regression tests.
enum TrainingCalendar {
    static func days(in month: Date, calendar: Calendar = .current) -> [Date?] {
        guard let interval = calendar.dateInterval(of: .month, for: month),
              let range = calendar.range(of: .day, in: .month, for: month) else { return [] }
        let weekday = calendar.component(.weekday, from: interval.start)
        let offset = (weekday - calendar.firstWeekday + 7) % 7
        return Array(repeating: nil, count: offset) + range.map {
            calendar.date(byAdding: .day, value: $0 - 1, to: interval.start)
        }
    }
}

struct CalendarSectionView: View {
    @Query(sort: \WorkoutSet.date, order: .reverse) private var sets: [WorkoutSet]
    @State private var currentMonth = Date()
    @State private var selectedDate = Date()

    private var trainingDays: Set<Date> {
        Set(sets.map { Calendar.current.startOfDay(for: $0.date) })
    }

    private var monthCount: Int {
        trainingDays.filter { Calendar.current.isDate($0, equalTo: currentMonth, toGranularity: .month) }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.sectionSpacing) {
            Text("\(monthCount) strength training day\(monthCount == 1 ? "" : "s") this month")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("StrengthHistorySummary")
            CalendarGrid(currentMonth: $currentMonth, selectedDate: $selectedDate, trainingDays: trainingDays)
                .padding(12)
                .themeCard()
            DailyLogView(date: selectedDate, sets: sets)
        }
        .padding(.horizontal)
        .sensoryFeedback(.selection, trigger: selectedDate)
    }
}

struct CalendarGrid: View {
    @Binding var currentMonth: Date
    @Binding var selectedDate: Date
    let trainingDays: Set<Date>
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    private var weekdaySymbols: [String] {
        let symbols = Calendar.current.veryShortStandaloneWeekdaySymbols
        let first = Calendar.current.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(currentMonth.formatted(.dateTime.month().year())).font(.headline)
                Spacer(minLength: 0)
                Button("Previous month", systemImage: "chevron.left") { changeMonth(-1) }
                    .labelStyle(.iconOnly).frame(minWidth: 44, minHeight: 44)
                Button("Next month", systemImage: "chevron.right") { changeMonth(1) }
                    .labelStyle(.iconOnly).frame(minWidth: 44, minHeight: 44)
            }
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol).font(.caption).foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
                ForEach(Array(TrainingCalendar.days(in: currentMonth).enumerated()), id: \.offset) { _, date in
                    if let date {
                        let selected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                        let trained = trainingDays.contains(date)
                        Button { selectedDate = date } label: {
                            VStack(spacing: 3) {
                                Text("\(Calendar.current.component(.day, from: date))")
                                    .font(.callout)
                                    .fontWeight(Calendar.current.isDateInToday(date) ? .bold : .regular)
                                Circle()
                                    .fill(trained ? (selected ? Color.white : Theme.accent) : .clear)
                                    .frame(width: 5, height: 5)
                            }
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .foregroundStyle(selected ? Color.white : .primary)
                            .background(selected ? Theme.primaryAction : Color.clear, in: RoundedRectangle(cornerRadius: 10))
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(date.formatted(date: .complete, time: .omitted))
                        .accessibilityValue(trained ? "Strength training recorded" : "No training recorded")
                        .accessibilityAddTraits(selected ? [.isSelected] : [])
                    } else {
                        Color.clear.frame(height: 44).accessibilityHidden(true)
                    }
                }
            }
            Button("Today") {
                currentMonth = Date()
                selectedDate = Date()
            }
            .frame(minHeight: 44)
        }
    }

    private func changeMonth(_ value: Int) {
        guard let start = Calendar.current.dateInterval(of: .month, for: currentMonth)?.start,
              let next = Calendar.current.date(byAdding: .month, value: value, to: start) else { return }
        currentMonth = next
        selectedDate = next
    }
}

struct DailyLogView: View {
    @Environment(\.modelContext) private var modelContext
    let date: Date
    let sets: [WorkoutSet]
    @State private var editingSet: WorkoutSet?

    private var filteredSets: [WorkoutSet] {
        sets.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }.sorted { $0.date < $1.date }
    }

    private var groups: [[WorkoutSet]] {
        Dictionary(grouping: filteredSets, by: { $0.exercise?.persistentModelID }).values.sorted {
            let left = $0.first?.exercise?.name ?? "Unassigned history"
            let right = $1.first?.exercise?.name ?? "Unassigned history"
            return left.localizedStandardCompare(right) == .orderedAscending
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(date.formatted(.dateTime.weekday(.wide).month().day())).font(.headline)
            if filteredSets.isEmpty {
                ContentUnavailableView("No sets recorded", systemImage: "dumbbell", description: Text("Your strength training for this day will appear here."))
            } else {
                ForEach(groups, id: \.first!.id) { group in
                    VStack(alignment: .leading, spacing: 12) {
                        if let exercise = group.first?.exercise {
                            NavigationLink(value: exercise) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(exercise.name).font(.headline).foregroundStyle(.primary)
                                        Text(exercise.muscleGroupName).font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").font(.caption)
                                }
                            }
                            .buttonStyle(.plain)
                        } else {
                            Text("Unassigned history").font(.headline)
                            Text("These older sets are preserved, but their original exercise is no longer linked.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        ForEach(group) { set in
                            Button { editingSet = set } label: {
                                HStack {
                                    Text("\(set.reps) × \(set.weight.formatted()) lbs")
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Text(set.date, style: .time).font(.caption).foregroundStyle(.secondary)
                                    Image(systemName: "pencil").font(.caption)
                                }
                                .frame(minHeight: 44)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Edit set: \(set.reps) repetitions, \(set.weight.formatted()) pounds")
                            .accessibilityIdentifier("HistorySetRow")
                        }
                    }
                    .padding()
                    .themeCard()
                }
            }
        }
        .sheet(item: $editingSet) { set in
            WorkoutSetEditor(set: set) { reps, weight, date in
                set.reps = reps
                set.weight = weight
                set.date = date
                set.exercise?.refreshCachedLastLogDate()
                do {
                    try modelContext.save()
                    return true
                } catch {
                    modelContext.rollback()
                    modelContext.processPendingChanges()
                    return false
                }
            }
        }
    }
}
