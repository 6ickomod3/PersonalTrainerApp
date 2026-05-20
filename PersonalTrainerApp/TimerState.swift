import Foundation
import Observation

@Observable
class TimerState {
    var isExpanded: Bool = true
    var expandedHeight: CGFloat = 0
    var collapsedHeight: CGFloat = 0
    
    /// Dynamic spacer height for views that need to account for the timer overlay
    var spacerHeight: CGFloat {
        let timerHeight = isExpanded ? expandedHeight : collapsedHeight
        return timerHeight > 0 ? timerHeight : (isExpanded ? 250 : 60)
    }
}
