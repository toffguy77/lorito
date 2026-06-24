import SwiftUI
import Domain
import DesignSystem

/// The Today screen: summary of the day's queue, a start action, and distinct
/// empty / all-done states. Presents the study session modally.
public struct TodayView: View {
    @State private var model: TodayModel
    @State private var session: StudySessionModel?
    private let catalog: ContentCatalog
    private let store: UserDataStore

    public init(store: UserDataStore, catalog: ContentCatalog) {
        self.store = store
        self.catalog = catalog
        _model = State(initialValue: TodayModel(store: store, catalog: catalog))
    }

    public var body: some View {
        VStack(spacing: LoritoSpacing.lg) {
            Text("Сегодня")
                .font(LoritoFont.title)
                .foregroundStyle(LoritoColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if model.hasWork {
                activeState
            } else if model.isAllDone {
                message(icon: "✅", title: "Всё на сегодня!", subtitle: "Вы прошли все карточки дня.")
            } else {
                message(icon: "🌤", title: "Пока нечего изучать", subtitle: "Загляните позже — карточки появятся, когда придёт срок.")
            }

            Spacer()
        }
        .padding(LoritoSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LoritoColor.surface.ignoresSafeArea())
        .onAppear { model.refresh() }
        .sheet(item: $session, onDismiss: { model.refresh() }) { session in
            StudySessionView(model: session) { self.session = nil }
        }
    }

    private var activeState: some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.md) {
            DayProgressBar(completed: model.studiedCount, total: max(model.totalCount, 1))
            Text(model.summary)
                .font(LoritoFont.heading)
                .foregroundStyle(LoritoColor.textSecondary)

            Button {
                session = StudySessionModel(store: store, catalog: catalog, queue: model.sessionQueue())
            } label: {
                Text("Начать")
                    .font(LoritoFont.body.weight(.semibold))
                    .foregroundStyle(LoritoColor.onAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, LoritoSpacing.sm)
                    .background(LoritoColor.accent, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(!model.hasWork)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func message(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: LoritoSpacing.xs) {
            Text(icon).font(.system(size: 44))
            Text(title)
                .font(LoritoFont.heading)
                .foregroundStyle(LoritoColor.textPrimary)
            Text(subtitle)
                .font(LoritoFont.body)
                .foregroundStyle(LoritoColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, LoritoSpacing.xl)
    }
}

// Allow presenting the session via `.sheet(item:)`.
extension StudySessionModel: @MainActor Identifiable {
    public var id: ObjectIdentifier { ObjectIdentifier(self) }
}
