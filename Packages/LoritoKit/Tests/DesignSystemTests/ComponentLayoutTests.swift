import Foundation
import Testing
import Domain
@testable import DesignSystem

@Suite("Recall prompt runs")
struct RecallPromptRunsTests {
    @Test("Bold is the question, emphasis is Spanish, the rest plain")
    func runs() {
        let runs = RecallPromptView.runs("**¿el или la?** *problema, mano*")
        #expect(runs.map(\.voice) == [.question, .plain, .spanish])
        #expect(runs.last?.text == "problema, mano")
    }

    @Test("Plain prompt stays one plain run")
    func plain() {
        let runs = RecallPromptView.runs("Вспомните главное: «Род»")
        #expect(runs.count == 1 && runs[0].voice == .plain)
    }
}

@Suite("Activity heatmap layout")
struct ActivityHeatmapLayoutTests {
    @Test("Rows are Monday…Sunday; columns hold whole weeks, oldest first")
    func layout() {
        let cal = { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c }()
        let today = cal.date(from: DateComponents(year: 2026, month: 10, day: 27))!   // Tuesday
        let days = (0..<84).reversed().map { offset in
            HeatmapDay(day: cal.date(byAdding: .day, value: -offset, to: today)!, count: 0, bucket: 0)
        }
        let columns = ActivityHeatmap.columns(days, calendar: cal)
        #expect(columns.allSatisfy { $0.count == 7 })
        #expect(columns.flatMap { $0 }.compactMap { $0 }.count == 84)
        #expect(ActivityHeatmap.row(of: today, calendar: cal) == 1)                  // Tuesday
        #expect(columns.last?[1]?.day == today)                                      // today in its weekday row
        #expect(columns.last![2] == nil)                                               // future slots empty
    }
}

@Suite("Balanced columns")
struct BalancedColumnsTests {
    @Test("Blocks go, in order, to the currently shorter column")
    func greedy() {
        let result = BalancedColumnsLayout.assign(heights: [100, 40, 40, 30, 200], spacing: 10)
        #expect(result.columns == [0, 1, 1, 1, 0])
        #expect(result.columnHeights == [310, 130])
    }

    @Test("Each block is placed whole, never split")
    func whole() {
        let result = BalancedColumnsLayout.assign(heights: [500], spacing: 10)
        #expect(result.columns == [0])
        #expect(result.columnHeights == [500, 0])
    }

    @Test("Single column when the body fits the available height")
    func fits() {
        #expect(BalancedColumnsLayout.usesSingleColumn(totalHeight: 380, availableHeight: 400, count: 4))
        #expect(!BalancedColumnsLayout.usesSingleColumn(totalHeight: 900, availableHeight: 400, count: 4))
        #expect(BalancedColumnsLayout.usesSingleColumn(totalHeight: 900, availableHeight: 400, count: 1))
    }
}
