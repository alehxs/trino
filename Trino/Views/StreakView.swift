import SwiftUI
import SwiftData

struct StreakView: View {
    @Query(sort: \DailyLog.date, order: .reverse) var dailyLogs: [DailyLog]

    var productivityStreak: Int {
        StreakService.calculateProductivityStreak(from: dailyLogs)
    }

    var topTaskStreaks: [(taskName: String, streak: Int)] {
        StreakService.getTopTaskStreaks(from: dailyLogs)
    }

    var streakContextLabel: String {
        switch productivityStreak {
        case 0:     return "Complete 2 of 3 tasks today to start"
        case 1:     return "Day one. The streak starts now."
        case 2...6: return "Building momentum — keep going"
        case 7...13: return "One week strong"
        case 14...29: return "Two weeks in — this is becoming a habit"
        default:    return "A month of consistency. Remarkable."
        }
    }

    var flameColor: Color {
        switch productivityStreak {
        case 0:    return Color(.secondaryLabel)
        case 1...6: return .orange
        default:   return Color(red: 1.0, green: 0.4, blue: 0.0)
        }
    }

    var taskStreaksAreUniform: Bool {
        Set(topTaskStreaks.map(\.streak)).count <= 1
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if dailyLogs.isEmpty {
                    emptyStateView
                } else {
                    mainContentView
                }
            }
            .navigationTitle("Progress")
        }
    }

    // MARK: - Subviews

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 60)
            Image(systemName: "flame")
                .font(.system(size: 48))
                .foregroundStyle(Color(.tertiaryLabel))
            Text("Your streak starts today")
                .font(.title3.weight(.semibold))
            Text("Complete at least 2 of your 3 tasks\nto log your first day.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
    }

    private var mainContentView: some View {
        VStack(spacing: 28) {
            // Hero
            VStack(spacing: 8) {
                HStack(alignment: .center, spacing: 6) {
                    Text("\(productivityStreak)")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(flameColor)
                        .monospacedDigit()
                        .contentTransition(.numericText())

                    Image(systemName: "flame.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(flameColor)
                }

                Text(productivityStreak == 1 ? "day streak" : "days streak")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                WeeklyCompletionDots(logs: dailyLogs)
                    .padding(.vertical, 4)

                Text(streakContextLabel)
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.top, 16)

            // Stats row
            StatsRow(
                daysLogged: StreakService.totalDaysLogged(from: dailyLogs),
                completionRate: StreakService.completionRate(from: dailyLogs),
                totalCompleted: StreakService.totalTasksCompleted(from: dailyLogs)
            )

            // Individual streaks
            VStack(alignment: .leading, spacing: 12) {
                Text("Individual Streaks")
                    .font(.headline)
                    .padding(.horizontal)

                if topTaskStreaks.isEmpty {
                    Text("Complete tasks to start building streaks.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 24)
                } else {
                    ForEach(Array(topTaskStreaks.enumerated()), id: \.offset) { index, item in
                        TaskStreakRow(
                            rank: index + 1,
                            taskName: item.taskName,
                            streak: item.streak,
                            showRank: !taskStreaksAreUniform
                        )
                    }
                }
            }
        }
        .padding(.bottom, 24)
    }
}

// MARK: - Weekly Completion Dots

struct WeeklyCompletionDots: View {
    let logs: [DailyLog]
    @Environment(SettingsStore.self) private var settings

    private enum DotState { case empty, partial, completed }

    private var last7Days: [DotState] {
        let calendar = Calendar.current
        return (0..<7).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date())!
            let dayStart = calendar.startOfDay(for: date)
            guard let log = logs.first(where: { calendar.startOfDay(for: $0.date) == dayStart }) else {
                return .empty
            }
            switch log.completionCount {
            case 3:    return .completed
            case 1...: return .partial
            default:   return .empty
            }
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(last7Days.enumerated()), id: \.offset) { _, state in
                Circle()
                    .fill(dotColor(for: state))
                    .frame(width: 10, height: 10)
            }
        }
    }

    private func dotColor(for state: DotState) -> Color {
        switch state {
        case .empty:     return Color(.systemFill)
        case .partial:   return settings.theme.accent.opacity(0.4)
        case .completed: return settings.theme.accent
        }
    }
}

// MARK: - Stats Row

struct StatsRow: View {
    let daysLogged: Int
    let completionRate: Double
    let totalCompleted: Int

    var body: some View {
        HStack(spacing: 0) {
            StatCell(value: "\(daysLogged)", label: "days tracked")
            Divider().frame(height: 36)
            StatCell(value: "\(Int(completionRate * 100))%", label: "completion")
            Divider().frame(height: 36)
            StatCell(value: "\(totalCompleted)", label: "tasks done")
        }
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

struct StatCell: View {
    let value: String
    let label: String
    @Environment(SettingsStore.self) private var settings

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.headline, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(settings.theme.accent)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Task Streak Row

struct TaskStreakRow: View {
    let rank: Int
    let taskName: String
    let streak: Int
    let showRank: Bool
    @Environment(SettingsStore.self) private var settings

    var body: some View {
        HStack(spacing: 16) {
            if showRank {
                Image(systemName: "\(rank).circle.fill")
                    .font(.title2)
                    .foregroundStyle(rank == 1 ? settings.theme.accent : Color(.secondaryLabel))
            } else {
                Circle()
                    .fill(Color(.tertiarySystemFill))
                    .frame(width: 28, height: 28)
            }

            Text(taskName)
                .font(.body)

            Spacer()

            HStack(spacing: 4) {
                Text("\(streak)")
                    .font(.headline)
                    .monospacedDigit()
                    .foregroundStyle(settings.theme.accent)
                Text(streak == 1 ? "day" : "days")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

#Preview {
    StreakView()
        .modelContainer(for: [TrinoTask.self, DailyLog.self, TaskEntry.self, PendingSwap.self], inMemory: true)
}
