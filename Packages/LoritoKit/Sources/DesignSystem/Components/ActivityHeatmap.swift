import SwiftUI

/// One heatmap cell: a day, its count and intensity bucket (0–3).
public struct HeatmapDay: Sendable, Equatable {
    public let day: Date
    public let count: Int
    public let bucket: Int

    public init(day: Date, count: Int, bucket: Int) {
        self.day = day
        self.count = count
        self.bucket = bucket
    }
}

/// A weeks × weekdays activity grid: columns are weeks (oldest left), rows are
/// Monday…Sunday, colored by the `heat0–heat3` tokens.
public struct ActivityHeatmap: View {
    private let days: [HeatmapDay]
    private let calendar: Calendar

    public init(days: [HeatmapDay], calendar: Calendar) {
        self.days = days
        self.calendar = calendar
    }

    /// Row (0 = Monday … 6 = Sunday) of a day.
    nonisolated static func row(of day: Date, calendar: Calendar) -> Int {
        (calendar.component(.weekday, from: day) + 5) % 7
    }

    /// Days laid out into week columns of seven optional slots (nil = outside
    /// the window), oldest week first.
    nonisolated static func columns(_ days: [HeatmapDay], calendar: Calendar) -> [[HeatmapDay?]] {
        guard let first = days.first else { return [] }
        let lead = row(of: first.day, calendar: calendar)
        let slots: [HeatmapDay?] = Array(repeating: nil, count: lead) + days.map { Optional($0) }
        return stride(from: 0, to: slots.count, by: 7).map { start in
            let week = Array(slots[start..<min(start + 7, slots.count)])
            return week + Array(repeating: nil, count: 7 - week.count)
        }
    }

    public static func color(bucket: Int) -> Color {
        switch bucket {
        case 3: return LoritoColor.heat3
        case 2: return LoritoColor.heat2
        case 1: return LoritoColor.heat1
        default: return LoritoColor.heat0
        }
    }

    /// Day labels in the grid's calendar time zone (days are its midnights).
    private var dayFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.timeZone = calendar.timeZone
        f.setLocalizedDateFormatFromTemplate("d MMMM")
        return f
    }

    public var body: some View {
        let columns = Self.columns(days, calendar: calendar)
        let formatter = dayFormatter
        Grid(horizontalSpacing: 4, verticalSpacing: 4) {
            ForEach(0..<7, id: \.self) { row in
                GridRow {
                    ForEach(columns.indices, id: \.self) { col in
                        cell(columns[col][row], formatter: formatter)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func cell(_ day: HeatmapDay?, formatter: DateFormatter) -> some View {
        if let day {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Self.color(bucket: day.bucket))
                .frame(maxWidth: .infinity, minHeight: 14, maxHeight: 18)
                .accessibilityElement()
                .accessibilityLabel(formatter.string(from: day.day))
                .accessibilityValue("\(day.count)")
                .accessibilityIdentifier(day == days.last ? "heatmap.today" : "heatmap.day")
        } else {
            Color.clear
                .frame(maxWidth: .infinity, minHeight: 14, maxHeight: 18)
                .accessibilityHidden(true)
        }
    }
}

/// The "меньше … больше" legend under the heatmap.
public struct ActivityHeatmapLegend: View {
    public init() {}

    public var body: some View {
        HStack(spacing: 6) {
            Text("меньше")
            ForEach(0..<4, id: \.self) { bucket in
                RoundedRectangle(cornerRadius: 3).fill(ActivityHeatmap.color(bucket: bucket)).frame(width: 12, height: 12)
            }
            Text("больше")
        }
        .font(LoritoFont.caption)
        .foregroundStyle(LoritoColor.textSecondary)
        .accessibilityHidden(true)
    }
}
