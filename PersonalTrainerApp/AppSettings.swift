import Foundation
import SwiftData

@Model
class AppSettings {
    var id: UUID = UUID()
    var maxStorageDays: Int = 4
    
    init() {
        self.id = UUID()
        self.maxStorageDays = 4
    }
}
