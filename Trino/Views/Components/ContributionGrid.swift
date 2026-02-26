import SwiftUI

struct ContributionGrid: View {
    let completionData: [Date: Int]
    let year: Int
    let theme: AppTheme
    let weekStartsOnMonday: Bool

    @State private var tappedDate: Date? = nil

    private let cellSize: CGFloat = 38
    private let gap: CGFloat = 6
    private let calendar = Calendar.current
    private let weeks: [[Date]]

    private var dayLabels: [String] {
        weekStartsOnMonday
            ? ["M", "T", "W", "T", "F", "S", "S"]
            : ["S", "M", "T", "W", "T", "F", "S"]
    }

    init(completionData: [Date: Int], year: Int, theme: AppTheme, weekStartsOnMonday: Bool) {
        self.completionData = completionData
        self.year = year
        self.theme = theme
        self.weekStartsOnMonday = weekStartsOnMonday
        self.weeks = ContributionGrid.buildWeeks(for: year, weekStartsOnMonday: weekStartsOnMonday)
    }

    // MARK: - Grid data

    private static func buildWeeks(for year: Int, weekStartsOnMonday: Bool) -> [[Date]] {
        let calendar = Calendar.current
        let firstWeekday = weekStartsOnMonday ? 2 : 1

        var comps = DateComponents()
        comps.year = year; comps.month = 1; comps.day = 1
        let jan1 = calendar.date(from: comps)!
        comps.month = 12; comps.day = 31
        let dec31 = calendar.date(from: comps)!

        let jan1Weekday = calendar.component(.weekday, from: jan1)
        let daysBack = (jan1Weekday - firstWeekday + 7) % 7
        let start = calendar.date(byAdding: .day, value: -daysBack, to: jan1)!

        let dec31Weekday = calendar.component(.weekday, from: dec31)
        let daysFwd = (6 - (dec31Weekday - firstWeekday + 7) % 7)
        let end = calendar.date(byAdding: .day, value: daysFwd, to: dec31)!

        var result: [[Date]] = []
        var cur = start
        while cur <= end {
            var week: [Date] = []
            for _ in 0..<7 {
                week.append(cur)
                cur = calendar.date(byAdding: .day, value: 1, to: cur)!
            }
            result.append(week)
        }
        return result
    }

    private func monthLabel(for week: [Date]) -> String {
        guard let first = week.first(where: {
            calendar.component(.day, from: $0) == 1 &&
            calendar.component(.year, from: $0) == year
        }) else { return "" }
        return first.formatted(.dateTime.month(.abbreviated))
    }

    private var todayWeekIndex: Int {
        weeks.firstIndex(where: { week in
            week.contains(where: { calendar.isDateInToday($0) })
        }) ?? weeks.count - 1
    }

    /// Past zero-completion days use systemGray5. Future days are dimmed. Out-of-year cells are clear.
    private func cellColor(for date: Date) -> Color {
        guard calendar.component(.year, from: date) == year else { return .clear }
        let today = calendar.startOfDay(for: Date())
        let normalized = calendar.startOfDay(for: date)
        if normalized > today { return Color(.systemGray6).opacity(0.5) }
        switch completionData[normalized] ?? 0 {
        case 0:  return Color(.systemGray5)
        case 1:  return theme.intensity1
        case 2:  return theme.intensity2
        default: return theme.intensity3
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Tapped cell info bar — auto-dismisses, no X button
            if let date = tappedDate {
                let count = completionData[date] ?? 0
                HStack {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(count)/3 completed")
                        .font(.caption.weight(.medium))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Sticky day-of-week header
            HStack(spacing: gap) {
                ForEach(Array(dayLabels.enumerated()), id: \.offset) { _, label in
                    Text(label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: cellSize, alignment: .center)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal)

            // Vertical scrolling grid
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .center, spacing: gap) {
                        ForEach(Array(weeks.enumerated()), id: \.offset) { index, week in
                            let label = monthLabel(for: week)
                            // Month section header
                            if !label.isEmpty {
                                Text(label)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.top, index == 0 ? 0 : 14)
                                    .padding(.horizontal)
                            }
                            // Week row
                            HStack(spacing: gap) {
                                ForEach(week, id: \.self) { date in
                                    let inYear = calendar.component(.year, from: date) == year
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(cellColor(for: date))
                                        .frame(width: cellSize, height: cellSize)
                                        .overlay {
                                            if calendar.isDateInToday(date) {
                                                RoundedRectangle(cornerRadius: 4)
                                                    .strokeBorder(Color.primary, lineWidth: 1.5)
                                            }
                                        }
                                        .onTapGesture {
                                            guard inYear else { return }
                                            let normalized = calendar.startOfDay(for: date)
                                            withAnimation(.easeInOut(duration: 0.15)) {
                                                if tappedDate == normalized {
                                                    tappedDate = nil
                                                } else {
                                                    tappedDate = normalized
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                                        withAnimation { tappedDate = nil }
                                                    }
                                                }
                                            }
                                        }
                                }
                            }
                            .id(index)
                        }
                    }
                    .padding(.vertical, 12)
                }
                .frame(maxHeight: .infinity)
                .onAppear {
                    let isCurrentYear = year == Calendar.current.component(.year, from: Date())
                    if isCurrentYear {
                        proxy.scrollTo(todayWeekIndex, anchor: .center)
                    } else {
                        proxy.scrollTo(weeks.count - 1, anchor: .bottom)
                    }
                }
            }
        }
    }
}

#Preview {
    ContributionGrid(
        completionData: [:],
        year: 2026,
        theme: .orange,
        weekStartsOnMonday: false
    )
}
