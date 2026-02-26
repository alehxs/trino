import Foundation

struct StreakService {

    /// Consecutive days ending today (or yesterday if today has no log yet / is unproductive)
    /// where completionCount >= 2. A gap or low count resets to 0.
    static func calculateProductivityStreak(from logs: [DailyLog]) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let logsByDate = Dictionary(uniqueKeysWithValues: logs.map { ($0.date, $0.completionCount) })

        // Only anchor at today if today is already productive; otherwise use yesterday
        // (avoids resetting a long streak every morning before the 2nd task is completed)
        let anchor: Date
        if let todayCount = logsByDate[today], todayCount >= 2 {
            anchor = today
        } else {
            anchor = calendar.date(byAdding: .day, value: -1, to: today)!
        }

        var streak = 0
        var current = anchor

        while let count = logsByDate[current], count >= 2 {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: current) else { break }
            current = prev
        }

        return streak
    }

    /// Consecutive days a specific task (by taskId UUID) was completed.
    static func calculateTaskStreak(taskId: UUID, from logs: [DailyLog]) -> Int {
        var completedDates = Set<Date>()
        for log in logs where log.entries.contains(where: { $0.taskId == taskId && $0.isCompleted }) {
            completedDates.insert(log.date)
        }
        return streakFrom(dates: completedDates)
    }

    /// Top 3 per-task streaks across all unique taskIds, sorted descending.
    /// Single pass over logs — O(N) instead of O(K×N).
    static func getTopTaskStreaks(from logs: [DailyLog]) -> [(taskName: String, streak: Int)] {
        var taskNames = [UUID: String]()
        var completedDates = [UUID: Set<Date>]()

        // Oldest-first so the most recent name wins on collision
        for log in logs.sorted(by: { $0.date < $1.date }) {
            for entry in log.entries {
                taskNames[entry.taskId] = entry.taskName
                if entry.isCompleted {
                    completedDates[entry.taskId, default: []].insert(log.date)
                }
            }
        }

        return taskNames.keys
            .compactMap { taskId -> (taskName: String, streak: Int)? in
                guard let name = taskNames[taskId] else { return nil }
                let streak = streakFrom(dates: completedDates[taskId] ?? [])
                return streak > 0 ? (taskName: name, streak: streak) : nil
            }
            .sorted { $0.streak > $1.streak }
            .prefix(3)
            .map { $0 }
    }

    // MARK: - Aggregate stats

    static func completionRate(from logs: [DailyLog]) -> Double {
        guard !logs.isEmpty else { return 0 }
        let productive = logs.filter { $0.completionCount >= 2 }.count
        return Double(productive) / Double(logs.count)
    }

    static func totalDaysLogged(from logs: [DailyLog]) -> Int {
        logs.count
    }

    static func totalTasksCompleted(from logs: [DailyLog]) -> Int {
        logs.reduce(0) { $0 + $1.completionCount }
    }

    // MARK: - Private

    private static func streakFrom(dates: Set<Date>) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let anchor = dates.contains(today)
            ? today
            : calendar.date(byAdding: .day, value: -1, to: today)!

        var streak = 0
        var current = anchor

        while dates.contains(current) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: current) else { break }
            current = prev
        }

        return streak
    }
}
