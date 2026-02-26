import SwiftUI
import SwiftData

struct RootView: View {
    @Query(filter: #Predicate<TrinoTask> { $0.isActive }) var tasks: [TrinoTask]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            if tasks.isEmpty {
                OnboardingView()
                    .transition(.opacity)
            } else {
                ContentView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: tasks.isEmpty)
        .onAppear {
            TaskSwapService.applyPendingSwaps(context: modelContext)
        }
    }
}
