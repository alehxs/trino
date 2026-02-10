import Foundation
import SwiftData

@Model
final class TrinoTask {
    var id: UUID
    var name: String
    var slotPosition: Int
    var isActive: Bool
    var createdDate: Date
    
    init(name: String, slotPosition: Int) {
        self.id = UUID()
        self.name = name
        self.slotPosition = slotPosition
        self.isActive = true
        self.createdDate = Date()
    }
}
