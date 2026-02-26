import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) var modelContext
    @State private var slot1 = ""
    @State private var slot2 = ""
    @State private var slot3 = ""

    private var canSubmit: Bool {
        let names = [slot1, slot2, slot3].map { $0.trimmingCharacters(in: .whitespaces) }
        let allFilled = names.allSatisfy { !$0.isEmpty }
        let allUnique = Set(names).count == names.count
        return allFilled && allUnique
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 8) {
                Text("Trino")
                    .font(.largeTitle.bold())
                Text("Track your 3 daily essentials")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 16) {
                taskField(slot: 1, text: $slot1)
                taskField(slot: 2, text: $slot2)
                taskField(slot: 3, text: $slot3)
            }
            .padding(.horizontal)

            Button {
                saveTasks()
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canSubmit ? Color.trinoOrange : Color.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!canSubmit)
            .padding(.horizontal)

            Spacer()
        }
    }

    private func taskField(slot: Int, text: Binding<String>) -> some View {
        HStack(spacing: 12) {
            Text("\(slot)")
                .font(.headline)
                .foregroundStyle(Color.trinoOrange)
                .frame(width: 24)

            TextField("Task \(slot)", text: text)
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func saveTasks() {
        let names = [
            slot1.trimmingCharacters(in: .whitespaces),
            slot2.trimmingCharacters(in: .whitespaces),
            slot3.trimmingCharacters(in: .whitespaces)
        ]
        for (index, name) in names.enumerated() {
            modelContext.insert(TrinoTask(name: name, slotPosition: index + 1))
        }
        NotificationService.requestPermission()
    }
}

#Preview {
    OnboardingView()
        .modelContainer(for: [TrinoTask.self], inMemory: true)
}
