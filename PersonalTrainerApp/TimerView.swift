import SwiftUI

struct TimerView: View {
    @State var timerManager: TimerManager
    @State private var isExpanded: Bool = false
    @State private var dragOffset: CGFloat = 0
    @State private var startPauseToggleCount: Int = 0
    var defaultTimerDuration: Int = 90

    init(defaultTimerDuration: Int = 90) {
        self.defaultTimerDuration = defaultTimerDuration
        _timerManager = State(initialValue: TimerManager(initialDuration: defaultTimerDuration))
    }

    var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
                expandedView
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                minimizedView
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .sensoryFeedback(.success, trigger: startPauseToggleCount)
    }

    // MARK: - Expanded View

    private var expandedView: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                // Header (chevron tap-to-collapse)
                Button(action: collapse) {
                    HStack(spacing: 8) {
                        Image(systemName: "timer")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)

                        Text("Rest Timer")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)

                        Spacer()

                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Collapse rest timer")

                Divider()
                    .padding(.horizontal, 16)

                // Ring + countdown
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.18), lineWidth: 8)

                    Circle()
                        .trim(from: 0, to: timerManager.progress)
                        .stroke(
                            Theme.timerActive,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.1), value: timerManager.progress)

                    Text(timerManager.formattedTime)
                        .font(.system(size: 56, weight: .semibold, design: .default))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .foregroundStyle(Theme.timerActive)
                }
                .frame(width: 200, height: 200)
                .padding(.top, 4)

                // Controls
                HStack(spacing: 12) {
                    secondaryButton("–15s", action: { timerManager.addTime(-15) })
                        .accessibilityLabel("Subtract 15 seconds")

                    secondaryButton("+15s", action: { timerManager.addTime(15) })
                        .accessibilityLabel("Add 15 seconds")

                    Spacer()

                    secondaryButton("Reset", action: { timerManager.reset() })

                    primaryButton(timerManager.isRunning ? "Pause" : "Start", action: toggleStartPause)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
            .background(.regularMaterial)
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 20, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 20))
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: -2)
            .ignoresSafeArea(edges: .bottom)
        }
        .padding(.horizontal)
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation.height
                }
                .onEnded { value in
                    if value.translation.height > 50 {
                        collapse()
                    }
                    dragOffset = 0
                }
        )
    }

    // MARK: - Minimized View

    private var minimizedView: some View {
        VStack(spacing: 0) {
            // Progress bar at top edge — confirms an active timer
            // without taking layout space in the collapsed state.
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.15))
                    Rectangle()
                        .fill(Theme.timerActive)
                        .frame(width: geo.size.width * timerManager.progress)
                        .animation(.linear(duration: 0.1), value: timerManager.progress)
                }
            }
            .frame(height: 5)

            Text(timerManager.formattedTime)
                .font(.system(size: 20, weight: .semibold, design: .default))
                .monospacedDigit()
                .foregroundStyle(Theme.timerActive)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .padding(.bottom, 20)
        }
        .background(.regularMaterial)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 20, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: -2)
        .ignoresSafeArea(edges: .bottom)
        .padding(.horizontal)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                isExpanded = true
            }
        }
        .contentTransition(.numericText())
    }

    // MARK: - Helpers

    private func toggleStartPause() {
        if timerManager.isRunning {
            timerManager.pause()
        } else {
            timerManager.start()
        }
        startPauseToggleCount += 1
    }

    private func collapse() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isExpanded = false
        }
    }

    private func primaryButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .frame(minWidth: 84, minHeight: 44)
                .background(Capsule().fill(Theme.primaryAction))
        }
    }

    private func secondaryButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.body)
                .foregroundStyle(Theme.primaryAction)
                .frame(minWidth: 44, minHeight: 44)
        }
    }
}

#Preview {
    VStack {
        Spacer()
        Text("Scroll content above")
        Spacer()
    }
    .safeAreaInset(edge: .bottom) {
        TimerView()
    }
    .background(Color(.systemGray6))
}
