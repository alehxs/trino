import SwiftUI
import SwiftData

@main
struct TrinoApp: App {
    var body: some Scene {
        WindowGroup {
            DashboardView()
                .modelContainer(for: [TrinoTask.self, DailyLog.self, PendingSwap.self])
        }
    }
}
