import Foundation
import Observation
import UIKit
import ActivityKit
import AudioToolbox
import UserNotifications

@MainActor
@Observable
final class TimerManager {
    private(set) var secondsRemaining: Int
    private(set) var isRunning = false
    private(set) var isFinished = false

    private var defaultDuration: Int
    private var resetDuration: Int
    private var currentDuration: Int
    private var hasStarted = false
    private var isApplicationActive = true
    private var endTime: Date?

    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var activity: Activity<TimerAttributes>?
    @ObservationIgnored private var notificationIdentifier: String?
    @ObservationIgnored private var notificationTask: Task<Void, Never>?
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private let enablesExternalEffects: Bool
    @ObservationIgnored private let automaticallyTicks: Bool

    init(
        initialDuration: Int = 90,
        now: @escaping () -> Date = Date.init,
        enablesExternalEffects: Bool = true,
        automaticallyTicks: Bool = true
    ) {
        let duration = max(1, initialDuration)
        defaultDuration = duration
        resetDuration = duration
        currentDuration = duration
        secondsRemaining = duration
        self.now = now
        self.enablesExternalEffects = enablesExternalEffects
        self.automaticallyTicks = automaticallyTicks
    }

    /// A setting change applies immediately when idle and to the next rest when active.
    func updateDefaultDuration(_ duration: Int) {
        let duration = max(1, duration)
        guard duration != defaultDuration else { return }
        defaultDuration = duration
        resetDuration = duration
        if !hasStarted {
            secondsRemaining = duration
            currentDuration = duration
            isFinished = false
        }
    }

    func start() {
        guard !isRunning else { return }
        if isFinished || secondsRemaining <= 0 {
            secondsRemaining = resetDuration
            currentDuration = resetDuration
        }
        isFinished = false
        hasStarted = true
        isRunning = true
        let target = now().addingTimeInterval(TimeInterval(secondsRemaining))
        endTime = target
        scheduleNotification(at: target)
        startLiveActivity(endTime: target)
        startTicking()
    }

    func pause() {
        guard isRunning else { return }
        synchronize()
        guard isRunning else { return }
        stopCountdown()
    }

    func reset() {
        stopCountdown()
        hasStarted = false
        isFinished = false
        secondsRemaining = resetDuration
        currentDuration = resetDuration
    }

    /// Used when erasing app settings; also clears adjustments made to the current rest.
    func resetToDefaultDuration(_ duration: Int) {
        defaultDuration = max(1, duration)
        resetDuration = defaultDuration
        reset()
    }

    func addTime(_ seconds: Int) {
        if isRunning { synchronize() }
        // Adjustments are remembered for the next rest, until Settings changes the default.
        resetDuration = max(1, resetDuration + seconds)
        secondsRemaining = max(0, secondsRemaining + seconds)
        currentDuration = max(1, currentDuration + seconds)
        if isFinished {
            secondsRemaining = resetDuration
            currentDuration = resetDuration
            isFinished = false
            hasStarted = false
        }
        guard isRunning else { return }
        guard secondsRemaining > 0 else {
            finish(playsAlarm: isApplicationActive)
            return
        }
        if let previousEnd = endTime {
            // Preserve the fractional second of the deadline when extending a rest.
            let target = previousEnd.addingTimeInterval(TimeInterval(seconds))
            endTime = target
            scheduleNotification(at: target)
            updateLiveActivity(endTime: target)
        }
    }

    /// Reconcile after suspension without replaying a late foreground alarm.
    func setApplicationActive(_ active: Bool) {
        guard active != isApplicationActive else { return }
        isApplicationActive = active
        if active {
            synchronize(playsAlarm: false)
            startTicking()
        } else {
            stopTicking()
        }
    }

    func synchronize(playsAlarm: Bool = true) {
        guard isRunning, let endTime else { return }
        let remaining = endTime.timeIntervalSince(now())
        if remaining <= 0 {
            finish(playsAlarm: playsAlarm && isApplicationActive)
        } else {
            secondsRemaining = Int(ceil(remaining))
        }
    }

    private func finish(playsAlarm: Bool) {
        stopCountdown()
        secondsRemaining = 0
        isFinished = true
        hasStarted = false
        if enablesExternalEffects && playsAlarm {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            AudioServicesPlaySystemSound(1022)
        }
    }

    private func stopCountdown() {
        isRunning = false
        endTime = nil
        stopTicking()
        cancelNotification()
        endLiveActivity()
    }

    private func startTicking() {
        guard automaticallyTicks, isRunning, isApplicationActive, timer == nil else { return }
        let timer = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.synchronize() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func stopTicking() {
        timer?.invalidate()
        timer = nil
    }

    // Notifications remain independent of Live Activity authorization and availability.
    private func scheduleNotification(at date: Date) {
        guard enablesExternalEffects else { return }
        cancelNotification()
        let identifier = "RestTimer-\(UUID().uuidString)"
        notificationIdentifier = identifier
        notificationTask = Task { [weak self] in
            let center = UNUserNotificationCenter.current()
            var settings = await center.notificationSettings()
            if settings.authorizationStatus == .notDetermined {
                _ = try? await center.requestAuthorization(options: [.alert, .sound])
                settings = await center.notificationSettings()
            }
            guard let self, !Task.isCancelled,
                  self.notificationIdentifier == identifier,
                  settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
            else { return }
            let interval = date.timeIntervalSince(self.now())
            guard interval > 0 else { return }
            let content = UNMutableNotificationContent()
            content.title = "Rest complete"
            content.body = "Ready for your next set."
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, interval), repeats: false)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            try? await center.add(request)
            // Pause/reset may run while the notification center processes add.
            if Task.isCancelled || self.notificationIdentifier != identifier {
                center.removePendingNotificationRequests(withIdentifiers: [identifier])
            }
        }
    }

    private func cancelNotification() {
        notificationTask?.cancel()
        notificationTask = nil
        guard let identifier = notificationIdentifier else { return }
        notificationIdentifier = nil
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    private func startLiveActivity(endTime: Date) {
        guard enablesExternalEffects, ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let content = activityContent(endTime: endTime)
        do {
            activity = try Activity.request(
                attributes: TimerAttributes(timerName: "Rest Timer"),
                content: content,
                pushType: nil
            )
        } catch {
            print("Unable to start rest Live Activity: \(error.localizedDescription)")
        }
    }

    private func updateLiveActivity(endTime: Date) {
        guard let activity else { return }
        let content = activityContent(endTime: endTime)
        Task { await activity.update(content) }
    }

    private func endLiveActivity() {
        guard let endingActivity = activity else { return }
        // Ending an old rest must not clear a newly started activity.
        activity = nil
        let content = activityContent(endTime: now())
        Task { await endingActivity.end(content, dismissalPolicy: .immediate) }
    }

    private func activityContent(endTime: Date) -> ActivityContent<TimerAttributes.ContentState> {
        ActivityContent(
            state: TimerAttributes.ContentState(endTime: endTime, duration: currentDuration),
            staleDate: endTime
        )
    }

    var formattedTime: String {
        String(format: "%02d:%02d", secondsRemaining / 60, secondsRemaining % 60)
    }

    var progress: Double {
        min(max(Double(secondsRemaining) / Double(currentDuration), 0), 1)
    }

    deinit {
        timer?.invalidate()
        notificationTask?.cancel()
        if let identifier = notificationIdentifier {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        }
        if let activity {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }
    }
}
