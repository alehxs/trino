import Foundation
import SwiftData

struct TaskSwapService {

    // Returns true if the current time is still before the user's cut-off, meaning
    // scheduling a swap for tomorrow is allowed.
    static func canSwapForTomorrow(settings: SettingsStore) -> Bool {
        let cal = Calendar.current
        let now = Date()
        let nowMinutes = cal.component(.hour, from: now) * 60 + cal.component(.minute, from: now)
        let cutoffMinutes = settings.cutoffHour * 60 + settings.cutoffMinute
        return nowMinutes < cutoffMinutes
    }

    // Fetches all PendingSwap records whose effectiveDate has arrived and applies each:
    // deactivates the old TrinoTask for that slot, inserts a new one, then deletes the record.
    // Call on app launch so swaps that happened overnight are applied before the user sees tasks.
    static func applyPendingSwaps(context: ModelContext) {
        let today = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<PendingSwap>(
            predicate: #Predicate { $0.effectiveDate <= today }
        )
        guard let swaps = try? context.fetch(descriptor), !swaps.isEmpty else { return }

        // Fetch all tasks once — only 3 active at most, so no perf concern.
        // If this fetch fails, bail rather than proceeding with an empty list, which would
        // deactivate nothing and silently delete the PendingSwap records without applying them.
        guard let allTasks = try? context.fetch(FetchDescriptor<TrinoTask>()) else { return }

        for swap in swaps {
            if let old = allTasks.first(where: { $0.isActive && $0.slotPosition == swap.slotPosition }) {
                old.isActive = false
            }
            let newTask = TrinoTask(name: swap.newTaskName, slotPosition: swap.slotPosition)
            context.insert(newTask)
            context.delete(swap)
        }
    }
}
