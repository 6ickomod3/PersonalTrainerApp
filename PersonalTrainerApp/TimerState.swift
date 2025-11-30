import Foundation
import Observation

@Observable
class TimerState {
    var isExpanded: Bool = true
    var expandedHeight: CGFloat = 0
    var collapsedHeight: CGFloat = 0
}
