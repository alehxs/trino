import Foundation
import SwiftData

@Model
final class DailyLog {
    var id: UUID
    var date: Date
    var task1Name: String
    var task2Name: String
    var task3Name: String
    var task1Completed: Bool
    var task2Completed: Bool
    var task3Completed: Bool
    
    init(task1Name: String, task2Name: String, task3Name: String) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: Date())
        self.task1Name = task1Name
        self.task2Name = task2Name
        self.task3Name = task3Name
        self.task1Completed = false
        self.task2Completed = false
        self.task3Completed = false
        
    }
    
    var completionCount: Int {
        return (task1Completed ? 1 : 0) + (task2Completed ? 1 : 0) + (task3Completed ? 1 : 0)
    }

}
