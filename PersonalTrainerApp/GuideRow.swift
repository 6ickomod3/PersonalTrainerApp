import SwiftUI

/// Row view for guide items (warm-up / cool-down) with daily checkmark tracking
struct GuideRow: View {
    let item: GuideItem
    let color: Color
    let muscleGroup: String
    let section: String
    @Environment(TimerState.self) var timerState
    
    @State private var isChecked = false
    
    private var storageKey: String {
        "guide_\(muscleGroup)_\(section)_\(item.name)"
    }
    
    var body: some View {
        HStack {
            // Check Circle
            Button(action: toggleState) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isChecked ? Theme.success : Theme.inactive)
            }
            .buttonStyle(.plain)
            
            // Content
            NavigationLink(destination: GuideDetailView(item: item, color: color).environment(timerState)) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.body.weight(.medium))
                        .foregroundStyle(color)
                    
                    Text(item.duration)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onAppear(perform: loadState)
    }
    
    private func loadState() {
        if let lastDate = UserDefaults.standard.object(forKey: storageKey) as? Date {
            isChecked = Calendar.current.isDateInToday(lastDate)
        } else {
            isChecked = false
        }
    }
    
    private func toggleState() {
        let newState = !isChecked
        isChecked = newState
        
        if newState {
            UserDefaults.standard.set(Date(), forKey: storageKey)
        } else {
            UserDefaults.standard.removeObject(forKey: storageKey)
        }
    }
}
