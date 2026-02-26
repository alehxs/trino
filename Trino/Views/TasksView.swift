import SwiftUI
import SwiftData

struct TasksView: View {
    @Query(sort: \DailyLog.date, order: .reverse) var dailyLogs: [DailyLog]
    @Environment(\.modelContext) var modelContext
    @State private var showSettings = false
    @State private var showManageTasks = false

    var productivityStreak: Int {
        StreakService.calculateProductivityStreak(from: dailyLogs)
    }

    var todayLog: DailyLog? {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        return dailyLogs.first { $0.date >= today && $0.date < tomorrow }
    }

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()

                if let log = todayLog, !log.sortedEntries.isEmpty {
                    VStack(spacing: 16) {
                        ForEach(log.sortedEntries) { entry in
                            TaskRowView(entry: entry)
                        }
                    }
                    .padding(.horizontal)
                } else {
                    Text("No tasks set up yet")
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if todayLog != nil {
                    Text(productivityStreak == 0 ? "No streak yet" : productivityStreak == 1 ? "1 day streak" : "\(productivityStreak) day streak")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 24)
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 4) {
                        Button {
                            showManageTasks = true
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                        }
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
            }
            .onAppear {
                do {
                    try ensureTodayLogExists(context: modelContext)
                } catch {
                    print(error)
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showManageTasks) {
            TaskManagementView()
        }
    }
}

#Preview {
    TasksView()
        .modelContainer(for: [TrinoTask.self, DailyLog.self, TaskEntry.self, PendingSwap.self], inMemory: true)
        .environment(SettingsStore())
}
