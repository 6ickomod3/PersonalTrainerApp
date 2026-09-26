import SwiftUI
import Charts

struct ExerciseAnalyticsView: View {
    let exercise: Exercise

    struct DailyStats: Identifiable {
        var id: Date { date }
        let date: Date
        let totalVolume: Double
        let maxWeight: Double
    }

    private var recentStats: [DailyStats] {
        let grouped = Dictionary(grouping: exercise.sets) { Calendar.current.startOfDay(for: $0.date) }
        let stats = grouped.map { date, sets in
            DailyStats(date: date, totalVolume: sets.reduce(0) { $0 + $1.volume }, maxWeight: sets.map(\.weight).max() ?? 0)
        }
        return Array(stats.sorted { $0.date < $1.date }.suffix(7))
    }

    var body: some View {
        let stats = recentStats
        List {
            if stats.isEmpty {
                ContentUnavailableView("No progress yet", systemImage: "chart.xyaxis.line", description: Text("Log a set to start tracking your training."))
            } else {
                if let target = exercise.suggestedVolume {
                    Section {
                        LabeledContent("Suggested volume", value: "\(target.formatted(.number.precision(.fractionLength(0...1)))) lbs")
                    } footer: {
                        Text("Previous training volume plus \(exercise.volumeImprovementPercent.formatted(.number.precision(.fractionLength(0...1))))%. Volume is reps × weight summed across sets.")
                    }
                }
                Section("Volume (lbs)") {
                    Chart(stats) { stat in
                        LineMark(x: .value("Date", stat.date), y: .value("Volume", stat.totalVolume))
                            .foregroundStyle(Theme.dataHighlight)
                        PointMark(x: .value("Date", stat.date), y: .value("Volume", stat.totalVolume))
                            .foregroundStyle(Theme.dataHighlight)
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 4)) {
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        }
                    }
                    .frame(height: 180)
                    .padding(.vertical, 8)
                    .accessibilityLabel("Training volume by date")
                }
                Section("Heaviest set (lbs)") {
                    Chart(stats) { stat in
                        LineMark(x: .value("Date", stat.date), y: .value("Weight", stat.maxWeight))
                            .foregroundStyle(Theme.accent)
                        PointMark(x: .value("Date", stat.date), y: .value("Weight", stat.maxWeight))
                            .foregroundStyle(Theme.accent)
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 4)) {
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        }
                    }
                    .frame(height: 180)
                    .padding(.vertical, 8)
                    .accessibilityLabel("Heaviest set by date")
                }
                Section("Last \(stats.count) training day\(stats.count == 1 ? "" : "s")") {
                    ForEach(stats.reversed()) { stat in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(stat.date, format: .dateTime.month(.abbreviated).day().year())
                                .font(.subheadline.weight(.semibold))
                            Text("Volume: \(stat.totalVolume.formatted(.number.precision(.fractionLength(0...1)))) lbs · Heaviest: \(stat.maxWeight.formatted(.number.precision(.fractionLength(0...3)))) lbs")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
        .navigationTitle("Progress")
        .navigationBarTitleDisplayMode(.inline)
    }
}
