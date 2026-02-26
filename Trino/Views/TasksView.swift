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

                    Text(productivityStreak == 0 ? "No streak yet" : productivityStreak == 1 ? "1 day streak" : "\(productivityStreak) day streak")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 12)
                } else {
                    Text("No tasks set up yet")
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showManageTasks = true
                    } label: {
                        Image(systemName: "arrow.trianglehead.2.clockwise")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
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
