import Foundation

// Pure, deterministic study-scope logic: given a target level and a set of
// selected theme ids, derive which levels, themes, and cards are in scope and
// whether the selection is studyable. No UI or persistence dependencies — this
// is the single source of selection truth shared by onboarding, settings, and
// the daily-plan planner.
public enum SelectionScope {

    /// The target level plus every lower level, per `content-model`'s ordered
    /// levels (`A1 < A2 < B1 < B2 < C1 < C2`).
    public static func includedLevels(for targetLevel: CEFRLevel) -> [CEFRLevel] {
        targetLevel.included
    }

    /// Themes belonging to the included levels, ordered by level then theme order.
    public static func inScopeThemes(
        for includedLevels: [CEFRLevel],
        in catalog: ContentCatalog
    ) -> [Theme] {
        let included = Set(includedLevels)
        return catalog.themes
            .filter { included.contains($0.level) }
            .sorted { lhs, rhs in
                if lhs.level != rhs.level { return lhs.level < rhs.level }
                return lhs.order < rhs.order
            }
    }

    /// Cards whose level is included by the target and whose theme is selected.
    public static func inScopeCards(
        targetLevel: CEFRLevel?,
        selectedThemeIDs: Set<String>,
        in catalog: ContentCatalog
    ) -> [Card] {
        guard let targetLevel else { return [] }
        let included = Set(includedLevels(for: targetLevel))
        return catalog.cards
            .filter { included.contains($0.level) && selectedThemeIDs.contains($0.themeID) }
            .sorted { lhs, rhs in
                if lhs.level != rhs.level { return lhs.level < rhs.level }
                if lhs.order != rhs.order { return lhs.order < rhs.order }
                return lhs.id < rhs.id
            }
    }

    /// A selection is studyable only when its in-scope card set is non-empty.
    public static func isStudyable(
        targetLevel: CEFRLevel?,
        selectedThemeIDs: Set<String>,
        in catalog: ContentCatalog
    ) -> Bool {
        !inScopeCards(targetLevel: targetLevel, selectedThemeIDs: selectedThemeIDs, in: catalog).isEmpty
    }
}
