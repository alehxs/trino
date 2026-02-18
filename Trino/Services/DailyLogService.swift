import Foundation
import SwiftData


func ensureTodayLogExists(context: ModelContext) throws {
    let today = Calendar.current.startOfDay(for: Date())
    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
    
    let descriptor = FetchDescriptor<DailyLog>(
        predicate: #Predicate { log in
            log.date >= today && log.date < tomorrow
        }
    )
    
    let results = try context.fetch(descriptor)
    
    if results.isEmpty {
        let newLog = try createTodayLog(context: context)
        context.insert(newLog)
    }
}

func createTodayLog(context: ModelContext) throws -> DailyLog {
    let descriptor = FetchDescriptor<TrinoTask>(
        predicate: #Predicate { task in
            task.isActive
        }
    )
        
    let activeTasks = try context.fetch(descriptor)
    
    let entries = activeTasks.map { TaskEntry(task: $0, slotPosition: $0.slotPosition) }
    
    return DailyLog(entries: entries)
}
