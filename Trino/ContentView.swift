//
//  ContentView.swift
//  Trino
//
//  Created by Alex on 1/28/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(SettingsStore.self) private var settings
    @State private var selectedTab = 1
    @Query private var todayLogs: [DailyLog]

    init() {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        _todayLogs = Query(filter: #Predicate<DailyLog> { log in
            log.date >= today && log.date < tomorrow
        })
    }

    private var allTasksCompleted: Bool {
        todayLogs.first.map { $0.completionCount == 3 } ?? false
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            StreakView()
                .tabItem { Label("Progress", systemImage: "chart.bar.fill") }
                .tag(0)

            TasksView()
                .tabItem { Label("Tasks", systemImage: allTasksCompleted ? "checkmark.circle.fill" : "checkmark.circle") }
                .tag(1)

            YearTrackerView()
                .tabItem { Label("Year", systemImage: "calendar") }
                .tag(2)
        }
        .tint(settings.theme.accent)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [TrinoTask.self, DailyLog.self, TaskEntry.self, PendingSwap.self], inMemory: true)
        .environment(SettingsStore())
}
