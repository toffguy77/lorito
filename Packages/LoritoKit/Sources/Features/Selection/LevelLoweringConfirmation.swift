import SwiftUI
import Domain

/// A level lowering that would reset progress, waiting for the user's confirmation.
struct PendingLowering: Equatable {
    let level: CEFRLevel
    let cards: Int
}

extension View {
    /// Asks before a lowering resets the progress of the cards above the new level;
    /// cancelling keeps the level and all progress.
    func levelLoweringConfirmation(_ pending: Binding<PendingLowering?>,
                                   onConfirm: @escaping (CEFRLevel) -> Void) -> some View {
        confirmationDialog(
            "Понизить уровень до \(pending.wrappedValue?.level.rawValue ?? "")?",
            isPresented: Binding(get: { pending.wrappedValue != nil }, set: { if !$0 { pending.wrappedValue = nil } }),
            titleVisibility: .visible,
            presenting: pending.wrappedValue
        ) { lowering in
            Button("Понизить и сбросить", role: .destructive) { onConfirm(lowering.level) }
                .accessibilityIdentifier("level.lower.confirm")
            Button("Отмена", role: .cancel) {}
        } message: { lowering in
            let cards = RussianPlural.form(lowering.cards, one: "карточки", few: "карточек", many: "карточек")
            Text("Прогресс \(lowering.cards) \(cards) выше \(lowering.level.rawValue) будет сброшен: они уйдут из повторений и снова станут новыми, если поднять уровень.")
        }
    }
}

extension ScopeSelectionModel {
    /// A lowering of the stored level to `level` that needs confirmation, or nil.
    func loweringNeedingConfirmation(to level: CEFRLevel) -> PendingLowering? {
        guard let stored = storedTargetLevel, level < stored else { return nil }
        let cards = cardsWithProgress(above: level).count
        return cards > 0 ? PendingLowering(level: level, cards: cards) : nil
    }
}
