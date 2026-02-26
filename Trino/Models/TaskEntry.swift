import Foundation
import SwiftData

@Model
final class TaskEntry {
    var id: UUID
    var taskName: String
    var taskId: UUID
    var isCompleted: Bool
    var slotPosition: Int
    var dailyLog: DailyLog?

    init(taskName: String, taskId: UUID, slotPosition: Int) {
        self.id = UUID()
        self.taskName = taskName
        self.taskId = taskId
        self.isCompleted = false
        self.slotPosition = slotPosition
    }
}
