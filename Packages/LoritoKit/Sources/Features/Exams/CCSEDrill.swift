import SwiftUI
import Observation
import Domain
import DesignSystem

/// CCSE questions as spaced-repetition items: choose → feedback → next.
/// Grading goes through `GradingService` under `ccse:<item-id>`.
@MainActor
@Observable
public final class CCSEDrillModel: Identifiable {
    public let id = UUID()
    private let grading: GradingService
    private let now: () -> Date
    public let items: [ExamItem]
    public private(set) var index = 0
    public private(set) var chosen: String?

    init(store: UserDataStore, items: [ExamItem], now: @escaping () -> Date = { Date() }) {
        self.grading = GradingService(store: store)
        self.items = items
        self.now = now
    }

    /// Today's CCSE plan as a drill (nil when nothing is planned).
    static func today(store: UserDataStore, catalog: ContentCatalog, today: Date = Date()) -> CCSEDrillModel? {
        guard let bank = catalog.exams?.items else { return nil }
        let events = (try? store.allEvents()) ?? []
        let plan = CCSEPlanner.plan(bank: bank, reviews: (try? store.allReviews()) ?? [],
                                    settings: (try? store.loadSettings()) ?? .default,
                                    introducedToday: IntroductionLedger(events: events, day: today).countsByKind, today: today)
        let gradedToday = Set(events.filter { $0.grade != nil && Calendar.learningDay.isDate($0.date, inSameDayAs: today) }.map(\.cardID))
        let ids = plan.filter { !gradedToday.contains($0) }
        let items = ids.compactMap { id in bank.first { CCSEPlanner.itemID($0.id) == id } }
        return items.isEmpty ? nil : CCSEDrillModel(store: store, items: items)
    }

    public var current: ExamItem? { index < items.count ? items[index] : nil }

    public func choose(_ option: String) {
        guard chosen == nil, let item = current else { return }
        chosen = option
        _ = try? grading.grade(cardID: CCSEPlanner.itemID(item.id), grade: option == item.correctAnswer ? .good : .again,
                               today: now())
    }

    public func next() {
        chosen = nil
        index += 1
    }
}

struct CCSEDrillView: View {
    @Bindable var model: CCSEDrillModel
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: LoritoSpacing.md) {
            if let item = model.current, case .choice(let options, let answer) = item.kind {
                SessionTopBar(segments: SessionProgressBar.segments(current: model.index, total: model.items.count),
                              position: "\(model.index + 1)/\(model.items.count)", onClose: onClose)
                    .padding(.horizontal, LoritoSpacing.screenGutter)
                    .padding(.top, LoritoSpacing.sm)
                ScrollView {
                    VStack(alignment: .leading, spacing: LoritoSpacing.md) {
                        AnswerText(item.text, color: LoritoColor.onInk, interaction: .standalone)
                        ForEach(options, id: \.self) { option in
                            Button { model.choose(option) } label: {
                                HStack { AnswerText(option, color: LoritoColor.onInk); Spacer() }
                                    .padding(.horizontal, LoritoSpacing.md)
                                    .frame(minHeight: LoritoLayout.primaryButtonHeight)
                                    .background(background(option, answer: answer),
                                                in: RoundedRectangle(cornerRadius: LoritoRadius.md, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .disabled(model.chosen != nil)
                        }
                        if model.chosen != nil, !item.explanation.isEmpty {
                            CardContentView(item.explanation, tone: .ink)
                        }
                        if let edition = item.edition {
                            Text("Instituto Cervantes, Manual CCSE, edición \(edition)")
                                .font(LoritoFont.caption).foregroundStyle(LoritoColor.onInkSecondary)
                        }
                    }
                    .padding(.horizontal, LoritoSpacing.screenGutter)
                }
                if model.chosen != nil {
                    PrimaryButton("Дальше", variant: .highlight) { model.next() }
                        .padding(.horizontal, LoritoSpacing.screenGutter)
                        .padding(.bottom, LoritoSpacing.md)
                }
            } else {
                SessionCompleteView(subtitle: "Вопросы CCSE на сегодня пройдены.", onClose: onClose)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LoritoColor.ink.ignoresSafeArea())
    }

    private func background(_ option: String, answer: String) -> Color {
        guard let chosen = model.chosen else { return LoritoColor.inkRaised }
        if option == answer { return LoritoColor.highlight.opacity(0.35) }
        return option == chosen ? LoritoColor.dangerSoft : LoritoColor.inkRaised
    }
}
