import Foundation
import SwiftData

@Model
class AppSettings {
    var id: UUID = UUID()
    var maxStorageDays: Int = 4
    var defaultTimerDuration: Int = 90 // Default 1:30 in seconds
    var userName: String = ""

    init() {
        self.id = UUID()
        self.maxStorageDays = 4
        self.defaultTimerDuration = 90
        self.userName = ""
    }
}
