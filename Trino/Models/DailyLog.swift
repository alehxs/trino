import Foundation
import SwiftData

@Model
final class DailyLog {
    var id: UUID
    var date: Date
    @Relationship(deleteRule: .cascade, inverse: \TaskEntry.dailyLog)
    var entries: [TaskEntry]

    init(entries: [TaskEntry]) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: Date())
        self.entries = entries
    }

    var completionCount: Int {
        entries.filter(\.isCompleted).count
    }
    
    var sortedEntries: [TaskEntry] {
        entries.sorted { $0.slotPosition < $1.slotPosition }
    }
}
