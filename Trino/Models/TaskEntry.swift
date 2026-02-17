import Foundation
import SwiftData

@Model
final class TaskEntry {
    var id: UUID
    var task: TrinoTask
    var isCompleted: Bool
    var slotPosition: Int
    var dailyLog: DailyLog?

    init(task: TrinoTask, slotPosition: Int){
        self.id = UUID()
        self.task = task
        self.isCompleted = false
        self.slotPosition = slotPosition
    }
}
