import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query var dailyLogs: [DailyLog]
    @Environment(\.modelContext) var modelContext
    
    
    
    var todayLog: DailyLog? {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        return dailyLogs.first{
            $0.date >= today && $0.date < tomorrow  
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if let log = todayLog {
                    ForEach(log.sortedEntries) { entry in
                        HStack {
                            Image(systemName: entry.isCompleted ? "checkmark.circle.fill" : "circle")
                            Text(entry.task.name)
                        }
                        .onTapGesture {
                            entry.isCompleted.toggle()
                        }
                    }
                }
                else {
                    Text("No Tasks Yet")
                }
            }
            .navigationTitle("Dashboard")
            .onAppear {
                do {
                    try ensureTodayLogExists(context: modelContext)
                } catch {
                    print(error)
                }
            }
        }
    }
}
#Preview {
    DashboardView()
        .modelContainer(for: [TrinoTask.self, DailyLog.self, TaskEntry.self], inMemory: true)
}
