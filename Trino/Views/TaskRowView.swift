import SwiftUI
import SwiftData

struct TaskRowView: View {
    @Environment(SettingsStore.self) private var settings
    @Bindable var entry: TaskEntry

    var body: some View {
        HStack(spacing: 16) {
            Button {
                entry.isCompleted.toggle()
            } label: {
                Image(systemName: entry.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(entry.isCompleted ? settings.theme.accent : .secondary)
                    .animation(.easeInOut(duration: 0.15), value: entry.isCompleted)
            }
            .buttonStyle(.plain)

            Text(entry.taskName)
                .font(.body)
                .foregroundStyle(entry.isCompleted ? .secondary : .primary)
                .strikethrough(entry.isCompleted, color: .secondary)

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
