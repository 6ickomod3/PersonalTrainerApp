import Foundation
import UIKit
import ActivityKit
import AudioToolbox
import UserNotifications

@Observable
class TimerManager {
    var secondsRemaining: Int
    var isRunning: Bool = false
    
    // Live Activity
    private var activity: Activity<TimerAttributes>?
    
    private var timer: Timer?
    private var endTime: Date?
    
    private let initialDuration: Int
    private var userSetDuration: Int
    
    init(initialDuration: Int = 90) {
        self.initialDuration = initialDuration
        self.secondsRemaining = initialDuration
        self.userSetDuration = initialDuration
        
        // Request permission immediately
        requestNotificationPermission()
    }
    
    // MARK: - Timer Control
    
    func start() {
        guard !isRunning else { return }
        
        // If we are starting fresh or resuming, calculate the target end time
        let targetDate = Date().addingTimeInterval(TimeInterval(secondsRemaining))
        endTime = targetDate
        isRunning = true
        
        // Start Live Activity
        startLiveActivity(endTime: targetDate)
        
        // Start local timer for UI updates
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }
    
    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        endTime = nil
        
        // End Live Activity immediately
        endLiveActivity()
    }
    
    func reset() {
        pause()
        secondsRemaining = userSetDuration
    }
    
    func addTime(_ seconds: Int) {
        secondsRemaining += seconds
        
        // Update the user-set duration to remember this adjustment
        userSetDuration = secondsRemaining
        
        // Prevent negative time
        if secondsRemaining < 0 {
            secondsRemaining = 0
            userSetDuration = 0
        }
        
        // If running, extend the end time and update Live Activity
        if isRunning, let currentEnd = endTime {
            let newEnd = currentEnd.addingTimeInterval(TimeInterval(seconds))
            endTime = newEnd
            updateLiveActivity(endTime: newEnd)
        }
    }
    
    // MARK: - Private Methods
    
    private func tick() {
        guard let endTime = endTime else { return }
        
        let remaining = endTime.timeIntervalSinceNow
        
        if remaining <= 0 {
            secondsRemaining = 0
            pause()
            triggerAlarm()
        } else {
            // Round up to show "1" until it actually hits 0
            secondsRemaining = Int(ceil(remaining))
        }
    }
    
    private func triggerAlarm() {
        // Haptic Feedback
        triggerHapticFeedback()
        
        // Play Sound (if app is in foreground)
        playForegroundSound()
    }
    
    private func playForegroundSound() {
        // ID 1005 is the standard alarm sound
        // ID 1022 is "Calypso" (gentler)
        AudioServicesPlaySystemSound(1022)
    }
    
    private func triggerHapticFeedback() {
        // Trigger strong haptic feedback for 3 seconds (like incoming call vibration)
        let feedbackPattern = [
            0.0,   // Start immediately
            0.15,  // First impact
            0.3,   // Second impact
            0.45,  // Third impact
            0.6,   // Fourth impact
            0.75,  // Fifth impact
            0.9,   // Sixth impact
            1.05,  // Seventh impact
            1.2,   // Eighth impact
            1.35,  // Ninth impact
            1.5,   // Tenth impact
            1.65,  // Eleventh impact
            1.8,   // Twelfth impact
            1.95,  // Thirteenth impact
            2.1,   // Fourteenth impact
            2.25,  // Fifteenth impact
            2.4,   // Sixteenth impact
            2.55,  // Seventeenth impact
            2.7,   // Eighteenth impact
            2.85,  // Nineteenth impact
        ]
        
        for delay in feedbackPattern {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                let impact = UIImpactFeedbackGenerator(style: .heavy)
                impact.impactOccurred()
            }
        }
    }
    
    // MARK: - Notifications
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    private func scheduleNotification(at date: Date) {
        // Remove any existing timer notifications
        cancelNotification()
        
        let content = UNMutableNotificationContent()
        content.title = "Rest Timer Finished"
        content.body = "Time to get back to work!"
        content.sound = .default
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: "RestTimer", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func cancelNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["RestTimer"])
    }
    
    // MARK: - Live Activity
    
    private func startLiveActivity(endTime: Date) {
        // Also schedule the notification when we start the activity/timer
        scheduleNotification(at: endTime)
        
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        let attributes = TimerAttributes(timerName: "Rest Timer")
        let contentState = TimerAttributes.ContentState(endTime: endTime, duration: userSetDuration)
        let content = ActivityContent(state: contentState, staleDate: endTime.addingTimeInterval(60))
        
        do {
            activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
        } catch {
            print("Error starting Live Activity: \(error.localizedDescription)")
        }
    }
    
    private func updateLiveActivity(endTime: Date) {
        // Update notification trigger
        scheduleNotification(at: endTime)
        
        guard let activity = activity else { return }
        
        let contentState = TimerAttributes.ContentState(endTime: endTime, duration: userSetDuration)
        let content = ActivityContent(state: contentState, staleDate: endTime.addingTimeInterval(60))
        
        Task {
            await activity.update(content)
        }
    }
    
    private func endLiveActivity() {
        // Cancel notification
        cancelNotification()
        
        guard let activity = activity else { return }
        
        let contentState = TimerAttributes.ContentState(endTime: Date(), duration: userSetDuration)
        let content = ActivityContent(state: contentState, staleDate: nil)
        
        Task {
            await activity.end(content, dismissalPolicy: .immediate)
            self.activity = nil
        }
    }
    
    // MARK: - Time Formatting
    
    var formattedTime: String {
        let minutes = secondsRemaining / 60
        let seconds = secondsRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    deinit {
        timer?.invalidate()
        // Ensure activity ends if manager dies
        if let activity = activity {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }
    }
}
