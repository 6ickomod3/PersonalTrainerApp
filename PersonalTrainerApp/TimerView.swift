import SwiftUI

struct TimerView: View {
    @State var timerManager = TimerManager()
    @State private var isExpanded: Bool = true
    @State private var dragOffset: CGFloat = 0
    var timerState: TimerState
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Border
            Divider()
                .frame(height: 1)
            
            if isExpanded {
                // Expanded View
                expandedView
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .background(GeometryReader { geo in
                        Color.clear.onAppear {
                            timerState.expandedHeight = geo.size.height + 50 // Account for label, padding, borders
                        }
                    })
            } else {
                // Minimized View
                minimizedView
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .background(GeometryReader { geo in
                        Color.clear.onAppear {
                            timerState.collapsedHeight = geo.size.height + 2 // Just borders
                        }
                    })
            }
            
            // Bottom Border
            Divider()
                .frame(height: 1)
        }
        .background(Color(.systemBackground))
        .padding(.bottom, 24)
        .onChange(of: isExpanded) { oldValue, newValue in
            timerState.isExpanded = newValue
        }
    }
    
    // MARK: - Expanded View
    
    private var expandedView: some View {
        VStack(spacing: 20) {
            // Label with icon
            HStack(spacing: 8) {
                Image(systemName: "timer")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                
                Text("Rest Timer")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Image(systemName: "chevron.up")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            // White Box Container with Timer and Buttons
            VStack(spacing: 20) {
                // Timer Display
                Text(timerManager.formattedTime)
                    .font(.system(size: 60, weight: .semibold, design: .default))
                    .contentTransition(.numericText())
                    .foregroundStyle(timerManager.isRunning ? .blue : .primary)
                
                // Control Buttons
                HStack(spacing: 16) {
                    // -15s Button
                    Button(action: { timerManager.addTime(-15) }) {
                        Text("–15s")
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                    
                    // +15s Button
                    Button(action: { timerManager.addTime(15) }) {
                        Text("+15s")
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                    
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
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                    
                    // Reset Button
                    Button(action: { timerManager.reset() }) {
                        Text("Reset")
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation.height
                }
                .onEnded { value in
                    if value.translation.height > 50 {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isExpanded = false
                        }
                    }
                    dragOffset = 0
                }
        )
    }
    
    // MARK: - Minimized View
    
    private var minimizedView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 0) {
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 50, height: 50)
                
                Spacer()
            }
            
            Text(timerManager.formattedTime)
                .font(.system(size: 20, weight: .semibold, design: .default))
                .monospacedDigit()
                .foregroundStyle(timerManager.isRunning ? .blue : .primary)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                isExpanded = true
            }
        }
        .contentTransition(.numericText())
    }
}

#Preview {
    @Previewable @State var timerState = TimerState()
    VStack {
        Spacer()
        TimerView(timerState: timerState)
    }
    .background(Color(.systemGray6))
}
