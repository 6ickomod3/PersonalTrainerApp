import SwiftUI

struct TimerView: View {
    @State var timerManager = TimerManager()
    
    var body: some View {
        VStack(spacing: 16) {
            // Timer Display
            VStack(spacing: 8) {
                Text("Rest Timer")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(timerManager.formattedTime)
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundStyle(timerManager.isRunning ? .blue : .primary)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
            .frame(height: 100)
            
            // Control Buttons
            HStack(spacing: 12) {
                // -15s Button
                Button(action: { timerManager.addTime(-15) }) {
                    Text("–15s")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.bordered)
                .tint(.gray)
                
                Spacer()
                
                // Start/Pause Button
                Button(action: {
                    if timerManager.isRunning {
                        timerManager.pause()
                    } else {
                        timerManager.start()
                    }
                }) {
                    Text(timerManager.isRunning ? "Pause" : "Start")
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.semibold)
                        .frame(minWidth: 80)
                        .foregroundStyle(.white)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                
                Spacer()
                
                // Reset Button
                Button(action: { timerManager.reset() }) {
                    Text("Reset")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.bordered)
                .tint(.gray)
                
                Spacer()
                
                // +15s Button
                Button(action: { timerManager.addTime(15) }) {
                    Text("+15s")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.bordered)
                .tint(.gray)
            }
            .padding(.horizontal, 8)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }
}

#Preview {
    VStack {
        Spacer()
        TimerView()
    }
    .background(Color(.systemBackground))
}
