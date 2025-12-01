import ActivityKit
import Foundation

struct TimerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // The end time is dynamic and changes if the user adds time
        var endTime: Date
        var duration: Int
    }

    // Fixed non-changing properties about your activity go here!
    var timerName: String
}
