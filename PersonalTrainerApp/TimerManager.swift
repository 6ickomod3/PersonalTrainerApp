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
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()
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
