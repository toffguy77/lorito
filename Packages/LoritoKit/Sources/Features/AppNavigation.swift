import Foundation
import Observation
import Domain

/// App-wide navigation state, owned above the size-class switch so rotating,
/// resizing (Split View, Stage Manager) or relayouting never resets the
/// selected destination, the catalog selection, or an open study session.
@MainActor
@Observable
public final class AppNavigation {
    public enum Destination: Int, CaseIterable, Hashable, Sendable {
        case today, catalog, progress, settings

        public var title: String {
            switch self {
            case .today: return "Сегодня"
            case .catalog: return "Каталог"
            case .progress: return "Прогресс"
            case .settings: return "Настройки"
            }
        }

        public var systemImage: String {
            switch self {
            case .today: return "sun.max"
            case .catalog: return "point.topleft.down.to.point.bottomright.curvepath"
            case .progress: return "flame"
            case .settings: return "slider.horizontal.3"
            }
        }
    }

    public var destination: Destination = .today

    // Catalog selection (level → theme → card).
    public private(set) var catalogLevel: CEFRLevel?
    public private(set) var catalogThemeID: String?
    public private(set) var catalogCardID: String?

    /// The open study session, presented above every layout.
    public private(set) var session: StudySessionModel?
    /// Bumped when a session closes, so screens can refresh.
    public private(set) var sessionEndCount = 0

    public init() {}

    // MARK: Destinations

    /// Reminder deep link.
    public func openToday() { destination = .today }

    // MARK: Session

    public func startSession(_ session: StudySessionModel) { self.session = session }

    public func endSession() {
        guard session != nil else { return }
        session = nil
        sessionEndCount += 1
    }

    // MARK: Catalog selection

    public func selectLevel(_ level: CEFRLevel) {
        guard level != catalogLevel else { return }
        catalogLevel = level
        catalogThemeID = nil
        catalogCardID = nil
    }

    /// Select a theme (and its level); keeps the card only when it belongs to
    /// the same theme.
    public func selectTheme(_ theme: Theme?) {
        if theme?.id != catalogThemeID { catalogCardID = nil }
        if let theme { catalogLevel = theme.level }
        catalogThemeID = theme?.id
    }

    public func selectCard(_ card: Card) {
        catalogLevel = card.level
        catalogThemeID = card.themeID
        catalogCardID = card.id
    }

    public func clearCard() { catalogCardID = nil }

    /// "level|theme|card" for `@SceneStorage`.
    public var catalogSelectionStorage: String {
        [catalogLevel?.rawValue ?? "", catalogThemeID ?? "", catalogCardID ?? ""].joined(separator: "|")
    }

    /// Restore a stored selection, dropping ids the catalog doesn't know.
    public func restoreCatalogSelection(_ stored: String, in catalog: ContentCatalog) {
        let parts = stored.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
        guard parts.count == 3 else { return }
        catalogLevel = CEFRLevel(rawValue: parts[0])
        let theme = catalog.theme(id: parts[1]).flatMap { $0.level == catalogLevel ? $0 : nil }
        catalogThemeID = theme?.id
        let card = catalog.card(id: parts[2]).flatMap { $0.themeID == theme?.id ? $0 : nil }
        catalogCardID = card?.id
    }
}
