import SwiftUI

// MARK: - Visual Effect Blur
struct VisualEffectBlur: UIViewRepresentable {
    var style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let blurEffect = UIBlurEffect(style: style)
        let blurView = UIVisualEffectView(effect: blurEffect)
        return blurView
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

struct TimerView: View {
    @State var timerManager: TimerManager
    @State private var isExpanded: Bool = false
    @State private var dragOffset: CGFloat = 0
    var timerState: TimerState
    var defaultTimerDuration: Int = 90
    
    init(timerState: TimerState, defaultTimerDuration: Int = 90) {
        self.timerState = timerState
        self.defaultTimerDuration = defaultTimerDuration
        _timerManager = State(initialValue: TimerManager(initialDuration: defaultTimerDuration))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
                // Expanded View
                expandedView
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .background(GeometryReader { geo in
                        Color.clear.onAppear {
                            timerState.expandedHeight = geo.size.height + 24
                        }
                    })
            } else {
                // Minimized View
                minimizedView
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .background(GeometryReader { geo in
                        Color.clear.onAppear {
                            timerState.collapsedHeight = geo.size.height
                        }
                    })
            }
        }
        .onChange(of: isExpanded) { oldValue, newValue in
            timerState.isExpanded = newValue
        }
    }
    
    // MARK: - Expanded View
    
    private var expandedView: some View {
        VStack(spacing: 0) {
            // Unified Glass Container
            VStack(spacing: 16) {
                // Header Section
                HStack(spacing: 8) {
                    Image(systemName: "timer")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                    
                    Text("Rest Timer")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.up")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                
                Divider()
                    .padding(.horizontal, 16)
                
                // Content Section
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
                        .disabled(timerManager.isRunning)
                        .opacity(timerManager.isRunning ? 0.3 : 1.0)
                        
                        // +15s Button
                        Button(action: { timerManager.addTime(15) }) {
                            Text("+15s")
                                .font(.body)
                                .foregroundStyle(.primary)
                        }
                        .disabled(timerManager.isRunning)
                        .opacity(timerManager.isRunning ? 0.3 : 1.0)
                        
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
                .padding(.bottom, 50)
            }
            .background(
                ZStack {
                    VisualEffectBlur(style: .systemThickMaterial)
                    Color.white.opacity(0.2)
                }
                .ignoresSafeArea(edges: .bottom)
            )
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 20, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 20))
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: -2)
        }
        .padding(.horizontal)
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
        VStack(spacing: 0) {
            Text(timerManager.formattedTime)
                .font(.system(size: 20, weight: .semibold, design: .default))
                .monospacedDigit()
                .foregroundStyle(timerManager.isRunning ? .blue : .primary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .padding(.bottom, 20)
        }
        .background(
            ZStack {
                VisualEffectBlur(style: .systemThickMaterial)
                Color.white.opacity(0.2)
            }
            .ignoresSafeArea(edges: .bottom)
        )
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 20, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: -2)
        .padding(.horizontal)
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
