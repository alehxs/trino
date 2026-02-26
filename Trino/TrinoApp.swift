import SwiftUI
import SwiftData

@main
struct TrinoApp: App {
    @State private var settingsStore = SettingsStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(for: [TrinoTask.self, DailyLog.self, TaskEntry.self, PendingSwap.self])
                .environment(settingsStore)
                .task { await AppIconService.apply(theme: settingsStore.theme) }
        }
    }
}
