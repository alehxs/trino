import Foundation
import SwiftData

@Model
final class PendingSwap {
    var id: UUID
    var slotPosition: Int
    var newTaskName: String
    var effectiveDate: Date
    
    init(slotPosition: Int, newTaskName: String, effectiveDate: Date) {
        self.id = UUID()
        self.slotPosition = slotPosition
        self.newTaskName = newTaskName
        self.effectiveDate = effectiveDate
    }
}
