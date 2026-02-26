import SwiftUI
import SwiftData

struct TaskRowView: View {
    @Environment(SettingsStore.self) private var settings
    @Bindable var entry: TaskEntry

    var body: some View {
        Button {
            entry.isCompleted.toggle()
        } label: {
            HStack(spacing: 16) {
                Image(systemName: entry.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(entry.isCompleted ? settings.theme.accent : .secondary)
                    .animation(.easeInOut(duration: 0.15), value: entry.isCompleted)

                Text(entry.taskName)
                    .font(.body)
                    .foregroundStyle(.primary)

                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 20)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.success, trigger: entry.isCompleted)
    }
}
