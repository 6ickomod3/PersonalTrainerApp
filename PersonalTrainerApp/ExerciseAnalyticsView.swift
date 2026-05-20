import SwiftUI
import Charts
import SwiftData

struct ExerciseAnalyticsView: View {
    let exercise: Exercise
    
    // Data Structure for Charts
    struct DailyStats: Identifiable {
        let id = UUID()
        let date: Date
        let totalVolume: Double
        let maxWeight: Double
    }
    
    // Computed property to get the last 7 logged days
    var recentStats: [DailyStats] {
        let calendar = Calendar.current
        
        // 1. Group sets by day
        let groupedSets = Dictionary(grouping: exercise.sets) { set in
            calendar.startOfDay(for: set.date)
        }
        
        // 2. Calculate stats for each day
        let stats = groupedSets.map { (date, sets) -> DailyStats in
            let totalVol = sets.reduce(0) { $0 + $1.volume }
            let maxW = sets.map(\.weight).max() ?? 0.0
            return DailyStats(date: date, totalVolume: totalVol, maxWeight: maxW)
        }
        
        // 3. Sort by date and take last 7
        let sortedStats = stats.sorted { $0.date < $1.date }
        return Array(sortedStats.suffix(7))
    }
    
    var body: some View {
        if !recentStats.isEmpty {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                Label("Progress Trends", systemImage: "chart.xyaxis.line")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                // 1. Volume Chart
                VStack(alignment: .leading, spacing: 8) {
                    Text("Total Volume (lbs)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Chart {
                        ForEach(Array(recentStats.enumerated()), id: \.element.id) { index, stat in
                            // Right-align data: map index 0..<count to (7-count)..<7
                            let offset = 7 - recentStats.count
                            let xValue = offset + index
                            
                            LineMark(
                                x: .value("Index", xValue),
                                y: .value("Volume", stat.totalVolume)
                            )
                            .foregroundStyle(Theme.highlight.gradient)
                            .interpolationMethod(.catmullRom)
                            
                            AreaMark(
                                x: .value("Index", xValue),
                                y: .value("Volume", stat.totalVolume)
                            )
                            .foregroundStyle(Theme.highlight.opacity(0.1).gradient)
                            .interpolationMethod(.catmullRom)
                        }
                    }
                    .chartXScale(domain: 0...6)
                    .chartXAxis(.hidden)
                    .frame(height: 150)
                }
                .padding()
                .background(Theme.innerCardBackground)
                .cornerRadius(Theme.innerRadius)
                
                // 2. Max Weight Chart
                VStack(alignment: .leading, spacing: 8) {
                    Text("Max Weight (lbs)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Chart {
                        ForEach(Array(recentStats.enumerated()), id: \.element.id) { index, stat in
                            let offset = 7 - recentStats.count
                            let xValue = offset + index
                            
                            LineMark(
                                x: .value("Index", xValue),
                                y: .value("Weight", stat.maxWeight)
                            )
                            .foregroundStyle(Theme.accent.gradient)
                            .interpolationMethod(.catmullRom)
                            
                            PointMark(
                                x: .value("Index", xValue),
                                y: .value("Weight", stat.maxWeight)
                            )
                            .foregroundStyle(Theme.accent)
                        }
                    }
                    .chartXScale(domain: 0...6)
                    .chartXAxis(.hidden)
                    .frame(height: 150)
                }
                .padding()
                .background(Theme.innerCardBackground)
                .cornerRadius(Theme.innerRadius)
            }
        } else {
            // Not enough data for a chart, but show something
             VStack(alignment: .leading, spacing: 8) {
                 Label("Progress Trends", systemImage: "chart.xyaxis.line")
                     .font(.headline)
                 
                 Text("Log more workouts to see your progress charts!")
                     .font(.subheadline)
                     .foregroundStyle(.secondary)
                     .frame(maxWidth: .infinity, alignment: .center)
                     .padding()
                     .background(Theme.innerCardBackground)
                     .cornerRadius(Theme.innerRadius)
             }
        }
    }
}
