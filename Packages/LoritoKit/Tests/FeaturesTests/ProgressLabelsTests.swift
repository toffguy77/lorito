import Testing
@testable import Features

/// stats-and-streak: the all-time tile counts cards, the heatmap total counts every graded
/// answer — the two must not share a label (498 cards + 1 conjugation read as 498 vs 499).
@Suite struct ProgressLabelsTests {
    @Test func allTimeTileNamesCards() {
        #expect(StatsView.allTimeLabel == "карточек повторено")
    }

    @Test func heatmapTotalNamesAnswers() {
        #expect(StatsView.windowTotalText(499) == "499 ответов")
        #expect(StatsView.windowTotalText(1) == "1 ответ")
        #expect(StatsView.windowTotalText(22) == "22 ответа")
    }

    @Test func labelsDiffer() {
        #expect(!StatsView.windowTotalText(498).contains(StatsView.allTimeLabel))
        #expect(!StatsView.windowTotalText(498).contains("повтор"))
    }
}
