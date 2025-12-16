import SwiftUI
import SwiftData

struct CardioSectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CardioLog.date, order: .reverse) private var recentCardio: [CardioLog]
    @State private var showingAddCardio = false
    
    // Cardio Types
    let cardioTypes = ["Run", "Cycle", "Walk", "Swim", "HIIT", "Rowing"]
    
    var todaysLogs: [CardioLog] {
        recentCardio.filter { Calendar.current.isDateInToday($0.date) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Label("Cardio", systemImage: "figure.run")
                    .font(.title3.bold())
                    .foregroundStyle(.cyan)
                
                Spacer()
                
                Button(action: { showingAddCardio = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.cyan)
                }
            }
            .padding(.horizontal)
            
            // Content Card
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(LinearGradient(colors: [.cyan.opacity(0.3), .blue.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                    )
                
                if todaysLogs.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "heart.text.square")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No cardio logs today")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Button("Log Run") {
                            addQuickLog(type: "Run", minutes: 30)
                        }
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.cyan.opacity(0.2)))
                        .foregroundStyle(.cyan)
                    }
                    .padding()
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(todaysLogs) { log in
                                CardioLogCell(log: log)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            deleteLog(log)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }
                }
            }
            .frame(height: 140)
            .padding(.horizontal)
        }
        .sheet(isPresented: $showingAddCardio) {
            AddCardioSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
    
    func addQuickLog(type: String, minutes: Double) {
        let newLog = CardioLog(type: type, duration: minutes * 60)
        modelContext.insert(newLog)
    }
    
    func deleteLog(_ log: CardioLog) {
        modelContext.delete(log)
    }
}

struct CardioLogCell: View {
    let log: CardioLog
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: iconForType(log.type))
                Spacer()
                Text(log.date.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .font(.caption)
            .foregroundStyle(.cyan)
            
            Text(log.type)
                .font(.headline)
                .foregroundStyle(.primary)
            
            Text(formatDuration(log.duration))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())
        }
        .padding(10)
        .frame(width: 110, height: 90)
        .background(Color.black.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        )
    }
    
    func iconForType(_ type: String) -> String {
        switch type {
        case "Run": return "figure.run"
        case "Cycle": return "bicycle"
        case "Walk": return "figure.walk"
        case "Swim": return "figure.pool.swim"
        default: return "heart.fill"
        }
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        return "\(minutes) min"
    }
}

struct AddCardioSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    @State private var selectedType = "Run"
    @State private var durationMinutes: Double = 30
    @State private var date = Date()
    
    let types = ["Run", "Cycle", "Walk", "Swim", "HIIT", "Rowing", "Elliptical", "Stairmaster"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $selectedType) {
                        ForEach(types, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(.menu) // or navigation link for more options
                    
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section("Duration") {
                    HStack {
                        Text("\(Int(durationMinutes)) min")
                            .frame(width: 60, alignment: .leading)
                        Slider(value: $durationMinutes, in: 5...180, step: 5)
                    }
                }
            }
            .navigationTitle("Log Cardio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let newLog = CardioLog(type: selectedType, duration: durationMinutes * 60, date: date)
                        modelContext.insert(newLog)
                        dismiss()
                    }
                }
            }
        }
    }
}
