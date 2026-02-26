import SwiftUI
import SwiftData

struct TaskManagementView: View {
    @Query(filter: #Predicate<TrinoTask> { task in task.isActive },
           sort: \TrinoTask.slotPosition) var tasks: [TrinoTask]
    @Environment(\.dismiss) var dismiss
    @Environment(SettingsStore.self) private var settings

    @State private var taskToSwap: TrinoTask?

    private var cutoffTimeLabel: String {
        guard let date = Calendar.current.date(
            bySettingHour: settings.cutoffHour,
            minute: settings.cutoffMinute,
            second: 0,
            of: Date()
        ) else { return "9:00 PM" }
        return date.formatted(date: .omitted, time: .shortened)
    }

    private var isSwapLocked: Bool {
        !TaskSwapService.canSwapForTomorrow(settings: settings)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(tasks) { task in
                        TaskManagementRow(task: task) {
                            taskToSwap = task
                        }
                    }
                } footer: {
                    Label(
                        isSwapLocked
                            ? "Scheduling locked — past cut-off (\(cutoffTimeLabel))"
                            : "Scheduling cut-off: \(cutoffTimeLabel)",
                        systemImage: isSwapLocked ? "lock.fill" : "lock.open"
                    )
                    .font(.caption)
                    .foregroundStyle(isSwapLocked ? settings.theme.accent : .secondary)
                }
            }
            .navigationTitle("Manage Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $taskToSwap) { task in
                SwapTaskView(task: task)
            }
        }
    }
}

// MARK: - Row

struct TaskManagementRow: View {
    let task: TrinoTask
    let onSwapTap: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(SettingsStore.self) private var settings
    @State private var draftName: String

    init(task: TrinoTask, onSwapTap: @escaping () -> Void) {
        self.task = task
        self.onSwapTap = onSwapTap
        _draftName = State(initialValue: task.name)
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Slot \(task.slotPosition)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Task name", text: $draftName)
                    .font(.body)
                    .onSubmit { commitEdit() }
            }

            Spacer()

            Button(action: onSwapTap) {
                Image(systemName: "arrow.trianglehead.2.clockwise")
                    .foregroundStyle(settings.theme.accent)
                    .imageScale(.medium)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    private func commitEdit() {
        let trimmed = draftName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, trimmed != task.name else {
            draftName = task.name
            return
        }
        task.name = trimmed
        patchTodayEntryName(for: task, newName: trimmed)
    }

    private func patchTodayEntryName(for task: TrinoTask, newName: String) {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let descriptor = FetchDescriptor<DailyLog>(
            predicate: #Predicate { $0.date >= today && $0.date < tomorrow }
        )
        guard let log = (try? modelContext.fetch(descriptor))?.first,
              let entry = log.entries.first(where: { $0.taskId == task.id }) else { return }
        entry.taskName = newName
    }
}

// MARK: - Swap Sheet

struct SwapTaskView: View {
    let task: TrinoTask

    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    @Environment(SettingsStore.self) private var settings

    @State private var newTaskName = ""
    @State private var showStreakResetAlert = false

    private var trimmedName: String { newTaskName.trimmingCharacters(in: .whitespaces) }
    private var isNameValid: Bool { !trimmedName.isEmpty }
    private var canSchedule: Bool { TaskSwapService.canSwapForTomorrow(settings: settings) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("New task name", text: $newTaskName)
                } header: {
                    Text("Replacing \"\(task.name)\"")
                }

                Section {
                    Button("Swap Now") {
                        showStreakResetAlert = true
                    }
                    .disabled(!isNameValid)
                    .foregroundStyle(.red)

                    if canSchedule {
                        Button("Schedule for Tomorrow") {
                            scheduleForTomorrow()
                        }
                        .disabled(!isNameValid)
                        .foregroundStyle(settings.theme.accent)
                    }
                } footer: {
                    Text(canSchedule
                        ? "Swapping now resets this task's streak. Scheduling for tomorrow keeps the streak intact until midnight."
                        : "Scheduling is locked for tonight. You can still swap now, but it will reset the streak.")
                }
            }
            .navigationTitle("Replace Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Reset Task Streak?", isPresented: $showStreakResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Swap Now", role: .destructive) { swapNow() }
            } message: {
                Text("This will immediately replace \"\(task.name)\" with \"\(trimmedName)\" and reset its streak.")
            }
        }
    }

    private func swapNow() {
        guard isNameValid else { return }
        task.isActive = false
        let newTask = TrinoTask(name: trimmedName, slotPosition: task.slotPosition)
        modelContext.insert(newTask)
        patchTodayLog(oldTaskId: task.id, newTask: newTask)
        dismiss()
    }

    private func scheduleForTomorrow() {
        guard isNameValid else { return }

        // Remove any existing pending swap for this slot — last intent wins
        let slot = task.slotPosition
        let existingDescriptor = FetchDescriptor<PendingSwap>(
            predicate: #Predicate { $0.slotPosition == slot }
        )
        (try? modelContext.fetch(existingDescriptor))?.forEach { modelContext.delete($0) }

        let tomorrow = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        )
        let pending = PendingSwap(slotPosition: task.slotPosition, newTaskName: trimmedName, effectiveDate: tomorrow)
        modelContext.insert(pending)
        dismiss()
    }

    private func patchTodayLog(oldTaskId: UUID, newTask: TrinoTask) {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let descriptor = FetchDescriptor<DailyLog>(
            predicate: #Predicate { $0.date >= today && $0.date < tomorrow }
        )
        guard let log = (try? modelContext.fetch(descriptor))?.first else { return }

        if let staleEntry = log.entries.first(where: { $0.taskId == oldTaskId }) {
            log.entries.removeAll { $0.taskId == oldTaskId }
            modelContext.delete(staleEntry)
        }

        let newEntry = TaskEntry(taskName: newTask.name, taskId: newTask.id, slotPosition: newTask.slotPosition)
        modelContext.insert(newEntry)
        log.entries.append(newEntry)
    }
}

#Preview {
    TaskManagementView()
        .modelContainer(for: [TrinoTask.self, DailyLog.self, TaskEntry.self, PendingSwap.self], inMemory: true)
        .environment(SettingsStore())
}
