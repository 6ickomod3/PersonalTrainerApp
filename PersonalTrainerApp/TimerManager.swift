import Foundation
import UIKit

@Observable
class TimerManager {
    var secondsRemaining: Int = 60
    var isRunning: Bool = false
    private var timer: Timer?
    
    private let initialDuration = 60 // Initial 1 minute in seconds
    private var userSetDuration: Int = 60 // Tracks user-adjusted duration
    
    init() {
        self.secondsRemaining = initialDuration
        self.userSetDuration = initialDuration
    }
    
    // MARK: - Timer Control
    
    func start() {
        guard !isRunning else { return }
        isRunning = true
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }
    
    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
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
    }
    
    // MARK: - Private Methods
    
    private func tick() {
        secondsRemaining -= 1
        
        if secondsRemaining <= 0 {
            secondsRemaining = 0
            pause()
            triggerHapticFeedback()
        }
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
    
    // MARK: - Time Formatting
    
    var formattedTime: String {
        let minutes = secondsRemaining / 60
        let seconds = secondsRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    deinit {
        timer?.invalidate()
    }
}
