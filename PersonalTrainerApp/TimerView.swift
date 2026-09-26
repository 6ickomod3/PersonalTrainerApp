import SwiftUI

struct TimerView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var timerManager: TimerManager
    @State private var showingControls = false
    var defaultTimerDuration: Int

    init(defaultTimerDuration: Int = 90) {
        self.init(timerManager: TimerManager(initialDuration: defaultTimerDuration), defaultTimerDuration: defaultTimerDuration)
    }

    init(timerManager: TimerManager, defaultTimerDuration: Int) {
        self.defaultTimerDuration = defaultTimerDuration
        _timerManager = State(initialValue: timerManager)
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            ViewThatFits(in: .horizontal) {
                if !dynamicTypeSize.isAccessibilitySize { timerRow(showsButtonTitle: true) }
                timerRow(showsButtonTitle: false)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)

            if showingControls {
                Divider()
                expandedControls
            }
        }
        .background {
            // The background receives only taps outside the foreground controls.
            Button(action: toggleControls) {
                Color(.systemBackground).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHidden(true)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("RestTimerBar")
        .onAppear {
            timerManager.updateDefaultDuration(defaultTimerDuration)
            timerManager.setApplicationActive(scenePhase == .active)
        }
        .onChange(of: defaultTimerDuration) { _, duration in
            timerManager.updateDefaultDuration(duration)
        }
        .onChange(of: scenePhase) { _, phase in
            timerManager.setApplicationActive(phase == .active)
        }
    }

    private func timerRow(showsButtonTitle: Bool) -> some View {
        HStack(spacing: 4) {
            countdown
                .allowsHitTesting(false)
            Button(action: toggleControls) {
                Color.clear
                    .frame(minWidth: 44, maxWidth: .infinity)
                    .frame(height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(showingControls ? "Collapse rest timer controls" : "Expand rest timer controls")
            .accessibilityIdentifier("restTimerToggleArea")
            startPauseButton(showsTitle: showsButtonTitle)
            controlsButton
        }
    }

    private var countdown: some View {
        HStack(spacing: 8) {
            Image(systemName: timerManager.isFinished ? "checkmark.circle" : "timer")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.timerActive)
                .accessibilityHidden(true)
            Text(timerManager.formattedTime)
                .font(.body.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(Theme.timerActive)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .layoutPriority(1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(timerManager.isFinished ? "Rest complete" : "Rest timer")
        .accessibilityValue(timerManager.formattedTime)
    }

    private func startPauseButton(showsTitle: Bool) -> some View {
        Button(action: toggleStartPause) {
            HStack(spacing: 6) {
                Image(systemName: timerManager.isRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: 16, weight: .semibold))
                if showsTitle {
                    Text(timerManager.isRunning ? "Pause" : "Start")
                        .font(.body.weight(.semibold))
                }
            }
                .padding(.horizontal, showsTitle ? 12 : 0)
                .frame(minWidth: 44, minHeight: 44)
                .foregroundStyle(.white)
                .background(Theme.primaryAction, in: RoundedRectangle(cornerRadius: 12))
                .fixedSize(horizontal: true, vertical: false)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(timerManager.isRunning ? "Pause" : "Start")
        .accessibilityIdentifier("restTimerStartPause")
    }

    private var controlsButton: some View {
        Button(action: toggleControls) {
            Image(systemName: showingControls ? "chevron.down" : "chevron.up")
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(showingControls ? "Collapse rest timer controls" : "Expand rest timer controls")
        .accessibilityIdentifier("restTimerExpand")
    }

    private var expandedControls: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 8))
            : AnyLayout(HStackLayout(spacing: 12))
        return layout {
            adjustmentButton("−15s", accessibilityLabel: "Subtract 15 seconds") { timerManager.addTime(-15) }
            adjustmentButton("+15s", accessibilityLabel: "Add 15 seconds") { timerManager.addTime(15) }
            adjustmentButton("Reset", accessibilityLabel: "Reset timer") { timerManager.reset() }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("RestTimerControls")
    }

    private func adjustmentButton(_ title: String, accessibilityLabel: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.body.weight(.medium))
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(Theme.primaryAction)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
        .accessibilityLabel(accessibilityLabel)
    }

    private func toggleControls() {
        withAnimation(.easeInOut(duration: 0.2)) { showingControls.toggle() }
    }

    private func toggleStartPause() {
        if timerManager.isRunning {
            timerManager.pause()
        } else {
            timerManager.start()
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        ScrollView { Text("Workout content").frame(maxWidth: .infinity) }
        TimerView()
    }
}
