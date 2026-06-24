import Foundation
import Observation
import Domain

/// Drives the study-scope choice for both onboarding and settings. Holds the
/// working target level and selected-theme set, derives the selectable themes
/// from the content catalog via the pure `SelectionScope` helpers, enforces the
/// non-empty-scope guard at the persistence boundary, and signals a `daily-plan`
/// recompute whenever a change is persisted.
@MainActor
@Observable
public final class ScopeSelectionModel {
    private let store: UserDataStore
    private let catalog: ContentCatalog

    /// Working target level (nil until the user picks one in onboarding).
    public private(set) var targetLevel: CEFRLevel?
    /// Working set of selected theme ids.
    public private(set) var selectedThemeIDs: Set<String>
    /// Bumped each time a scope change is persisted — observers (the future
    /// `daily-plan` driver) recompute the queue when this changes.
    public private(set) var recomputeToken: Int = 0

    public init(store: UserDataStore, catalog: ContentCatalog) {
        self.store = store
        self.catalog = catalog
        let settings = (try? store.loadSettings()) ?? .default
        self.targetLevel = settings.targetLevel
        self.selectedThemeIDs = Set(settings.selectedThemeIDs)
    }

    // MARK: - Derived scope (via pure Domain helpers)

    /// All selectable levels, in CEFR order.
    public var allLevels: [CEFRLevel] { CEFRLevel.allCases }

    /// Levels included by the current target (target plus all lower).
    public var includedLevels: [CEFRLevel] {
        targetLevel.map(SelectionScope.includedLevels(for:)) ?? []
    }

    /// Themes belonging to the included levels, level-ordered — the only themes
    /// offered for selection.
    public var availableThemes: [Theme] {
        SelectionScope.inScopeThemes(for: includedLevels, in: catalog)
    }

    /// Whether the current working selection yields at least one in-scope card.
    public var isStudyable: Bool {
        SelectionScope.isStudyable(targetLevel: targetLevel, selectedThemeIDs: selectedThemeIDs, in: catalog)
    }

    public func isThemeSelected(_ id: String) -> Bool { selectedThemeIDs.contains(id) }

    // MARK: - Mutations (working state only; nothing persisted until `persist()`)

    /// Choose a target level and re-derive the selectable theme set. Themes that
    /// remain in scope keep their prior selected/deselected state; newly in-scope
    /// themes are selected by default; themes no longer in scope are dropped.
    public func selectLevel(_ level: CEFRLevel) {
        let previousAvailable = Set(availableThemes.map(\.id))
        targetLevel = level
        let nowAvailable = Set(availableThemes.map(\.id))

        let kept = selectedThemeIDs.intersection(nowAvailable)
        let newlyInScope = nowAvailable.subtracting(previousAvailable)
        selectedThemeIDs = kept.union(newlyInScope)
    }

    public func toggleTheme(_ id: String) {
        if selectedThemeIDs.contains(id) {
            selectedThemeIDs.remove(id)
        } else {
            selectedThemeIDs.insert(id)
        }
    }

    /// Reset the theme selection to "all in-scope themes selected" (the default).
    public func selectAllThemes() {
        selectedThemeIDs = Set(availableThemes.map(\.id))
    }

    // MARK: - Persistence boundary

    /// Persist the working scope, guarded by the studyability invariant. Returns
    /// `false` (and persists nothing, triggers no recompute) when the selection
    /// is not studyable. When `completingOnboarding` is true the persisted
    /// settings also record onboarding completion.
    @discardableResult
    public func persist(completingOnboarding: Bool = false) -> Bool {
        guard isStudyable else { return false }
        do {
            var settings = (try? store.loadSettings()) ?? .default
            settings.targetLevel = targetLevel
            settings.selectedThemeIDs = availableThemes.map(\.id).filter(selectedThemeIDs.contains)
            if completingOnboarding {
                settings.didCompleteOnboarding = true
            }
            try store.saveSettings(settings)
            recomputeToken += 1
            return true
        } catch {
            return false
        }
    }
}
