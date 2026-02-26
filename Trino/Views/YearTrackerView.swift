import SwiftUI
import SwiftData

struct YearTrackerView: View {
    @Environment(SettingsStore.self) private var settings
    @Query(sort: \DailyLog.date) var logs: [DailyLog]
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())

    private let currentYear = Calendar.current.component(.year, from: Date())

    private var availableYears: [Int] {
        let logYears = Set(logs.map { Calendar.current.component(.year, from: $0.date) })
        return logYears.union([currentYear]).sorted(by: >)
    }

    private var completionData: [Date: Int] {
        Dictionary(
            logs
                .filter { Calendar.current.component(.year, from: $0.date) == selectedYear }
                .map { ($0.date, $0.completionCount) },
            uniquingKeysWith: { a, _ in a }
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if availableYears.count > 1 {
                    Picker("Year", selection: $selectedYear) {
                        ForEach(availableYears, id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                }

                // .id forces a fresh ContributionGrid (and scroll reset) on year or week-start change
                ContributionGrid(
                    completionData: completionData,
                    year: selectedYear,
                    theme: settings.theme,
                    weekStartsOnMonday: settings.weekStartsOnMonday
                )
                .id(settings.weekStartsOnMonday)
                .frame(maxHeight: .infinity)
            }
            .padding(.top, 8)
            .navigationTitle("Year")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    YearTrackerView()
        .modelContainer(for: [DailyLog.self, TaskEntry.self], inMemory: true)
        .environment(SettingsStore())
}
